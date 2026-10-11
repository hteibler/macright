import Cocoa
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var handledURL = false

    func applicationWillFinishLaunching(_ notification: Notification) {
        // SwiftUI's lifecycle does not forward URLs to the delegate, so listen directly.
        NSAppleEventManager.shared().setEventHandler(
            self, andSelector: #selector(handleURLEvent(_:withReply:)),
            forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
    }

    @objc private func handleURLEvent(_ event: NSAppleEventDescriptor,
                                      withReply reply: NSAppleEventDescriptor) {
        guard let string = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              URL(string: string)?.scheme == MacrightShared.urlScheme else { return }
        handledURL = true
        // The URL carries no data; the request itself is read from the app group.
        guard let request = MacrightShared.takeRequest() else { return }
        ActionHandler.perform(request)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let defaults = MacrightShared.defaults
        let firstRun = !defaults.bool(forKey: MacrightShared.firstRunKey)
        defaults.set(true, forKey: MacrightShared.firstRunKey)

        // Show the settings on first start, or when started by hand while the
        // menu bar icon is hidden. Not for login starts or Finder-triggered starts.
        let launchedAtLogin = NSAppleEventManager.shared().currentAppleEvent?
            .paramDescriptor(forKeyword: AEKeyword(keyAEPropData))?.enumCodeValue
            == AEKeyword(keyAELaunchedAsLogInItem)
        let iconHidden = defaults.object(forKey: MacrightShared.showMenuBarIconKey) as? Bool == false
        guard (firstRun || iconHidden), !launchedAtLogin else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, !self.handledURL else { return }
            WindowManager.shared.show(.settings)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        WindowManager.shared.show(.settings)
        return true
    }
}
