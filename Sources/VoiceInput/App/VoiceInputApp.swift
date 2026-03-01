import AppKit
import SwiftUI

@main
struct VoiceInputApp: App {
    @StateObject private var appController: AppController

    init() {
        let controller = AppController()
        _appController = StateObject(wrappedValue: controller)
        NSApplication.shared.setActivationPolicy(.accessory)
        controller.start()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(appController: appController)
        } label: {
            Label("VoiceInput", systemImage: statusIcon)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(appController: appController)
        }
    }

    private var statusIcon: String {
        switch appController.state {
        case .idle:
            return "mic"
        case .listening, .transcribing:
            return "mic.fill"
        case .processing:
            return "waveform"
        case .inserting:
            return "text.insert"
        case .error:
            return "exclamationmark.triangle"
        }
    }
}
