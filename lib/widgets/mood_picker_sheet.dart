import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/mood.dart';
import '../models/mood_entry.dart';
import '../services/photo_storage.dart';

class MoodPickerResult {
  final List<Mood> moods;
  final String note;
  final String? imagePath;

  const MoodPickerResult({
    required this.moods,
    required this.note,
    this.imagePath,
  });
}

class MoodPickerSheet extends StatefulWidget {
  /// 수정할 기록. null이면 새 기록을 작성하는 것이다.
  final MoodEntry? initial;

  const MoodPickerSheet({super.key, this.initial});

  @override
  State<MoodPickerSheet> createState() => _MoodPickerSheetState();
}

class _MoodPickerSheetState extends State<MoodPickerSheet> {
  final _selected = <String>{};
  final _noteController = TextEditingController();
  String? _imagePath;
  double _dragOffset = 0;
  bool _dragging = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _selected.addAll(initial.emojis);
      _noteController.text = initial.note;
      if (initial.imageFileName != null) {
        _imagePath = PhotoStorage.pathFor(initial.imageFileName!);
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragging = true;
      _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, 600.0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragOffset > 100 || velocity > 700) {
      Navigator.pop(context);
    } else {
      setState(() {
        _dragging = false;
        _dragOffset = 0;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedback.lightImpact();
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _imagePath = picked.path);
  }

  void _showImageOptions() {
    HapticFeedback.lightImpact();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              _pickImage(ImageSource.camera);
            },
            child: const Text('사진 촬영'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              _pickImage(ImageSource.gallery);
            },
            child: const Text('앨범에서 선택'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(sheetContext),
          child: const Text('취소'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _dragging ? Duration.zero : const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _dragOffset, 0),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 드래그로 닫기는 상단 영역에서만 동작 — 시트 전체를 감싸면
          // 메모 입력란 내부 스크롤과 제스처가 충돌한다.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            onVerticalDragCancel: () => setState(() {
              _dragging = false;
              _dragOffset = 0;
            }),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey4.resolveFrom(context),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text.rich(
                  TextSpan(
                    text: _isEditing ? '기록 수정 ' : '오늘 기분이 어떠세요? ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                    children: [
                      TextSpan(
                        text: '(복수 선택 가능)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  children: Mood.all.map((mood) {
                    final isSelected = _selected.contains(mood.emoji);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (isSelected) {
                            _selected.remove(mood.emoji);
                          } else {
                            _selected.add(mood.emoji);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? mood.color.withValues(alpha: 0.35)
                              : CupertinoColors.tertiarySystemFill.resolveFrom(
                                  context,
                                ),
                          border: Border.all(
                            color: isSelected
                                ? mood.color
                                : const Color(0x00000000),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Text(
                              mood.emoji,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mood.label,
                              style: TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.label.resolveFrom(
                                  context,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CupertinoTextField(
            controller: _noteController,
            maxLines: 2,
            placeholder: '오늘 있었던 일을 적어보세요 (선택)',
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(height: 12),
          if (_imagePath == null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showImageOptions,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(CupertinoIcons.camera, size: 20),
                  SizedBox(width: 6),
                  Text('사진 추가'),
                ],
              ),
            )
          else
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(_imagePath!),
                    width: double.infinity,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _imagePath = null);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0x99000000),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        size: 16,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              borderRadius: BorderRadius.circular(12),
              onPressed: _selected.isEmpty
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(
                        context,
                        MoodPickerResult(
                          moods: Mood.all
                              .where((m) => _selected.contains(m.emoji))
                              .toList(),
                          note: _noteController.text.trim(),
                          imagePath: _imagePath,
                        ),
                      );
                    },
              child: Text(_isEditing ? '수정 완료' : '기록하기'),
            ),
          ),
        ],
      ),
    );
  }
}
