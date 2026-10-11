import Foundation

enum FileOpsError: LocalizedError {
    case invalidName
    case alreadyExists(String)
    case notADirectory(String)
    case moveIntoItself(String)

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "The name is empty or contains the characters “/” or “:”."
        case .alreadyExists(let name):
            return "“\(name)” already exists."
        case .notADirectory(let path):
            return "“\(path)” is not a folder."
        case .moveIntoItself(let name):
            return "“\(name)” cannot be moved into itself."
        }
    }
}

/// File-system operations used by the host app. Never overwrites existing items.
enum FileOps {
    static func validate(name: String) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != ".", trimmed != "..",
              !trimmed.contains("/"), !trimmed.contains(":"), !trimmed.contains("\0"),
              trimmed.utf8.count <= 255 else { throw FileOpsError.invalidName }
        return trimmed
    }

    @discardableResult
    static func createFolder(named name: String, in folder: URL,
                             fm: FileManager = .default) throws -> URL {
        let url = try destination(named: name, in: folder, fm: fm)
        try fm.createDirectory(at: url, withIntermediateDirectories: false)
        return url
    }

    @discardableResult
    static func createFile(named name: String, in folder: URL,
                           fm: FileManager = .default) throws -> URL {
        let url = try destination(named: name, in: folder, fm: fm)
        guard fm.createFile(atPath: url.path, contents: Data()) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return url
    }

    /// `report.txt` -> `report_dup.txt`, then `report_dup_2.txt`, ...
    @discardableResult
    static func duplicate(_ url: URL, fm: FileManager = .default) throws -> URL {
        let target = uniqueURL(in: url.deletingLastPathComponent(),
                               stem: url.deletingPathExtension().lastPathComponent + "_dup",
                               ext: url.pathExtension, fm: fm)
        try fm.copyItem(at: url, to: target)
        return target
    }

    /// Moves `url` into `folder`. On a name clash a `_2`, `_3`, ... suffix is added.
    @discardableResult
    static func move(_ url: URL, into folder: URL, fm: FileManager = .default) throws -> URL {
        let source = url.standardizedFileURL.path
        let dest = folder.standardizedFileURL.path
        if dest == source || dest.hasPrefix(source + "/") {
            throw FileOpsError.moveIntoItself(url.lastPathComponent)
        }
        if url.deletingLastPathComponent().standardizedFileURL.path == dest { return url }
        let target = uniqueURL(in: folder,
                               stem: url.deletingPathExtension().lastPathComponent,
                               ext: url.pathExtension, fm: fm)
        try fm.moveItem(at: url, to: target)
        return target
    }

    /// Folder an action applies to: the item itself if it is a folder, else its parent.
    static func containingFolder(of url: URL, fm: FileManager = .default) -> URL {
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue,
           !isPackage(url) {
            return url
        }
        return url.deletingLastPathComponent()
    }

    // MARK: - Helpers

    private static func isPackage(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isPackageKey]).isPackage) ?? false
    }

    private static func destination(named name: String, in folder: URL,
                                    fm: FileManager) throws -> URL {
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: folder.path, isDirectory: &isDir), isDir.boolValue else {
            throw FileOpsError.notADirectory(folder.path)
        }
        let valid = try validate(name: name)
        let url = folder.appendingPathComponent(valid)
        guard !fm.fileExists(atPath: url.path) else { throw FileOpsError.alreadyExists(valid) }
        return url
    }

    private static func uniqueURL(in folder: URL, stem: String, ext: String,
                                  fm: FileManager) -> URL {
        func candidate(_ index: Int?) -> URL {
            var name = stem
            if let index { name += "_\(index)" }
            if !ext.isEmpty { name += "." + ext }
            return folder.appendingPathComponent(name)
        }
        let plain = candidate(nil)
        if !fm.fileExists(atPath: plain.path) { return plain }
        var index = 2
        while fm.fileExists(atPath: candidate(index).path) { index += 1 }
        return candidate(index)
    }
}
