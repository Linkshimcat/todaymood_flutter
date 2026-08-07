import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../models/mood.dart';
import '../models/mood_entry.dart';
import '../services/photo_storage.dart';
import 'photo_viewer.dart';

class MoodCard extends StatelessWidget {
  final MoodEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const MoodCard({
    super.key,
    required this.entry,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final moods = entry.emojis.map(Mood.fromEmoji).toList();
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: CupertinoColors.destructiveRed,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(CupertinoIcons.delete, color: CupertinoColors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
              context,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: moods
                        .map(
                          (mood) => Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: mood.color.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              mood.emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          moods.map((m) => m.label).join(' · '),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('M월 d일 (E) HH:mm', 'ko_KR').format(
                            entry.date,
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                        if (entry.note.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            entry.note,
                            style: TextStyle(
                              fontSize: 15,
                              color: CupertinoColors.label.resolveFrom(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (entry.imageFileName != null) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => PhotoViewer.show(
                    context,
                    PhotoStorage.pathFor(entry.imageFileName!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(PhotoStorage.pathFor(entry.imageFileName!)),
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 160,
                        alignment: Alignment.center,
                        color: CupertinoColors.tertiarySystemFill.resolveFrom(
                          context,
                        ),
                        child: Icon(
                          CupertinoIcons.photo,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
