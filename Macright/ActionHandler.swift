import Cocoa

/// Executes requests posted by the Finder extension.
enum ActionHandler {
    static func perform(_ request: ActionRequest) {
        do {
            switch request.action {
            case .newFolder:
                let folder = try targetFolder(of: request)
                guard let name = promptForName(title: "New Folder", defaultName: "untitled folder",
                                               folder: folder) else { return }
                try FileOps.createFolder(named: name, in: folder)
            case .newFile:
                let folder = try targetFolder(of: request)
                guard let name = promptForName(title: "New File", defaultName: "untitled.txt",
                                               folder: folder) else { return }
                try FileOps.createFile(named: name, in: folder)
            case .duplicate:
                for path in request.paths {
                    try FileOps.duplicate(URL(fileURLWithPath: path))
                }
            case .paste:
                let folder = try targetFolder(of: request)
                let sources = MacrightShared.cutPaths
                for path in sources where FileManager.default.fileExists(atPath: path) {
                    try FileOps.move(URL(fileURLWithPath: path), into: folder)
                }
                MacrightShared.cutPaths = []
            case .openInTerminal:
                let folder = try targetFolder(of: request)
                let terminal = URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app")
                NSWorkspace.shared.open([folder], withApplicationAt: terminal,
                                        configuration: NSWorkspace.OpenConfiguration())
            }
        } catch {
            present(error)
        }
    }

    private static func targetFolder(of request: ActionRequest) throws -> URL {
        guard let target = request.target else { throw FileOpsError.notADirectory("") }
        return FileOps.containingFolder(of: URL(fileURLWithPath: target))
    }

    private static func promptForName(title: String, defaultName: String, folder: URL) -> String? {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = "Create in “\(folder.path)”"
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 24))
        field.stringValue = defaultName
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        return field.stringValue
    }

    private static func present(_ error: Error) {
        let alert = NSAlert(error: error)
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
