import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    LiveActivityBridge.register(
      with: engineBridge.pluginRegistry.registrar(forPlugin: "LiveActivityBridge")!
    )
    WidgetBridge.register(
      with: engineBridge.pluginRegistry.registrar(forPlugin: "WidgetBridge")!
    )
    GlassPlatformView.register(
      with: engineBridge.pluginRegistry.registrar(forPlugin: "GlassPlatformView")!
    )
  }
}
