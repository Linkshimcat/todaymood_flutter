import SwiftUI
import WidgetKit

struct MoodGrassProvider: TimelineProvider {
  func placeholder(in context: Context) -> MoodEntryView {
    MoodEntryView(date: Date(), data: .placeholder)
  }

  func getSnapshot(
    in context: Context,
    completion: @escaping (MoodEntryView) -> Void
  ) {
    let data = context.isPreview ? MoodWidgetData.placeholder : MoodWidgetData.load()
    completion(MoodEntryView(date: Date(), data: data))
  }

  func getTimeline(
    in context: Context,
    completion: @escaping (Timeline<MoodEntryView>) -> Void
  ) {
    let entry = MoodEntryView(date: Date(), data: MoodWidgetData.load())
    let midnight = Calendar.current.startOfDay(
      for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    )
    completion(Timeline(entries: [entry], policy: .after(midnight)))
  }
}

/// 깃허브 잔디처럼 하루 한 칸씩, 그날 기분 색으로 채운다.
struct MoodGrassWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: "MoodGrassWidget",
      provider: MoodGrassProvider()
    ) { entry in
      MoodGrassView(data: entry.data)
        .widgetContainerBackground()
    }
    .configurationDisplayName("기분 잔디")
    .description("기록한 날을 그날의 기분 색으로 채웁니다.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct MoodGrassView: View {
  let data: MoodWidgetData

  private let spacing: CGFloat = 2.5
  /// 칸 하나의 목표 크기. 위젯 폭에 맞춰 보여줄 주 수를 여기서 역산한다.
  private let targetCell: CGFloat = 11

  var body: some View {
    GeometryReader { geometry in
      let weeks = weekCount(for: geometry.size.width)
      let cell = (geometry.size.width - spacing * CGFloat(weeks - 1))
        / CGFloat(weeks)

      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 4) {
          Text(data.recorded ? data.emojis : "✍️")
            .font(.system(size: 13))
            .lineLimit(1)
          Text(recordedCountText(weeks: weeks))
            .font(.caption2)
            .foregroundStyle(.secondary)
          Spacer(minLength: 0)
        }

        Spacer(minLength: 0)

        HStack(spacing: spacing) {
          ForEach(0..<weeks, id: \.self) { column in
            VStack(spacing: spacing) {
              ForEach(0..<7, id: \.self) { row in
                cellView(
                  column: column, row: row, size: cell, weeks: weeks
                )
              }
            }
          }
        }

        Spacer(minLength: 0)
      }
    }
  }

  /// 칸 크기를 일정하게 유지하려고 폭에 따라 주 수를 정한다.
  private func weekCount(for width: CGFloat) -> Int {
    let raw = Int((width + spacing) / (targetCell + spacing))
    return min(26, max(8, raw))
  }

  private func cellView(
    column: Int, row: Int, size: CGFloat, weeks: Int
  ) -> some View {
    let date = dateFor(column: column, row: row, weeks: weeks)
    let isFuture = date > Calendar.current.startOfDay(for: Date())
    let key = MoodWidgetData.dayFormatter.string(from: date)
    let color = data.colorsByDay[key].flatMap { Color(hex: $0) }

    let shape = RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
    return shape
      .fill(color ?? Color.secondary.opacity(0.18))
      // 검정처럼 어두운 기분 색도 배경에 묻히지 않도록 옅은 테두리를 준다.
      .overlay(
        shape.strokeBorder(
          Color.primary.opacity(color == nil ? 0 : 0.22),
          lineWidth: 0.5
        )
      )
      .frame(width: size, height: size)
      .opacity(isFuture ? 0 : 1)
  }

  /// 맨 오른쪽 열이 이번 주가 되도록 역산한다. 행은 월요일(0)~일요일(6).
  private func dateFor(column: Int, row: Int, weeks: Int) -> Date {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    // Calendar의 weekday는 일요일이 1이므로 월요일 시작으로 옮긴다.
    let mondayBased = (calendar.component(.weekday, from: today) + 5) % 7
    let daysFromStart = (column - (weeks - 1)) * 7 + (row - mondayBased)
    return calendar.date(byAdding: .day, value: daysFromStart, to: today) ?? today
  }

  private func recordedCountText(weeks: Int) -> String {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let span = weeks * 7
    let recorded = data.colorsByDay.keys.filter { key in
      guard let date = MoodWidgetData.dayFormatter.date(from: key) else {
        return false
      }
      let days = calendar.dateComponents([.day], from: date, to: today).day ?? 0
      return days >= 0 && days < span
    }.count
    return "\(span)일 중 \(recorded)일"
  }
}
