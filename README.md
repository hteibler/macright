# macright

Extra entries for the macOS Finder right-click menu.

| Entry | What it does |
|---|---|
| New Folder | Creates a folder in the selected or current folder (asks for a name) |
| New File | Creates an empty file in the selected or current folder (asks for a name) |
| Copy Path | Copies the path of the selected item(s), or of the current folder |
| Duplicate | Copies a file or folder next to the original with `_dup` appended |
| Cut / Paste | Cut items, then paste (move) them into another folder |
| Open in Terminal | Opens Terminal at the selected or current folder |

Each entry can be switched off in the settings. macright runs as a menu bar app
(icon can be hidden) and can launch at login.

## Install

1. Download `macright-<version>.dmg` from the [Releases](https://github.com/hteibler/macright/releases) page.
2. Drag **macright** to Applications and start it.
3. Enable the extension: System Settings → Extensions → Finder → **macright**
   (the settings window has a button for this).

Requires macOS 15 or later.

## How it works

* `MacrightFinder` is a sandboxed Finder Sync extension. It builds the menu and
  hands requests over through an app group; it does not touch files itself.
* `Macright` is the host app (menu bar, settings, help). It performs the file
  operations. Existing items are never overwritten.

## Build

Requires Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
xcodegen generate
xcodebuild -project Macright.xcodeproj -scheme MacrightTests -destination 'platform=macOS' test
scripts/make-dmg.sh   # signed + notarized DMG, needs a notarytool keychain profile
```

## License / warranty

© Herbert Teibler. Provided as is, without any warranty of any kind.
