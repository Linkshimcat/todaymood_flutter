import 'package:flutter/cupertino.dart';

import '../models/mood_entry.dart';
import '../services/mood_storage.dart';
import '../widgets/mood_card.dart';
import '../widgets/mood_picker_sheet.dart';
import 'reminder_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = MoodStorage();
  List<MoodEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _storage.load();
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _addMood() async {
    final result = await showCupertinoModalPopup<MoodPickerResult>(
      context: context,
      builder: (_) => const MoodPickerSheet(),
    );
    if (result == null) return;

    final entry = MoodEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: DateTime.now(),
      emoji: result.mood.emoji,
      note: result.note,
    );

    setState(() => _entries.insert(0, entry));
    await _storage.save(_entries);
  }

  Future<void> _deleteMood(MoodEntry entry) async {
    setState(() => _entries.removeWhere((e) => e.id == entry.id));
    await _storage.save(_entries);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('오늘의 기분은?'),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.push(
                context,
                CupertinoPageRoute<void>(
                  builder: (_) => const ReminderScreen(),
                ),
              ),
              child: const Icon(CupertinoIcons.bell, size: 24),
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _addMood,
              child: const Icon(CupertinoIcons.add_circled_solid, size: 28),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (_entries.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(onAdd: _addMood),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(top: 10, bottom: 40),
              sliver: SliverList.builder(
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  return MoodCard(
                    entry: entry,
                    onDelete: () => _deleteMood(entry),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🙂', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            '아직 기록된 기분이 없어요.\n오늘의 기분을 기록해보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton.filled(
            borderRadius: BorderRadius.circular(26),
            onPressed: onAdd,
            child: const Text('기분 기록하기'),
          ),
        ],
      ),
    );
  }
}
