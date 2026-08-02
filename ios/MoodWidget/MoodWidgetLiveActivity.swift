import ActivityKit
import SwiftUI
import WidgetKit

/// 잠금화면과 Dynamic Island에 오늘의 기분 기록 상태를 보여준다.
struct MoodWidgetLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: MoodActivityAttributes.self) { context in
      LockScreenView(state: context.state, title: context.attributes.title)
        .activityBackgroundTint(Color.black.opacity(0.55))
        .activitySystemActionForegroundColor(Color.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Text(context.state.recorded ? context.state.emojis : "✍️")
            .font(.title2)
            .padding(.leading, 4)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text(context.state.recorded ? "기록 완료" : "미기록")
            .font(.caption)
            .foregroundStyle(context.state.recorded ? .green : .orange)
            .padding(.trailing, 4)
        }
        DynamicIslandExpandedRegion(.bottom) {
          Text(context.state.recorded ? context.state.label : "오늘의 기분을 기록해보세요")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      } compactLeading: {
        Text(firstEmoji(context.state))
      } compactTrailing: {
        Text(context.state.recorded ? "✓" : "···")
          .font(.caption2)
          .foregroundStyle(context.state.recorded ? .green : .orange)
      } minimal: {
        Text(firstEmoji(context.state))
      }
    }
  }

  /// Dynamic Island의 좁은 영역에는 이모지 하나만 넣는다.
  private func firstEmoji(_ state: MoodActivityAttributes.ContentState) -> String {
    guard state.recorded, let first = state.emojis.first else { return "🙂" }
    return String(first)
  }
}

private struct LockScreenView: View {
  let state: MoodActivityAttributes.ContentState
  let title: String

  var body: some View {
    HStack(spacing: 14) {
      Text(state.recorded ? state.emojis : "🙂")
        .font(.system(size: 34))

      VStack(alignment: .leading, spacing: 3) {
        Text(title)
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(state.recorded ? state.label : "아직 기록하지 않았어요")
          .font(.headline)
          .foregroundStyle(.primary)
      }

      Spacer()

      if !state.recorded {
        Text("기록하기")
          .font(.caption2.weight(.semibold))
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(Capsule().fill(.orange.opacity(0.25)))
      }
    }
    .padding(.horizontal, 18)
    .padding(.vertical, 14)
  }
}
