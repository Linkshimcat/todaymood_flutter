import Flutter
import UIKit

/// Flutter 위젯 뒤에 iOS 26의 진짜 Liquid Glass 머티리얼을 깔아주는 플랫폼 뷰.
/// Flutter는 자체 렌더러로 그리기 때문에 이 재질은 네이티브 뷰로만 얻을 수 있다.
enum GlassPlatformView {
  static let viewType = "today_mood/glass"

  static func register(with registrar: FlutterPluginRegistrar) {
    registrar.register(GlassViewFactory(), withId: viewType)
  }
}

private final class GlassViewFactory: NSObject, FlutterPlatformViewFactory {
  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    GlassView(frame: frame, args: args)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

private final class GlassView: NSObject, FlutterPlatformView {
  private let container: GlassContainer

  init(frame: CGRect, args: Any?) {
    let params = args as? [String: Any] ?? [:]
    container = GlassContainer(
      frame: frame,
      isCapsule: params["capsule"] as? Bool ?? true,
      radius: params["radius"] as? CGFloat ?? 26,
      interactive: params["interactive"] as? Bool ?? true
    )
    super.init()
  }

  func view() -> UIView { container }
}

/// iOS 26의 Liquid Glass 스타일 UISwitch를 올려주는 플랫폼 뷰.
///
/// UISwitch는 iOS 26 SDK로 컴파일하면 시스템이 자동으로 새 유리 모양과
/// 상호작용(스위치 손잡이의 형태 변화)을 입혀 준다. 구형 OS에서는 기존
/// 시스템 스위치로 그려진다.
enum GlassSwitchPlatformView {
  static let viewType = "today_mood/glass_switch"

  static func register(with registrar: FlutterPluginRegistrar) {
    registrar.register(
      GlassSwitchViewFactory(messenger: registrar.messenger()),
      withId: viewType
    )
  }
}

private final class GlassSwitchViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    GlassSwitchView(frame: frame, messenger: messenger, args: args)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

private final class GlassSwitchView: NSObject, FlutterPlatformView {
  private let control: UISwitch
  private let channel: FlutterMethodChannel

  init(frame: CGRect, messenger: FlutterBinaryMessenger, args: Any?) {
    let params = args as? [String: Any] ?? [:]
    control = UISwitch()
    control.isOn = params["value"] as? Bool ?? false
    channel = FlutterMethodChannel(
      name: params["channelName"] as? String ?? "today_mood/glass_switch",
      binaryMessenger: messenger
    )
    super.init()

    // 사용자가 토글하면 Dart 상태를 바꾸고, 반영된 값은 setValue로 내려온다.
    control.addTarget(self, action: #selector(controlChanged), for: .valueChanged)
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "setValue":
        let value = (call.arguments as? [String: Any])?["value"] as? Bool ?? false
        self?.control.setOn(value, animated: true)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  @objc private func controlChanged() {
    channel.invokeMethod("onChanged", arguments: ["value": control.isOn])
  }

  func view() -> UIView { control }
}

private final class GlassContainer: UIView {
  private let effectView: UIVisualEffectView
  private let isCapsule: Bool
  private let radius: CGFloat

  init(frame: CGRect, isCapsule: Bool, radius: CGFloat, interactive: Bool) {
    self.isCapsule = isCapsule
    self.radius = radius

    if #available(iOS 26.0, *) {
      let glass = UIGlassEffect(style: .regular)
      // interactive를 켜면 눌림에 반응해 유리가 일렁인다.
      glass.isInteractive = interactive
      effectView = UIVisualEffectView(effect: glass)
    } else {
      // iOS 26 미만에서는 시스템 블러로 대체한다.
      effectView = UIVisualEffectView(
        effect: UIBlurEffect(style: .systemThinMaterial)
      )
    }

    super.init(frame: frame)

    backgroundColor = .clear
    isUserInteractionEnabled = false
    addSubview(effectView)
    applyShape()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("not supported") }

  override func layoutSubviews() {
    super.layoutSubviews()
    effectView.frame = bounds
    applyShape()
  }

  private func applyShape() {
    if #available(iOS 26.0, *) {
      effectView.cornerConfiguration = isCapsule
        ? .capsule()
        : .uniformCorners(radius: .fixed(radius))
    } else {
      effectView.layer.cornerRadius = isCapsule
        ? min(bounds.height, bounds.width) / 2
        : radius
      effectView.layer.cornerCurve = .continuous
      effectView.clipsToBounds = true
    }
  }
}
