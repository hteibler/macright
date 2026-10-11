import SwiftUI

/// Owns the settings and help windows (the app has no SwiftUI window scenes).
final class WindowManager {
    enum Kind { case settings, help }
    static let shared = WindowManager()
    private var windows: [Kind: NSWindow] = [:]

    func show(_ kind: Kind) {
        if windows[kind] == nil {
            let window = NSWindow(contentRect: .zero,
                                  styleMask: [.titled, .closable, .miniaturizable],
                                  backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            switch kind {
            case .settings:
                window.title = "macright Settings"
                window.contentViewController = NSHostingController(rootView: SettingsView())
            case .help:
                window.title = "macright Help"
                window.contentViewController = NSHostingController(rootView: HelpView())
            }
            window.center()
            windows[kind] = window
        }
        NSApp.activate(ignoringOtherApps: true)
        windows[kind]?.makeKeyAndOrderFront(nil)
    }
}
