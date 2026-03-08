import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
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

  final TextEditingController _customController = TextEditingController();
  final TextEditingController _reflectionController = TextEditingController();
  final TextEditingController _triggerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkUnlocks();
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
    if (SettingsService.shouldSkipUnlocking()) {
      setState(() {
        _isTier2Unlocked = true;
        _isTier3Unlocked = true;
        _isIntensityUnlocked = true;
        _isBodyMapUnlocked = true;
        _isTriggerUnlocked = true;
      });
      return;
    }

    setState(() {
      _isTier2Unlocked = DatabaseService.getTier1Count() >= 7;
      _isTier3Unlocked = DatabaseService.getTier2Count() >= 7;
      _isIntensityUnlocked = DatabaseService.getTier3Count() >= 7;
      _isBodyMapUnlocked = DatabaseService.getIntensityCount() >= 7;
      _isTriggerUnlocked = DatabaseService.getBodyMapCount() >= 3;
    });
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
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('A familiar feeling?'),
          content: Text(
            match.isCustom 
              ? 'You have used "$text" before as a part of the "${match.tier1}" category.\n\nWould you like to use that existing path?'
              : 'It looks like "$text" is already a built-in part of the "${match.tier1}" category.\n\nWould you like to use the existing path, or keep your own word?'
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
              child: const Text('Use Existing'),
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
    } else {
      _persistAndSetCustomValue(text, tier);
    }
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
    // Combine selected calendar date with current time
    final timestamp = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      now.hour,
      now.minute,
      now.second,
    );

    if (widget.existingEntry != null && widget.revisionType != null) {
      // Save as Revision
      final revision = EmotionEntryRevision(
        emotionEntryId: widget.existingEntry!.id,
        revisionType: widget.revisionType!,
        tier1Emotion: _selectedTier1!,
        tier2Emotion: _selectedTier2,
        tier3Emotion: _selectedTier3,
        intensity: _isIntensityUnlocked ? _intensity.toInt() : 0,
        reflectionText: _reflectionText,
        bodyMapData: _bodyMapData,
        trigger: _triggerText,
      );
      await DatabaseService.saveRevision(revision);
    } else {
      // Save as New Entry
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
    }
    
    if (mounted) Navigator.pop(context);
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
              Text('Step 2: Secondary Emotion', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _isTier2Unlocked ? null : Colors.grey,
              )),
              const SizedBox(height: 8),
              if (_isTier2Unlocked)
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
                )
              else
                const Text(
                  'More ways to describe this will appear as you continue to reflect.',
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),

              if (_isTier2Unlocked) ...[
                const Divider(height: 32),
                Text('Step 3: Tertiary Emotion', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _isTier3Unlocked ? null : Colors.grey,
                )),
                const SizedBox(height: 8),
                if (_isTier3Unlocked)
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
                  )
                else
                  const Text(
                    'Even deeper layers of detail will become available over time.',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
              ],

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

              if (_isIntensityUnlocked) ...[
                const Divider(height: 32),
                Text(
                  'Body Map',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _isBodyMapUnlocked ? null : Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                if (_isBodyMapUnlocked)
                  InkWell(
                    onTap: _openBodyMap,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
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
                            // A tiny visual preview of the drawing
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey[300]!),
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
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'In time, you\'ll be able to mark where in your body you feel this.',
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],

              if (_isBodyMapUnlocked) ...[
                const Divider(height: 32),
                Text(
                  'What influenced this?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _isTriggerUnlocked ? null : Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                if (_isTriggerUnlocked)
                  TextField(
                    controller: _triggerController,
                    decoration: const InputDecoration(
                      hintText: 'Was it a person, place, or event?',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _triggerText = value,
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'You\'ll soon be able to note down external triggers or influences.',
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
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
