import AppIntents
import Foundation

@available(iOS 16.0, *)
enum TorchAction: String, AppEnum {
  case on
  case off
  case toggle

  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Flashlight Action"

  static var caseDisplayRepresentations: [TorchAction: DisplayRepresentation] = [
    .on: "Turn on",
    .off: "Turn off",
    .toggle: "Toggle",
  ]
}

@available(iOS 16.0, *)
struct ControlTorchIntent: AppIntent {
  static var title: LocalizedStringResource = "Control Flashlight"
  static var description = IntentDescription(
    "Turn the flashlight on, off, or toggle it without opening the app."
  )
  static var openAppWhenRun: Bool = false

  @Parameter(title: "Action")
  var action: TorchAction

  init() {}

  init(action: TorchAction) {
    self.action = action
  }

  func perform() async throws -> some IntentResult & ProvidesDialog {
    guard TorchController.shared.isAvailable else {
      throw TorchController.Failure.unavailable
    }

    let result: Result<Bool, TorchController.Failure>
    switch action {
    case .on:
      result = TorchController.shared.setEnabled(true)
    case .off:
      result = TorchController.shared.setEnabled(false)
    case .toggle:
      result = TorchController.shared.toggle()
    }

    switch result {
    case .success(let isOn):
      return .result(dialog: isOn ? "Flashlight on." : "Flashlight off.")
    case .failure(let failure):
      throw failure
    }
  }
}

@available(iOS 16.0, *)
struct FlashlightShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: ControlTorchIntent(action: .on),
      phrases: [
        "Turn on the flashlight in \(.applicationName)",
        "Turn on \(.applicationName)",
      ],
      shortTitle: "Flashlight On",
      systemImageName: "flashlight.on.fill"
    )

    AppShortcut(
      intent: ControlTorchIntent(action: .off),
      phrases: [
        "Turn off the flashlight in \(.applicationName)",
        "Turn off \(.applicationName)",
      ],
      shortTitle: "Flashlight Off",
      systemImageName: "flashlight.off.fill"
    )

    AppShortcut(
      intent: ControlTorchIntent(action: .toggle),
      phrases: [
        "Toggle the flashlight in \(.applicationName)"
      ],
      shortTitle: "Toggle Flashlight",
      systemImageName: "flashlight.off.fill"
    )
  }
}
