import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../models/mood_entry.dart';
import '../services/live_activity_service.dart';
import '../services/mood_editor.dart';
import '../services/mood_storage.dart';
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
    MoodStorage.cache.addListener(_onCacheChanged);
    MoodStorage.syncing.addListener(_onSyncingChanged);
    _load();
  }

  @override
  void dispose() {
    MoodStorage.cache.removeListener(_onCacheChanged);
    MoodStorage.syncing.removeListener(_onSyncingChanged);
    super.dispose();
  }

  void _onCacheChanged() {
    if (!mounted) return;
    setState(() => _entries = MoodStorage.cache.value);
  }

  void _onSyncingChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _load() async {
    final entries = await _storage.load();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      _storage.refresh(),
      Future<void>.delayed(const Duration(milliseconds: 1200)),
    ]);
  }

  static const _indicatorRadius = 15.0;

  Widget _buildRefreshIndicator(
    BuildContext context,
    RefreshIndicatorMode refreshState,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent,
  ) {
    final topInset = MediaQuery.paddingOf(context).top;
    final percentageComplete = (pulledExtent / refreshTriggerPullDistance)
        .clamp(0.0, 1.0)
        .toDouble();
    final primary = CupertinoTheme.of(context).primaryColor;
    final blue = CupertinoColors.systemBlue.resolveFrom(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primary.withValues(alpha: 0.16),
            blue.withValues(alpha: 0.09),
            primary.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: topInset + 18,
              left: 0,
              right: 0,
              child: _indicatorForState(refreshState, percentageComplete),
            ),
            if (refreshState == RefreshIndicatorMode.refresh)
              Positioned(
                top: topInset + 56,
                left: 0,
                right: 0,
                child: const Text(
                  '오늘의 기분 리프레시 중..',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _indicatorForState(
    RefreshIndicatorMode refreshState,
    double percentageComplete,
  ) {
    switch (refreshState) {
      case RefreshIndicatorMode.drag:
        return Opacity(
          opacity: const Interval(
            0.0,
            0.35,
            curve: Curves.easeInOut,
          ).transform(percentageComplete),
          child: CupertinoActivityIndicator.partiallyRevealed(
            radius: _indicatorRadius,
            progress: percentageComplete,
          ),
        );
      case RefreshIndicatorMode.armed:
      case RefreshIndicatorMode.refresh:
        return CupertinoActivityIndicator(radius: _indicatorRadius);
      case RefreshIndicatorMode.done:
        return CupertinoActivityIndicator(
          radius: _indicatorRadius * percentageComplete,
        );
      case RefreshIndicatorMode.inactive:
        return const SizedBox.shrink();
    }
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
    if (entry.imageFileName != null) {
      await PhotoStorage.delete(entry.imageFileName!);
    }
    await LiveActivityService.refresh();
    await WidgetService.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return CupertinoPageScaffold(
      backgroundColor: kAppBackground,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: _refresh,
            refreshIndicatorExtent: 120 + topInset,
            refreshTriggerPullDistance: 140 + topInset,
            builder: _buildRefreshIndicator,
          ),
          const CupertinoSliverNavigationBar(
            backgroundColor: kNavBarBackground,
            largeTitle: Text('오늘의 기분은?'),
          ),
          if (MoodStorage.syncing.value)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 4),
                child: _SyncBadge(),
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

/// 클라우드 동기화가 도는 동안 상단에 표시되는 작은 배지.
class _SyncBadge extends StatelessWidget {
  const _SyncBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(radius: 8),
            const SizedBox(width: 8),
            Text(
              '동기화 중..',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
