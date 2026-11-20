import AppKit
import FinderSync

// The host app exists only to carry the Finder Sync extension. Launching it
// registers the extension with the system and tells the user how to enable it.

let app = NSApplication.shared
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)

let alert = NSAlert()
alert.messageText = "Copy Pathname"

if FIFinderSyncController.isExtensionEnabled {
    alert.informativeText = """
        The Finder extension is enabled.

        Right-click any file or folder in Finder and choose "Copy Pathname". \
        You can also add the toolbar button via Finder > View > Customize Toolbar.
        """
    alert.addButton(withTitle: "OK")
    alert.addButton(withTitle: "Extension Settings…")
} else {
    alert.informativeText = """
        The Finder extension is not enabled yet.

        Click "Extension Settings…" and turn on "Copy Pathname" under \
        Finder extensions.
        """
    alert.addButton(withTitle: "Extension Settings…")
    alert.addButton(withTitle: "Cancel")
}

let response = alert.runModal()
let settingsResponse: NSApplication.ModalResponse =
    FIFinderSyncController.isExtensionEnabled ? .alertSecondButtonReturn : .alertFirstButtonReturn

if response == settingsResponse {
    FIFinderSyncController.showExtensionManagementInterface()
}
