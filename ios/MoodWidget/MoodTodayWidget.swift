import SwiftUI
import WidgetKit

struct MoodEntryView: TimelineEntry {
  let date: Date
  let data: MoodWidgetData
}

struct MoodTodayProvider: TimelineProvider {
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
    // 날짜가 바뀌면 "오늘"의 기준도 바뀌므로 자정에 다시 그린다.
    let midnight = Calendar.current.startOfDay(
      for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    )
    completion(Timeline(entries: [entry], policy: .after(midnight)))
  }
}

struct MoodTodayWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: "MoodTodayWidget",
      provider: MoodTodayProvider()
    ) { entry in
      MoodTodayView(data: entry.data)
        .widgetContainerBackground()
    }
    .configurationDisplayName("오늘의 기분")
    .description("오늘 기록한 기분을 보여줍니다.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct MoodTodayView: View {
  let data: MoodWidgetData

  var body: some View {
    GeometryReader { geometry in
      // 가로로 넉넉하면(중간 크기) 가로 배치, 정사각형이면 세로 배치.
      let isWide = geometry.size.width > geometry.size.height * 1.4

      if isWide {
        HStack(spacing: 18) {
          emoji(size: 46)
          VStack(alignment: .leading, spacing: 4) {
            caption
            title(size: 20, alignment: .leading)
          }
          Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      } else {
        VStack(spacing: 8) {
          emoji(size: 40)
          title(size: 15, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
  }

  private func emoji(size: CGFloat) -> some View {
    Text(data.recorded ? data.emojis : "✍️")
      .font(.system(size: size))
      .minimumScaleFactor(0.5)
      .lineLimit(1)
  }

  private var caption: some View {
    Text("오늘의 기분")
      .font(.caption2)
      .foregroundStyle(.secondary)
  }

  private func title(size: CGFloat, alignment: TextAlignment) -> some View {
    Text(data.recorded ? data.label : "아직 기록 전")
      .font(.system(size: size, weight: .semibold))
      .foregroundStyle(data.recorded ? .primary : .secondary)
      .minimumScaleFactor(0.6)
      .lineLimit(2)
      .multilineTextAlignment(alignment)
  }
}
