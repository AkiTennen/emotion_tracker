import 'package:flutter/material.dart';
import '../../models/emotion_data.dart';
import '../../models/emotion_entry.dart';
import '../../services/database_service.dart';
import '../../services/settings_service.dart';

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

  bool _isTier2Unlocked = false;
  bool _isTier3Unlocked = false;
  bool _isIntensityUnlocked = false;

  @override
  void initState() {
    super.initState();
    _checkUnlocks();
  }

  void _checkUnlocks() {
    if (SettingsService.shouldSkipUnlocking()) {
      setState(() {
        _isTier2Unlocked = true;
        _isTier3Unlocked = true;
        _isIntensityUnlocked = true;
      });
      return;
    }

    setState(() {
      _isTier2Unlocked = DatabaseService.getTier1Count() >= 7;
      _isTier3Unlocked = DatabaseService.getTier2Count() >= 7;
      _isIntensityUnlocked = DatabaseService.getTier3Count() >= 7;
    });
  }

  void _saveEntry() async {
    if (_selectedTier1 == null) return;

    final entry = EmotionEntry.create(
      tier1Emotion: _selectedTier1!,
      tier2Emotion: _selectedTier2,
      tier3Emotion: _selectedTier3,
      intensity: _isIntensityUnlocked ? _intensity.toInt() : 0,
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
            
            // --- TIER 2 SECTION (Always shows if Tier 1 selected) ---
            if (_selectedTier1 != null) ...[
              const Divider(height: 32),
              Text('Step 2: Secondary Emotion', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _isTier2Unlocked ? null : Colors.grey,
              )),
              const SizedBox(height: 8),
              if (_isTier2Unlocked)
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
                        });
                      },
                    );
                  }).toList(),
                )
              else
                const Text(
                  'More ways to describe this will appear as you continue to reflect.',
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),

              // --- TIER 3 SECTION (Only shows if Tier 2 is unlocked) ---
              if (_isTier2Unlocked) ...[
                const Divider(height: 32),
                Text('Step 3: Tertiary Emotion', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _isTier3Unlocked ? null : Colors.grey,
                )),
                const SizedBox(height: 8),
                if (_isTier3Unlocked)
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
                  )
                else
                  const Text(
                    'Even deeper layers of detail will become available over time.',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
              ],

              // --- INTENSITY SECTION (Only shows if Tier 3 is unlocked) ---
              if (_isTier3Unlocked) ...[
                const Divider(height: 32),
                Text(
                  _isIntensityUnlocked ? 'Intensity: ${_intensity.toInt()}' : 'Intensity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _isIntensityUnlocked ? null : Colors.grey,
                  ),
                ),
                if (_isIntensityUnlocked)
                  Slider(
                    value: _intensity,
                    min: 0,
                    max: 3,
                    divisions: 3,
                    label: _intensity.toInt().toString(),
                    activeColor: color,
                    onChanged: (value) => setState(() => _intensity = value),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Soon, you will be able to note the strength of these feelings.',
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
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
