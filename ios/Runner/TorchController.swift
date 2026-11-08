import AVFoundation
import Foundation

/// Single owner of the iPhone torch for the Flutter channel and App Intents.
final class TorchController {
  static let shared = TorchController()
  static let stateDidChange = Notification.Name(
    "com.claudysoft.flashlightpro.torchStateDidChange"
  )

  enum Failure: LocalizedError {
    case unavailable
    case failed

    var errorDescription: String? {
      switch self {
      case .unavailable:
        return "This device does not have a usable flashlight."
      case .failed:
        return "Could not change the flashlight. Please try again."
      }
    }
  }

  private let lock = NSLock()
  private let defaults = UserDefaults.standard

  private init() {}

  var isAvailable: Bool {
    lock.lock()
    defer { lock.unlock() }
    return torchDevice() != nil
  }

  var isOn: Bool {
    lock.lock()
    defer { lock.unlock() }
    guard let device = torchDevice() else { return false }
    return device.isTorchActive || device.torchMode == .on
  }

  var levelSupported: Bool {
    isAvailable
  }

  var storedLevel: Float {
    lock.lock()
    defer { lock.unlock() }
    return readLevel()
  }

  @discardableResult
  func setEnabled(_ enabled: Bool, level: Float? = nil) -> Result<Bool, Failure> {
    lock.lock()
    defer { lock.unlock() }
    return applyLocked(enabled, level: level)
  }

  @discardableResult
  func setLevel(_ level: Float) -> Bool {
    lock.lock()
    defer { lock.unlock() }

    let normalized = normalize(level)
    defaults.set(normalized, forKey: Keys.level)

    guard let device = torchDevice(), device.isTorchActive else { return true }

    do {
      try device.lockForConfiguration()
      defer { device.unlockForConfiguration() }
      try device.setTorchModeOn(level: normalized)
      postStateChange()
      return true
    } catch {
      return false
    }
  }

  func toggle() -> Result<Bool, Failure> {
    lock.lock()
    defer { lock.unlock() }

    let enabled: Bool
    if let device = torchDevice() {
      enabled = !(device.isTorchActive || device.torchMode == .on)
    } else {
      enabled = true
    }
    return applyLocked(enabled, level: nil)
  }

  private func applyLocked(
    _ enabled: Bool,
    level: Float?
  ) -> Result<Bool, Failure> {
    guard let device = torchDevice() else { return .failure(.unavailable) }
    let normalized = normalize(level ?? readLevel())

    do {
      try device.lockForConfiguration()
      defer { device.unlockForConfiguration() }

      if enabled {
        try device.setTorchModeOn(level: normalized)
      } else {
        device.torchMode = .off
      }

      defaults.set(normalized, forKey: Keys.level)
      postStateChange()
      return .success(enabled)
    } catch {
      return .failure(.failed)
    }
  }

  private func torchDevice() -> AVCaptureDevice? {
    guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
      return nil
    }
    return device
  }

  private func readLevel() -> Float {
    guard defaults.object(forKey: Keys.level) != nil else { return 1 }
    return normalize(defaults.float(forKey: Keys.level))
  }

  private func normalize(_ level: Float) -> Float {
    min(max(level, 0.01), 1)
  }

  /// Event sinks must be updated on the main queue.
  private func postStateChange() {
    DispatchQueue.main.async {
      NotificationCenter.default.post(name: Self.stateDidChange, object: self)
    }
  }

  private enum Keys {
    static let level = "native.torch_level"
  }
}
