import SwiftUI

@main
struct MacrightApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @AppStorage(MacrightShared.showMenuBarIconKey, store: MacrightShared.defaults)
    private var showMenuBarIcon = true

    var body: some Scene {
        MenuBarExtra(isInserted: $showMenuBarIcon) {
            Button("Settings…") { WindowManager.shared.show(.settings) }
            Button("Help") { WindowManager.shared.show(.help) }
            Divider()
            Button("Quit macright") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        } label: {
            Image(nsImage: MenuBarIcon.image)
        }
    }
}
