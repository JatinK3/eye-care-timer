import Flutter
import UIKit

final class ImmersiveFlutterViewController: FlutterViewController {
  private var immersiveEnabled = false

  override var prefersStatusBarHidden: Bool {
    immersiveEnabled
  }

  override var prefersHomeIndicatorAutoHidden: Bool {
    immersiveEnabled
  }

  override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
    immersiveEnabled ? .all : []
  }

  func setImmersiveEnabled(_ enabled: Bool) {
    guard immersiveEnabled != enabled else { return }
    immersiveEnabled = enabled
    setNeedsStatusBarAppearanceUpdate()
    setNeedsUpdateOfHomeIndicatorAutoHidden()
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var systemUiChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? ImmersiveFlutterViewController {
      let channel = FlutterMethodChannel(
        name: "blinkkind/system_ui",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak controller] call, result in
        guard call.method == "setImmersive" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard let enabled = call.arguments as? Bool else {
          result(
            FlutterError(
              code: "invalid_arguments",
              message: "setImmersive requires a Boolean value",
              details: nil
            )
          )
          return
        }
        controller?.setImmersiveEnabled(enabled)
        result(nil)
      }
      systemUiChannel = channel
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
