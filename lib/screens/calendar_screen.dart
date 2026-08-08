import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/mood.dart';
import '../models/mood_entry.dart';
import '../services/live_activity_service.dart';
import '../services/mood_editor.dart';
import '../services/mood_storage.dart';
import '../services/photo_storage.dart';
import '../services/widget_service.dart';
import '../theme.dart';
import '../widgets/mood_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const _dayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  final _storage = MoodStorage();
  Map<DateTime, List<MoodEntry>> _byDay = {};
  late DateTime _month;
  late DateTime _selected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    MoodStorage.cache.addListener(_onCacheChanged);
    final today = _dateOnly(DateTime.now());
    _month = DateTime(today.year, today.month);
    _selected = today;
    _load();
  }

  @override
  void dispose() {
    MoodStorage.cache.removeListener(_onCacheChanged);
    super.dispose();
  }

  void _onCacheChanged() {
    if (!mounted) return;
    _apply(MoodStorage.cache.value);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _load() async {
    final entries = await _storage.load();
    _apply(entries);
  }

  void _apply(List<MoodEntry> entries) {
    final grouped = <DateTime, List<MoodEntry>>{};
    for (final entry in entries) {
      grouped.putIfAbsent(_dateOnly(entry.date), () => []).add(entry);
    }
    setState(() {
      _byDay = grouped;
      _loading = false;
    });
  }

  Future<void> _edit(MoodEntry entry) async {
    if (await editMoodEntry(context, entry)) await _load();
  }

  Future<void> _delete(MoodEntry entry) async {
    HapticFeedback.mediumImpact();
    final entries = await _storage.load();
    entries.removeWhere((e) => e.id == entry.id);
    await _storage.save(entries);
    if (entry.imageFileName != null) {
      await PhotoStorage.delete(entry.imageFileName!);
    }
    await LiveActivityService.refresh();
    await WidgetService.refresh();
    await _load();
  }

  void _changeMonth(int delta) {
    HapticFeedback.lightImpact();
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final selectedEntries = _byDay[_selected] ?? const <MoodEntry>[];
    return CupertinoPageScaffold(
      backgroundColor: kAppBackground,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: kNavBarBackground,
        middle: Text('달력'),
      ),
      child: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildMonthHeader()),
                  SliverToBoxAdapter(child: _buildWeekdayLabels(context)),
                  SliverToBoxAdapter(child: _buildGrid(context)),
                  SliverToBoxAdapter(child: _buildSelectedHeader(context)),
                  if (selectedEntries.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Center(
                          child: Text(
                            '이 날은 기록이 없어요',
                            style: TextStyle(
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList.builder(
                      itemCount: selectedEntries.length,
                      itemBuilder: (context, i) => MoodCard(
                        entry: selectedEntries[i],
                        onDelete: () => _delete(selectedEntries[i]),
                        onTap: () => _edit(selectedEntries[i]),
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: kBottomNavSpace),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _changeMonth(-1),
            child: const Icon(CupertinoIcons.chevron_left, size: 20),
          ),
          Text(
            DateFormat('yyyy년 M월', 'ko_KR').format(_month),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _changeMonth(1),
            child: const Icon(CupertinoIcons.chevron_right, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayLabels(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: _dayLabels
            .map(
              (label) => Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final firstDay = DateTime(_month.year, _month.month);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // 월요일 시작 그리드라 앞쪽 빈칸 수는 첫날의 요일 - 1이다.
    final leadingBlanks = firstDay.weekday - 1;
    final cells = leadingBlanks + daysInMonth;
    final rows = (cells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        children: List.generate(rows, (row) {
          return Row(
            children: List.generate(7, (col) {
              final dayNumber = row * 7 + col - leadingBlanks + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const Expanded(child: SizedBox(height: 52));
              }
              return Expanded(
                child: _buildDayCell(
                  context,
                  DateTime(_month.year, _month.month, dayNumber),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime day) {
    final entries = _byDay[day];
    final isSelected = day == _selected;
    final isToday = day == _dateOnly(DateTime.now());
    final mood = entries == null ? null : Mood.fromEmoji(entries.first.emojis.first);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selected = day);
      },
      child: Container(
        height: 52,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? CupertinoTheme.of(context).primaryColor.withValues(alpha: 0.18)
              : mood?.color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(
                  color: CupertinoTheme.of(context).primaryColor,
                  width: 1.5,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                color: isToday
                    ? CupertinoTheme.of(context).primaryColor
                    : CupertinoColors.label.resolveFrom(context),
              ),
            ),
            if (entries != null)
              Text(
                entries.first.emojis.first,
                style: const TextStyle(fontSize: 17),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        DateFormat('M월 d일 (E)', 'ko_KR').format(_selected),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }
}
