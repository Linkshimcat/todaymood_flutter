import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../models/mood_entry.dart';
import '../services/live_activity_service.dart';
import '../services/mood_editor.dart';
import '../services/mood_storage.dart';
import '../services/mood_sync_service.dart';
import '../services/photo_storage.dart';
import '../services/widget_service.dart';
import '../theme.dart';
import '../widgets/mood_card.dart';

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
    if (await createMoodEntry(context)) await _load();
  }

  Future<void> _editMood(MoodEntry entry) async {
    if (await editMoodEntry(context, entry)) await _load();
  }

  Future<void> _deleteMood(MoodEntry entry) async {
    HapticFeedback.mediumImpact();
    setState(() => _entries.removeWhere((e) => e.id == entry.id));
    await _storage.save(_entries);
    await MoodSyncService.instance.push(_entries);
    if (entry.imageFileName != null) {
      await PhotoStorage.delete(entry.imageFileName!);
    }
    await LiveActivityService.refresh();
    await WidgetService.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            backgroundColor: kNavBarBackground,
            largeTitle: Text('오늘의 기분은?'),
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
              padding: const EdgeInsets.only(top: 10, bottom: kBottomNavSpace),
              sliver: SliverList.builder(
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  return MoodCard(
                    entry: entry,
                    onDelete: () => _deleteMood(entry),
                    onTap: () => _editMood(entry),
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
