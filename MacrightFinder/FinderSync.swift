import Cocoa
import FinderSync

/// Builds the Finder context menu. The sandboxed extension performs no file
/// operations itself: it posts a request to the host app, which does the work.
final class FinderSync: FIFinderSync {
    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    // MARK: - Menu

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems || menuKind == .contextualMenuForContainer else {
            return nil
        }
        let hasSelection = !(FIFinderSyncController.default().selectedItemURLs() ?? []).isEmpty
        let menu = NSMenu(title: "")

        func add(_ feature: MenuFeature, title: String? = nil, action: Selector) {
            let item = NSMenuItem(title: title ?? feature.title, action: action, keyEquivalent: "")
            item.target = self
            // Template images are tinted by Finder, so they follow light/dark mode.
            let image = NSImage(systemSymbolName: feature.symbol, accessibilityDescription: nil)
            image?.isTemplate = true
            item.image = image
            menu.addItem(item)
        }

        if MacrightShared.isEnabled(.newFolder) { add(.newFolder, action: #selector(newFolder)) }
        if MacrightShared.isEnabled(.newFile) { add(.newFile, action: #selector(newFile)) }
        if MacrightShared.isEnabled(.copyPath) { add(.copyPath, action: #selector(copyPath)) }
        if MacrightShared.isEnabled(.duplicate), hasSelection {
            add(.duplicate, action: #selector(duplicate))
        }
        if MacrightShared.isEnabled(.cutPaste) {
            if hasSelection { add(.cutPaste, title: "Cut", action: #selector(cut)) }
            if !pendingCutPaths().isEmpty { add(.cutPaste, title: "Paste", action: #selector(paste)) }
        }
        if MacrightShared.isEnabled(.openInTerminal) {
            add(.openInTerminal, action: #selector(openInTerminal))
        }
        return menu.items.isEmpty ? nil : menu
    }

    // MARK: - Actions

    @objc private func newFolder() { send(.newFolder, usesTarget: true) }
    @objc private func newFile() { send(.newFile, usesTarget: true) }
    @objc private func paste() { send(.paste, usesTarget: true) }
    @objc private func openInTerminal() { send(.openInTerminal, usesTarget: true) }
    @objc private func duplicate() { send(.duplicate, usesTarget: false) }

    @objc private func copyPath() {
        let urls = selectionOrContainer()
        guard !urls.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(urls.map(\.path).joined(separator: "\n"), forType: .string)
    }

    @objc private func cut() {
        let urls = FIFinderSyncController.default().selectedItemURLs() ?? []
        MacrightShared.cutPaths = urls.map(\.path)
    }

    // MARK: - Helpers

    private func selectionOrContainer() -> [URL] {
        let controller = FIFinderSyncController.default()
        if let selected = controller.selectedItemURLs(), !selected.isEmpty { return selected }
        return controller.targetedURL().map { [$0] } ?? []
    }

    /// Cut items that still exist.
    private func pendingCutPaths() -> [String] {
        MacrightShared.cutPaths.filter { FileManager.default.fileExists(atPath: $0) }
    }

    private func send(_ action: RequestAction, usesTarget: Bool) {
        let controller = FIFinderSyncController.default()
        let selected = (controller.selectedItemURLs() ?? []).map(\.path)
        let target: String?
        if usesTarget {
            // Single selected item decides the target folder; otherwise the current folder.
            target = (selected.count == 1 ? selected.first : controller.targetedURL()?.path)
        } else {
            target = controller.targetedURL()?.path
        }
        MacrightShared.post(ActionRequest(action: action, paths: selected,
                                          target: target, created: Date()))
        if let url = URL(string: "\(MacrightShared.urlScheme)://run") {
            NSWorkspace.shared.open(url)
        }
    }
}
