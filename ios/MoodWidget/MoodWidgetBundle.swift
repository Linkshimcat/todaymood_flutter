import SwiftUI
import WidgetKit

@main
struct MoodWidgetBundle: WidgetBundle {
  var body: some Widget {
    MoodTodayWidget()
    MoodGrassWidget()
    MoodWidgetLiveActivity()
  }
}
