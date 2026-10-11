import Foundation

/// Menu entries the user can enable or disable in the settings.
enum MenuFeature: String, CaseIterable {
    case newFolder, newFile, copyPath, duplicate, cutPaste, openInTerminal

    var title: String {
        switch self {
        case .newFolder: return "New Folder"
        case .newFile: return "New File"
        case .copyPath: return "Copy Path"
        case .duplicate: return "Duplicate"
        case .cutPaste: return "Cut / Paste"
        case .openInTerminal: return "Open in Terminal"
        }
    }

    var symbol: String {
        switch self {
        case .newFolder: return "folder.badge.plus"
        case .newFile: return "doc.badge.plus"
        case .copyPath: return "link"
        case .duplicate: return "plus.square.on.square"
        case .cutPaste: return "scissors"
        case .openInTerminal: return "terminal"
        }
    }

    var defaultsKey: String { "enabled.\(rawValue)" }
}

/// Actions the Finder extension asks the host app to perform.
enum RequestAction: String, Codable {
    case newFolder, newFile, duplicate, paste, openInTerminal
}

struct ActionRequest: Codable {
    var action: RequestAction
    var paths: [String]
    var target: String?
    var created: Date
}

/// Settings and hand-over state shared by the host app and the sandboxed extension
/// through the team-prefixed app group.
enum MacrightShared {
    static let appGroup = "V8583J8736.at.teibler.macright"
    static let urlScheme = "macright"
    static let showMenuBarIconKey = "showMenuBarIcon"
    static let firstRunKey = "didFirstRun"
    private static let requestKey = "request"
    private static let cutPathsKey = "cutPaths"
    /// Requests older than this are ignored by the host.
    static let requestTTL: TimeInterval = 30

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static func isEnabled(_ feature: MenuFeature) -> Bool {
        defaults.object(forKey: feature.defaultsKey) as? Bool ?? true
    }

    static var cutPaths: [String] {
        get { defaults.stringArray(forKey: cutPathsKey) ?? [] }
        set { defaults.set(newValue, forKey: cutPathsKey) }
    }

    static func post(_ request: ActionRequest) {
        if let data = try? JSONEncoder().encode(request) {
            defaults.set(data, forKey: requestKey)
        }
    }

    /// Returns and clears the pending request; nil if none or if it is stale.
    static func takeRequest() -> ActionRequest? {
        defer { defaults.removeObject(forKey: requestKey) }
        guard let data = defaults.data(forKey: requestKey),
              let request = try? JSONDecoder().decode(ActionRequest.self, from: data),
              Date().timeIntervalSince(request.created) <= requestTTL else { return nil }
        return request
    }
}
