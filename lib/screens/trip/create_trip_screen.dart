import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/trip_providers.dart';

/// Screen for creating or editing a trip.
class CreateTripScreen extends ConsumerStatefulWidget {
  final String? tripId; // null = create, non-null = edit

  const CreateTripScreen({super.key, this.tripId});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _participantController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _participantNames = [];
  bool _isLoading = false;

  bool get _isEditing => widget.tripId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      // Pre-fill form for editing
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final trip = ref.read(tripByIdProvider(widget.tripId!));
        if (trip != null) {
          _nameController.text = trip.name;
          _destinationController.text = trip.destination;
          _descriptionController.text = trip.description;
          _startDate = trip.startDate;
          _endDate = trip.endDate;
          _participantNames = trip.participants.map((p) => p.name).toList();
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
    _participantController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _addParticipant() {
    final name = _participantController.text.trim();
    if (name.isEmpty) return;

    // Prevent duplicates
    if (_participantNames.any((n) => n.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$name" is already added'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _participantNames.add(name);
      _participantController.clear();
    });
  }

  void _removeParticipant(int index) {
    setState(() {
      _participantNames.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select trip dates'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        final trip = ref.read(tripByIdProvider(widget.tripId!));
        if (trip != null) {
          // Keep existing participants, update only names/metadata
          final updated = trip.copyWith(
            name: _nameController.text.trim(),
            destination: _destinationController.text.trim(),
            description: _descriptionController.text.trim(),
            startDate: _startDate,
            endDate: _endDate,
          );
          await ref.read(tripListProvider.notifier).updateTrip(updated);
        }
      } else {
        await ref.read(tripListProvider.notifier).createTrip(
              name: _nameController.text.trim(),
              destination: _destinationController.text.trim(),
              description: _descriptionController.text.trim(),
              startDate: _startDate!,
              endDate: _endDate!,
              participantNames: _participantNames,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Trip updated!' : 'Trip created!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Trip' : 'Create Trip'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Trip Name
            Text('Trip Details', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Trip Name',
                hintText: 'e.g., Goa Weekend Trip',
                prefixIcon: Icon(Icons.flight_takeoff),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter trip name';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Destination
            TextFormField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination',
                hintText: 'e.g., Goa, India',
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter destination';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What\'s this trip about?',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // Date Range
            Text('Trip Dates', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDateRange,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _startDate != null
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    width: _startDate != null ? 2 : 0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    if (_startDate != null && _endDate != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_formatDate(_startDate!)} → ${_formatDate(_endDate!)}',
                              style: theme.textTheme.bodyLarge,
                            ),
                            Text(
                              '${_endDate!.difference(_startDate!).inDays + 1} days',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        'Select date range',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Participants
            Text('Participants', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _participantController,
                    decoration: const InputDecoration(
                      hintText: 'Add participant name',
                      prefixIcon: Icon(Icons.person_add),
                    ),
                    onFieldSubmitted: (_) => _addParticipant(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: _addParticipant,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_participantNames.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_participantNames.length, (index) {
                  return Chip(
                    label: Text(_participantNames[index]),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeParticipant(index),
                    avatar: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        _participantNames[index][0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  );
                }),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No participants added yet',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_isEditing ? Icons.save : Icons.check),
                label: Text(_isEditing ? 'Save Changes' : 'Create Trip'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
