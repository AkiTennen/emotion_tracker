import 'package:flutter/material.dart';
import '../../models/emotion_data.dart';
import '../../models/emotion_entry.dart';
import '../../services/database_service.dart';

class AddEmotionScreen extends StatefulWidget {
  final DateTime selectedDate;

  const AddEmotionScreen({super.key, required this.selectedDate});

  @override
  State<AddEmotionScreen> createState() => _AddEmotionScreenState();
}

class _AddEmotionScreenState extends State<AddEmotionScreen> {
  String? _selectedTier1;
  String? _selectedTier2;
  String? _selectedTier3;
  double _intensity = 1.0;

  void _saveEntry() async {
    if (_selectedTier1 == null) return;

    final entry = EmotionEntry.create(
      tier1Emotion: _selectedTier1!,
      tier2Emotion: _selectedTier2,
      tier3Emotion: _selectedTier3,
      intensity: _intensity.toInt(),
    );

    final now = DateTime.now();
    entry.timestamp = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      now.hour,
      now.minute,
    );

    await DatabaseService.saveEntry(entry);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final color = _selectedTier1 != null ? EmotionData.getColor(_selectedTier1!) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('How are you feeling?'),
        actions: [
          IconButton(
            onPressed: _selectedTier1 != null ? _saveEntry : null,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Step 1: Primary Emotion', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: EmotionData.tier1.map((e) {
                final isSelected = _selectedTier1 == e;
                final eColor = EmotionData.getColor(e);
                return ChoiceChip(
                  label: Text(e),
                  selected: isSelected,
                  selectedColor: eColor.withOpacity(0.4),
                  onSelected: (selected) {
                    setState(() {
                      _selectedTier1 = selected ? e : null;
                      _selectedTier2 = null;
                      _selectedTier3 = null;
                    });
                  },
                );
              }).toList(),
            ),
            if (_selectedTier1 != null) ...[
              const Divider(height: 32),
              Text('Step 2: Secondary Emotion', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: EmotionData.getTier2(_selectedTier1!).map((e) {
                  return ChoiceChip(
                    label: Text(e),
                    selected: _selectedTier2 == e,
                    selectedColor: color?.withOpacity(0.4),
                    onSelected: (selected) {
                      setState(() {
                        _selectedTier2 = selected ? e : null;
                        // We don't clear T3 anymore to allow flexible selection
                      });
                    },
                  );
                }).toList(),
              ),
              const Divider(height: 32),
              Text('Step 3: Tertiary Emotion', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: EmotionData.getAllTier3ForCategory(_selectedTier1!).map((e) {
                  return ChoiceChip(
                    label: Text(e),
                    selected: _selectedTier3 == e,
                    selectedColor: color?.withOpacity(0.4),
                    onSelected: (selected) {
                      setState(() {
                        _selectedTier3 = selected ? e : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const Divider(height: 32),
              Text('Intensity: ${_intensity.toInt()}', style: Theme.of(context).textTheme.titleMedium),
              Slider(
                value: _intensity,
                min: 0,
                max: 3,
                divisions: 3,
                label: _intensity.toInt().toString(),
                activeColor: color,
                onChanged: (value) => setState(() => _intensity = value),
              ),
            ],
            const SizedBox(height: 32),
            if (_selectedTier1 != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _saveEntry,
                  child: const Text('Save Entry'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
