import SwiftUI

/// 앱이 App Group에 써둔 위젯용 요약 데이터.
struct MoodWidgetData {
  /// 오늘 기록 여부와 내용.
  var recorded: Bool
  var emojis: String
  var label: String
  /// "yyyy-MM-dd" → 그날 기분 색(RRGGBB). 잔디 그리드에 쓴다.
  var colorsByDay: [String: String]

  static let appGroupId = "group.com.linkcat.todayMood"
  static let storageKey = "widget_payload"

  static let placeholder = MoodWidgetData(
    recorded: true,
    emojis: "😄",
    label: "행복",
    colorsByDay: samplePreviewDays()
  )

  static let empty = MoodWidgetData(
    recorded: false,
    emojis: "",
    label: "",
    colorsByDay: [:]
  )

  static func load() -> MoodWidgetData {
    guard
      let defaults = UserDefaults(suiteName: appGroupId),
      let raw = defaults.string(forKey: storageKey),
      let data = raw.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      return .empty
    }

    return MoodWidgetData(
      recorded: json["recorded"] as? Bool ?? false,
      emojis: json["emojis"] as? String ?? "",
      label: json["label"] as? String ?? "",
      colorsByDay: json["days"] as? [String: String] ?? [:]
    )
  }

  /// 위젯 갤러리 미리보기에 쓸 그럴듯한 더미 데이터.
  private static func samplePreviewDays() -> [String: String] {
    let palette = ["FFD54F", "AED581", "90A4AE", "64B5F6", "E57373", "B39DDB"]
    var days: [String: String] = [:]
    let formatter = MoodWidgetData.dayFormatter
    for offset in 0..<90 where offset % 3 != 0 {
      guard
        let date = Calendar.current.date(
          byAdding: .day, value: -offset, to: Date()
        )
      else { continue }
      days[formatter.string(from: date)] = palette[offset % palette.count]
    }
    return days
  }

  static let dayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }()
}

extension View {
  /// iOS 17부터는 위젯이 배경을 직접 선언해야 하고, 그 이전에는 시스템이 넣어준다.
  @ViewBuilder
  func widgetContainerBackground() -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(.background, for: .widget)
    } else {
      self
    }
  }
}

extension Color {
  /// "FFD54F" 형태의 문자열을 색으로 바꾼다.
  init?(hex: String) {
    var value: UInt64 = 0
    guard Scanner(string: hex).scanHexInt64(&value), hex.count == 6 else {
      return nil
    }
    self.init(
      .sRGB,
      red: Double((value >> 16) & 0xFF) / 255,
      green: Double((value >> 8) & 0xFF) / 255,
      blue: Double(value & 0xFF) / 255
    )
  }
}
