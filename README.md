# Copy Pathname — a macOS Finder extension

_authored by Cursor_

Adds a **Copy Pathname** item to Finder that copies the path of the selected
files/folders to the clipboard. Paths inside your home directory are
abbreviated with `~` (e.g. `~/Documents/notes.txt`); anything else is copied
as a full path (e.g. `/Applications/Safari.app`).

- Right-click one or more items → **Copy Pathname** (multiple paths are
  separated by newlines).
- Right-click the background of a window → **Copy Pathname** copies the
  folder's path.
- Optional toolbar button: Finder → View → Customize Toolbar… → drag in
  **Copy Pathname**.

## Requirements

- macOS 13 or later
- Xcode Command Line Tools (`xcode-select --install`); full Xcode is not needed

## Build and install

```sh
make install    # builds, copies to ~/Applications, registers + enables the extension
```

If the menu item doesn't appear, check **System Settings → General → Login
Items & Extensions → Finder** (or run the app once and click
"Extension Settings…"), or restart Finder with `killall Finder`.

Other targets:

| target           | description                                      |
| ---------------- | ------------------------------------------------ |
| `make build`     | build `build/Copy Pathname.app` (universal)      |
| `make status`    | show the extension's registration status         |
| `make enable`    | enable the extension                             |
| `make disable`   | disable the extension                            |
| `make uninstall` | disable, unregister, and remove the installed app |
| `make clean`     | remove `build/`                                  |

Variables you can override: `BUNDLE_ID`, `VERSION`, `MIN_MACOS`, `ARCHS`,
`SIGN_ID`, `INSTALL_DIR` — e.g. `make install INSTALL_DIR=/Applications`.

## Signing

By default the build is ad-hoc signed (`SIGN_ID=-`), which is fine for use on
the machine that built it. To share a build with others, sign with a Developer
ID and notarize it:

```sh
make build SIGN_ID="Developer ID Application: Your Name (TEAMID)"
```

The extension must stay inside the app, and the app must live in an
Applications folder; macOS refuses to load Finder extensions from elsewhere
(e.g. straight out of `build/`).

## Layout

```
Sources/App/main.swift            host app (just shows status / opens settings)
Sources/Extension/FinderSync.swift the Finder Sync extension
Resources/*.plist                 Info.plist templates
Resources/Extension.entitlements  sandbox entitlement (required for Finder Sync)
```
