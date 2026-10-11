import XCTest

final class FileOpsTests: XCTestCase {
    private var dir: URL!
    private let fm = FileManager.default

    override func setUpWithError() throws {
        dir = fm.temporaryDirectory.appendingPathComponent("macright-tests-\(UUID().uuidString)")
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? fm.removeItem(at: dir)
    }

    func testValidateRejectsBadNames() {
        for bad in ["", "   ", ".", "..", "a/b", "a:b"] {
            XCTAssertThrowsError(try FileOps.validate(name: bad), bad)
        }
        XCTAssertEqual(try FileOps.validate(name: "  ok.txt "), "ok.txt")
    }

    func testCreateFolderAndFileRefuseToOverwrite() throws {
        let folder = try FileOps.createFolder(named: "docs", in: dir)
        XCTAssertTrue(fm.fileExists(atPath: folder.path))
        XCTAssertThrowsError(try FileOps.createFolder(named: "docs", in: dir))
        let file = try FileOps.createFile(named: "a.txt", in: dir)
        XCTAssertTrue(fm.fileExists(atPath: file.path))
        XCTAssertThrowsError(try FileOps.createFile(named: "a.txt", in: dir))
    }

    func testCreateInMissingFolderFails() {
        XCTAssertThrowsError(try FileOps.createFolder(named: "x", in: dir.appendingPathComponent("nope")))
    }

    func testDuplicateFileAddsDupSuffixAndCounts() throws {
        let file = try FileOps.createFile(named: "report.txt", in: dir)
        XCTAssertEqual(try FileOps.duplicate(file).lastPathComponent, "report_dup.txt")
        XCTAssertEqual(try FileOps.duplicate(file).lastPathComponent, "report_dup_2.txt")
    }

    func testDuplicateFolderCopiesContents() throws {
        let folder = try FileOps.createFolder(named: "Photos", in: dir)
        try FileOps.createFile(named: "a.jpg", in: folder)
        let copy = try FileOps.duplicate(folder)
        XCTAssertEqual(copy.lastPathComponent, "Photos_dup")
        XCTAssertTrue(fm.fileExists(atPath: copy.appendingPathComponent("a.jpg").path))
    }

    func testMoveHandlesCollisionAndKeepsExisting() throws {
        let dest = try FileOps.createFolder(named: "dest", in: dir)
        let existing = try FileOps.createFile(named: "a.txt", in: dest)
        try "keep".write(to: existing, atomically: true, encoding: .utf8)
        let source = try FileOps.createFile(named: "a.txt", in: dir)
        let moved = try FileOps.move(source, into: dest)
        XCTAssertEqual(moved.lastPathComponent, "a_2.txt")
        XCTAssertFalse(fm.fileExists(atPath: source.path))
        XCTAssertEqual(try String(contentsOf: existing, encoding: .utf8), "keep")
    }

    func testMoveIntoItselfIsRejected() throws {
        let folder = try FileOps.createFolder(named: "a", in: dir)
        let child = try FileOps.createFolder(named: "b", in: folder)
        XCTAssertThrowsError(try FileOps.move(folder, into: folder))
        XCTAssertThrowsError(try FileOps.move(folder, into: child))
    }

    func testMoveIntoSameParentIsNoOp() throws {
        let file = try FileOps.createFile(named: "a.txt", in: dir)
        XCTAssertEqual(try FileOps.move(file, into: dir), file)
        XCTAssertTrue(fm.fileExists(atPath: file.path))
    }

    func testContainingFolder() throws {
        let folder = try FileOps.createFolder(named: "f", in: dir)
        let file = try FileOps.createFile(named: "a.txt", in: dir)
        XCTAssertEqual(FileOps.containingFolder(of: folder).path, folder.path)
        XCTAssertEqual(FileOps.containingFolder(of: file).standardizedFileURL.path,
                       dir.standardizedFileURL.path)
    }
}
