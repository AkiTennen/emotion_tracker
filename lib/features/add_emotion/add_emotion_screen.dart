import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/emotion_data.dart';
import '../../models/emotion_entry.dart';
import '../../models/emotion_entry_revision.dart';
import '../../services/database_service.dart';
import '../../services/settings_service.dart';
import 'body_map_screen.dart';

class AddEmotionScreen extends StatefulWidget {
  final DateTime selectedDate;
  final EmotionEntry? existingEntry;
  final RevisionType? revisionType;

  const AddEmotionScreen({
    super.key,
    required this.selectedDate,
    this.existingEntry,
    this.revisionType,
  });

  @override
  State<AddEmotionScreen> createState() => _AddEmotionScreenState();
}

class _AddEmotionScreenState extends State<AddEmotionScreen> {
  String? _selectedTier1;
  String? _selectedTier2;
  String? _selectedTier3;
  double _intensity = 1.0;
  String? _reflectionText;
  Map<String, dynamic>? _bodyMapData;
  String? _triggerText;

  bool _isTier2Unlocked = false;
  bool _isTier3Unlocked = false;
  bool _isIntensityUnlocked = false;
  bool _isBodyMapUnlocked = false;
  bool _isTriggerUnlocked = false;
  
  bool _showStep1Hint = false;
  bool _showTier2Hint = false;
  bool _showTier3Hint = false;
  bool _showIntensityHint = false;

  final TextEditingController _customController = TextEditingController();
  final TextEditingController _reflectionController = TextEditingController();
  final TextEditingController _triggerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkUnlocks();
    _showStep1Hint = !SettingsService.isFirstEntryHintShown() && widget.existingEntry == null;
    
    if (widget.existingEntry != null) {
      _selectedTier1 = widget.existingEntry!.tier1Emotion;
      _selectedTier2 = widget.existingEntry!.tier2Emotion;
      _selectedTier3 = widget.existingEntry!.tier3Emotion;
      _intensity = widget.existingEntry!.intensity.toDouble();
      _bodyMapData = widget.existingEntry!.bodyMapData;
      _triggerText = widget.existingEntry!.trigger;
      _triggerController.text = _triggerText ?? '';
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    _reflectionController.dispose();
    _triggerController.dispose();
    super.dispose();
  }

  void _checkUnlocks() {
    setState(() {
      _isTier2Unlocked = SettingsService.isTier2Unlocked();
      _isTier3Unlocked = SettingsService.isTier3Unlocked();
      _isIntensityUnlocked = SettingsService.isIntensityUnlocked(); 
      _isBodyMapUnlocked = SettingsService.isBodyMapUnlocked();
      _isTriggerUnlocked = SettingsService.isTriggerPromptsUnlocked();
      
      _showTier2Hint = _isTier2Unlocked && !SettingsService.isTier2IntroShown() && widget.existingEntry == null;
      _showTier3Hint = _isTier3Unlocked && !SettingsService.isTier3IntroShown() && widget.existingEntry == null;
      _showIntensityHint = _isIntensityUnlocked && !SettingsService.isIntensityIntroShown() && widget.existingEntry == null;
    });
  }

  void _showTier2Guide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber),
            SizedBox(width: 12),
            Text('Exploring Detail'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You\'ve unlocked more detail! Here is how to use it:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              _GuidePoint(
                icon: Icons.alt_route,
                title: 'It\'s Optional',
                description: 'Not every feeling needs a sub-category. If the primary emotion says it all, feel free to just save it there.',
              ),
              _GuidePoint(
                icon: Icons.edit_note,
                title: 'Custom Words',
                description: 'Can\'t find the right word? Tap "Custom" to add your own. We\'ll remember them for next time.',
              ),
              _GuidePoint(
                icon: Icons.gesture,
                title: 'Managing Words',
                description: 'To "forget" a custom word, just long-press its chip to remove it from your list.',
              ),
              _GuidePoint(
                icon: Icons.psychology,
                title: 'Staying Consistent',
                description: 'If you use a word that already exists elsewhere, we\'ll let you know. Keeping your emotions consistent helps your patterns stay clear.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showTier3Guide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.diamond_outlined, color: Colors.cyan),
            SizedBox(width: 12),
            Text('Nuance & Depth'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You\'ve reached the final layer of emotional depth.', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              _GuidePoint(
                icon: Icons.filter_center_focus,
                title: 'Maximum Nuance',
                description: 'Tertiary emotions allow you to be incredibly specific. Like the layers before, this is entirely optional.',
              ),
              _GuidePoint(
                icon: Icons.add_circle_outline,
                title: 'Even More Customization',
                description: 'You can add custom words here too. They belong specifically to the Primary category you chose at the start.',
              ),
              _GuidePoint(
                icon: Icons.analytics_outlined,
                title: 'Better Patterns',
                description: 'The more specific you are, the better you\'ll be able to see the subtle differences in your moods over time.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showIntensityGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.speed, color: Colors.orange),
            SizedBox(width: 12),
            Text('Tracking Intensity'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How "loud" is this feeling?', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              _GuidePoint(
                icon: Icons.linear_scale,
                title: 'Simple Scale (0-3)',
                description: '0 is very mild, 3 is overwhelming. Most emotions fall somewhere in between.',
              ),
              _GuidePoint(
                icon: Icons.palette_outlined,
                title: 'Visual Impact',
                description: 'High intensity emotions show up with stronger, brighter colors on your Home Screen journey.',
              ),
              _GuidePoint(
                icon: Icons.history,
                title: 'Spot Patterns',
                description: 'Tracking intensity helps you see not just what you feel, but how strongly those feelings impact your day.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showCustomDialog(int tier) {
    if (tier == 2 && _selectedTier2 != null && !EmotionData.getTier2(_selectedTier1!).contains(_selectedTier2)) {
      _customController.text = _selectedTier2!;
    } else if (tier == 3 && _selectedTier3 != null && !EmotionData.getAllTier3ForCategory(_selectedTier1!).contains(_selectedTier3)) {
      _customController.text = _selectedTier3!;
    } else {
      _customController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Custom Tier $tier Emotion'),
        content: TextField(
          controller: _customController,
          decoration: const InputDecoration(hintText: 'How would you describe it?'),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final text = _customController.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(context);
              _handleCustomEmotion(text, tier);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _handleCustomEmotion(String text, int tier) {
    final allT2 = <String, List<String>>{};
    final allT3 = <String, List<String>>{};
    
    for (var t1 in EmotionData.tier1) {
      final t2List = DatabaseService.getCustomTier2Emotions(t1);
      if (t2List.isNotEmpty) allT2[t1] = t2List;
      
      final t3List = DatabaseService.getCustomTier3Emotions(t1);
      if (t3List.isNotEmpty) allT3[t1] = t3List;
    }

    final match = EmotionData.findMatch(text, customT2Map: allT2, customT3Map: allT3);

    if (match != null) {
      bool isMatchUnlocked = false;
      if (match.tier == 1) isMatchUnlocked = true;
      if (match.tier == 2 && _isTier2Unlocked) isMatchUnlocked = true;
      if (match.tier == 3 && _isTier3Unlocked) isMatchUnlocked = true;

      if (isMatchUnlocked) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('We\'ve met this feeling before'),
            content: Text(
              match.isCustom 
                ? 'You have used "$text" before as a part of the "${match.tier1}" category.\n\nTo keep your patterns clear, would you like to use that existing path?'
                : 'It looks like "$text" is already a built-in part of the "${match.tier1}" category.\n\nWould you like to use the existing path, or keep your own word here?'
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedTier1 = match.tier1;
                    _selectedTier2 = match.tier2;
                    _selectedTier3 = match.tier3;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Use Existing Path'),
              ),
              TextButton(
                onPressed: () async {
                  await _persistAndSetCustomValue(text, tier);
                  Navigator.pop(context);
                },
                child: const Text('Keep Custom'),
              ),
            ],
          ),
        );
        return;
      }
    }
    
    _persistAndSetCustomValue(text, tier);
  }

  Future<void> _persistAndSetCustomValue(String text, int tier) async {
    if (_selectedTier1 == null) return;
    
    if (tier == 2) {
      await DatabaseService.addCustomTier2Emotion(_selectedTier1!, text);
      setState(() => _selectedTier2 = text);
    } else {
      await DatabaseService.addCustomTier3Emotion(_selectedTier1!, text);
      setState(() => _selectedTier3 = text);
    }
    _customController.clear();
  }

  void _confirmDeleteCustom(String emotion, int tier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forget this emotion?'),
        content: Text('Are you sure you want to remove "$emotion" from your list? This won\'t change your past logs.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep')),
          TextButton(
            onPressed: () async {
              if (tier == 2) {
                await DatabaseService.removeCustomTier2Emotion(_selectedTier1!, emotion);
                if (_selectedTier2 == emotion) setState(() => _selectedTier2 = null);
              } else {
                await DatabaseService.removeCustomTier3Emotion(_selectedTier1!, emotion);
                if (_selectedTier3 == emotion) setState(() => _selectedTier3 = null);
              }
              Navigator.pop(context);
              setState(() {}); // Refresh chips
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _saveEntry() async {
    if (_selectedTier1 == null) return;

    final now = DateTime.now();
    final timestamp = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      now.hour,
      now.minute,
      now.second,
    );

    if (widget.existingEntry != null && widget.revisionType != null) {
      final revision = EmotionEntryRevision(
        emotionEntryId: widget.existingEntry!.id,
        revisionType: widget.revisionType!,
        tier1Emotion: _selectedTier1!,
        tier2Emotion: _selectedTier2,
        tier3Emotion: _selectedTier3,
        intensity: _isIntensityUnlocked ? _intensity.toInt() : 0,
        reflectionText: _reflectionController.text.trim(),
        bodyMapData: _bodyMapData,
        trigger: _triggerText,
      );
      await DatabaseService.saveRevision(revision);
    } else {
      final entry = EmotionEntry(
        id: const Uuid().v4(),
        timestamp: timestamp,
        createdAt: now,
        tier1Emotion: _selectedTier1!,
        tier2Emotion: _selectedTier2,
        tier3Emotion: _selectedTier3,
        intensity: _isIntensityUnlocked ? _intensity.toInt() : 0,
        bodyMapData: _bodyMapData,
        trigger: _triggerText,
      );
      await DatabaseService.saveEntry(entry);
      
      if (!SettingsService.isFirstEntryHintShown()) {
        await SettingsService.setFirstEntryHintShown(true);
      }
      
      if (_showTier2Hint || _selectedTier2 != null) {
        await SettingsService.setTier2IntroShown(true);
      }

      if (_showTier3Hint || _selectedTier3 != null) {
        await SettingsService.setTier3IntroShown(true);
      }

      if (_showIntensityHint || _intensity != 1.0) {
        await SettingsService.setIntensityIntroShown(true);
      }
    }
    
    _updateProgressionThresholds();

    if (mounted) Navigator.pop(context);
  }

  void _updateProgressionThresholds() async {
    if (!SettingsService.isTier2Unlocked() && DatabaseService.getTier1Count() >= 7) {
      await SettingsService.setTier2Unlocked(true);
    }
    if (!SettingsService.isTier3Unlocked() && DatabaseService.getTier2Count() >= 7) {
      await SettingsService.setTier3Unlocked(true);
    }
    if (!SettingsService.isIntensityUnlocked() && DatabaseService.getTier3Count() >= 7) {
      await SettingsService.setIntensityUnlocked(true);
    }
    if (!SettingsService.isBodyMapUnlocked() && DatabaseService.getIntensityCount() >= 7) {
      await SettingsService.setBodyMapUnlocked(true);
    }
    if (!SettingsService.isTriggerPromptsUnlocked() && DatabaseService.getBodyMapCount() >= 3) {
      await SettingsService.setTriggerPromptsUnlocked(true);
    }
  }

  void _openBodyMap() async {
    if (!SettingsService.isBodyMapIntroShown()) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Listening to your body'),
          content: const Text(
            'Sometimes emotions aren\'t just in our heads—they\'re in our bodies too.\n\n'
            'In this screen, you can "draw" where you feel this emotion. Use two fingers to zoom in and pan for more detail.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      await SettingsService.setBodyMapIntroShown(true);
    }

    if (!mounted) return;

    final color = _selectedTier1 != null ? EmotionData.getColor(_selectedTier1!) : Colors.grey;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => BodyMapScreen(
          initialData: _bodyMapData,
          emotionColor: color,
        ),
      ),
    );

    if (result != null) {
      setState(() => _bodyMapData = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _selectedTier1 != null ? EmotionData.getColor(_selectedTier1!) : null;

    final customT2 = _selectedTier1 != null ? DatabaseService.getCustomTier2Emotions(_selectedTier1!) : <String>[];
    final customT3 = _selectedTier1 != null ? DatabaseService.getCustomTier3Emotions(_selectedTier1!) : <String>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.revisionType == null 
            ? 'How are you feeling?' 
            : (widget.revisionType == RevisionType.correction ? 'Correcting entry' : 'Reflecting on entry')),
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
            if (_showStep1Hint)
              _HintCard(
                text: 'Every emotion starts here. Pick the one that fits best in this moment.',
                onClose: () => setState(() => _showStep1Hint = false),
              ),
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
                      _showStep1Hint = false; 
                    });
                  },
                );
              }).toList(),
            ),
            
            if (_selectedTier1 != null) ...[
              if (_isTier2Unlocked) ...[
                const Divider(height: 32),
                if (_showTier2Hint)
                  _HintCard(
                    text: 'You\'ve unlocked more detail! You can now choose a secondary emotion, or skip this if it doesn\'t feel right.',
                    onClose: () async {
                      await SettingsService.setTier2IntroShown(true);
                      setState(() => _showTier2Hint = false);
                    },
                    onInfo: _showTier2Guide,
                  ),
                Text('Step 2: Secondary Emotion', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ...EmotionData.getTier2(_selectedTier1!).map((e) {
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
                    }),
                    ...customT2.map((e) {
                      return GestureDetector(
                        onLongPress: () => _confirmDeleteCustom(e, 2),
                        child: ChoiceChip(
                          avatar: const Icon(Icons.face_outlined, size: 16),
                          label: Text(e),
                          selected: _selectedTier2 == e,
                          selectedColor: color?.withOpacity(0.4),
                          onSelected: (selected) {
                            setState(() {
                              _selectedTier2 = selected ? e : null;
                            });
                          },
                        ),
                      );
                    }),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: const Text('Custom'),
                      onPressed: () => _showCustomDialog(2),
                    ),
                  ],
                ),
              ],

              if (_isTier3Unlocked) ...[
                const Divider(height: 32),
                if (_showTier3Hint)
                  _HintCard(
                    text: 'Nuance & Depth unlocked! Tertiary emotions help you be even more specific with how you feel.',
                    onClose: () async {
                      await SettingsService.setTier3IntroShown(true);
                      setState(() => _showTier3Hint = false);
                    },
                    onInfo: _showTier3Guide,
                  ),
                Text('Step 3: Tertiary Emotion', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ...EmotionData.getAllTier3ForCategory(_selectedTier1!).map((e) {
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
                    }),
                    ...customT3.map((e) {
                      return GestureDetector(
                        onLongPress: () => _confirmDeleteCustom(e, 3),
                        child: ChoiceChip(
                          avatar: const Icon(Icons.face_outlined, size: 16),
                          label: Text(e),
                          selected: _selectedTier3 == e,
                          selectedColor: color?.withOpacity(0.4),
                          onSelected: (selected) {
                            setState(() {
                              _selectedTier3 = selected ? e : null;
                            });
                          },
                        ),
                      );
                    }),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: const Text('Custom'),
                      onPressed: () => _showCustomDialog(3),
                    ),
                  ],
                ),
              ],

              if (_isIntensityUnlocked) ...[
                const Divider(height: 32),
                if (_showIntensityHint)
                  _HintCard(
                    text: 'How strong is this feeling? Intensity helps you track the volume of your emotions.',
                    onClose: () async {
                      await SettingsService.setIntensityIntroShown(true);
                      setState(() => _showIntensityHint = false);
                    },
                    onInfo: _showIntensityGuide,
                  ),
                Text('Intensity: ${_intensity.toInt()}', style: Theme.of(context).textTheme.titleMedium),
                Slider(
                  value: _intensity,
                  min: 0,
                  max: 3,
                  divisions: 3,
                  label: _intensity.toInt().toString(),
                  activeColor: color,
                  onChanged: (value) {
                    if (_showIntensityHint) {
                      SettingsService.setIntensityIntroShown(true);
                      setState(() {
                        _intensity = value;
                        _showIntensityHint = false;
                      });
                    } else {
                      setState(() => _intensity = value);
                    }
                  },
                ),
              ],

              if (_isBodyMapUnlocked) ...[
                const Divider(height: 32),
                Text('Body Map', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _openBodyMap,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.accessibility_new, color: color ?? Colors.grey),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Where do you feel this?'),
                              if (_bodyMapData != null)
                                const Text(
                                  'Area marked',
                                  style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                        ),
                        if (_bodyMapData != null)
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: CustomPaint(
                              painter: BodyMapSmallPreviewPainter(
                                data: _bodyMapData!,
                                color: color ?? Colors.grey,
                              ),
                            ),
                          ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ],

              if (_isTriggerUnlocked) ...[
                const Divider(height: 32),
                Text('What influenced this?', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _triggerController,
                  decoration: const InputDecoration(
                    hintText: 'Was it a person, place, or event?',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _triggerText = value,
                ),
              ],
            ],

            if (widget.revisionType == RevisionType.reflection) ...[
              const Divider(height: 32),
              Text('Why does this feel different now?', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _reflectionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add some context to your reflection...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _reflectionText = value,
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
                  child: Text(widget.revisionType == null ? 'Save Entry' : 'Save Revision'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  final String text;
  final VoidCallback onClose;
  final VoidCallback? onInfo;

  const _HintCard({required this.text, required this.onClose, this.onInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (onInfo != null)
            IconButton(
              icon: const Icon(Icons.help_outline, size: 18),
              onPressed: onInfo,
              tooltip: 'Learn more',
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _GuidePoint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _GuidePoint({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BodyMapSmallPreviewPainter extends CustomPainter {
  final Map<String, dynamic> data;
  final Color color;

  BodyMapSmallPreviewPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final midX = size.width / 2;
    final front = data['frontPaths'] as List?;
    final back = data['backPaths'] as List?;

    if (front != null) {
      for (var path in front) {
        final screenPath = Path();
        final points = path as List;
        if (points.isEmpty) continue;
        screenPath.moveTo(points[0][0] * midX, points[0][1] * size.height);
        for (var i = 1; i < points.length; i++) {
          screenPath.lineTo(points[i][0] * midX, points[i][1] * size.height);
        }
        canvas.drawPath(screenPath, paint);
      }
    }

    if (back != null) {
      for (var path in back) {
        final screenPath = Path();
        final points = path as List;
        if (points.isEmpty) continue;
        screenPath.moveTo((points[0][0] * midX) + midX, points[0][1] * size.height);
        for (var i = 1; i < points.length; i++) {
          screenPath.lineTo((points[i][0] * midX) + midX, points[i][1] * size.height);
        }
        canvas.drawPath(screenPath, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
