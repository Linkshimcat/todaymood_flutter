import 'package:flutter/cupertino.dart';

import '../models/mood.dart';

class MoodPickerResult {
  final Mood mood;
  final String note;

  const MoodPickerResult({required this.mood, required this.note});
}

class MoodPickerSheet extends StatefulWidget {
  const MoodPickerSheet({super.key});

  @override
  State<MoodPickerSheet> createState() => _MoodPickerSheetState();
}

class _MoodPickerSheetState extends State<MoodPickerSheet> {
  Mood? _selected;
  final _noteController = TextEditingController();
  double _dragOffset = 0;
  bool _dragging = false;

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
                Text(
                  '오늘 기분이 어떠세요? (*복수 체크 가능)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  children: Mood.all.map((mood) {
                    final isSelected = mood.emoji == _selected?.emoji;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = mood),
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              borderRadius: BorderRadius.circular(12),
              onPressed: _selected == null
                  ? null
                  : () => Navigator.pop(
                      context,
                      MoodPickerResult(
                        mood: _selected!,
                        note: _noteController.text.trim(),
                      ),
                    ),
              child: const Text('기록하기'),
            ),
          ),
        ],
      ),
    );
  }
}
