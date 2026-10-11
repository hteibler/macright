import SwiftUI

struct HelpView: View {
    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "Version \(short) (\(build))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(nsImage: MenuBarIcon.image)
                    .resizable().scaledToFit().frame(width: 28, height: 28)
                VStack(alignment: .leading) {
                    Text("macright").font(.title2.bold())
                    Text(version).font(.caption).foregroundStyle(.secondary)
                }
            }
            Text("Adds these entries to the Finder right-click menu:")
            VStack(alignment: .leading, spacing: 8) {
                helpRow(.newFolder, "Create a folder in the selected or current folder.")
                helpRow(.newFile, "Create an empty file in the selected or current folder.")
                helpRow(.copyPath, "Copy the path of the selected item(s) or current folder.")
                helpRow(.duplicate, "Copy an item next to the original, with “_dup” appended.")
                helpRow(.cutPaste, "Cut items, then paste (move) them into another folder.")
                helpRow(.openInTerminal, "Open Terminal at the selected or current folder.")
            }
            Text("Choose which entries appear in Settings. The Finder extension must be enabled in System Settings → Extensions → Finder.")
                .font(.callout).foregroundStyle(.secondary)
            Divider()
            Text("© Herbert Teibler. Provided as is, without any warranty.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func helpRow(_ feature: MenuFeature, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: feature.symbol).frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(feature.title).bold()
                Text(text).font(.callout).foregroundStyle(.secondary)
            }
        }
    }
}
