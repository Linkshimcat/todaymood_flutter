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
