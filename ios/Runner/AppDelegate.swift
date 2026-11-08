import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let deviceControlsChannelName = "com.claudysoft.flashlightpro/device_controls"
  private let torchEventsChannelName = "com.claudysoft.flashlightpro/torch_state"
  private var deviceControlsChannel: FlutterMethodChannel?
  private var originalBrightness: CGFloat?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 16.0, *) {
      FlashlightShortcuts.updateAppShortcutParameters()
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()
    let channel = FlutterMethodChannel(
      name: deviceControlsChannelName,
      binaryMessenger: messenger
    )
    deviceControlsChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleDeviceControls(call, result: result)
    }

    let events = FlutterEventChannel(
      name: torchEventsChannelName,
      binaryMessenger: messenger
    )
    events.setStreamHandler(TorchEventStreamHandler())
  }

  private func handleDeviceControls(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isTorchAvailable":
      result(TorchController.shared.isAvailable)

    case "getTorchState":
      result(TorchController.shared.isOn)

    case "setTorchEnabled":
      let enabled = (call.arguments as? [String: Any])?["enabled"] as? Bool ?? false
      result(enableTorch(enabled))

    case "isTorchLevelSupported":
      result(TorchController.shared.levelSupported)

    // iOS has no supported way to keep the torch on after the app is
    // suspended. Report that honestly so the setting stays disabled.
    case "isBackgroundModeSupported":
      result(false)

    case "startBackgroundMode":
      result(["started": false, "notificationsEnabled": false, "error": "unsupported"])

    case "stopBackgroundMode":
      result(nil)

    case "isBackgroundModeActive":
      result(false)

    case "hasNotificationPermission":
      result(true)

    case "requestNotificationPermission":
      result(false)

    case "setTorchLevel":
      guard let arguments = call.arguments as? [String: Any],
            let level = arguments["level"] as? Double else {
        result(false)
        return
      }
      let controller = TorchController.shared
      result(controller.levelSupported && controller.setLevel(Float(level)))

    case "setScreenBrightness":
      guard let arguments = call.arguments as? [String: Any],
            let brightness = arguments["brightness"] as? Double else {
        result(nil)
        return
      }
      if originalBrightness == nil {
        originalBrightness = UIScreen.main.brightness
      }
      UIScreen.main.brightness = CGFloat(min(max(brightness, 0.01), 1.0))
      result(nil)

    case "restoreScreenBrightness":
      if let original = originalBrightness {
        UIScreen.main.brightness = original
        originalBrightness = nil
      }
      result(nil)

    case "setKeepScreenOn":
      let enabled = (call.arguments as? [String: Any])?["enabled"] as? Bool ?? false
      UIApplication.shared.isIdleTimerDisabled = enabled
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func enableTorch(_ enabled: Bool) -> [String: Any] {
    let controller = TorchController.shared
    let outcome = controller.setEnabled(enabled)

    var payload: [String: Any] = [
      "success": outcome.isSuccess,
      "isOn": controller.isOn,
      "available": controller.isAvailable,
    ]
    if case .failure(let failure) = outcome {
      payload["error"] = failure.wireName
    }
    return payload
  }
}

final class TorchEventStreamHandler: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?
  private var observer: NSObjectProtocol?

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    sink = events
    events(TorchController.shared.isOn)

    observer = NotificationCenter.default.addObserver(
      forName: TorchController.stateDidChange,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.sink?(TorchController.shared.isOn)
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    if let observer {
      NotificationCenter.default.removeObserver(observer)
    }
    observer = nil
    sink = nil
    return nil
  }
}

private extension Result where Success == Bool, Failure == TorchController.Failure {
  var isSuccess: Bool {
    if case .success = self { return true }
    return false
  }
}

private extension TorchController.Failure {
  var wireName: String {
    switch self {
    case .unavailable:
      return "unavailable"
    case .failed:
      return "failed"
    }
  }
}
