import Cocoa
import FinderSync

private enum MenuTag: Int {
    case items = 1
    case container = 2
    case toolbar = 3
}

// NSHomeDirectory() returns the sandbox container inside an extension, so
// look up the user's real home directory instead.
private let realHomeDirectory: String? = {
    guard let pw = getpwuid(getuid()), let dir = pw.pointee.pw_dir else { return nil }
    let home = String(cString: dir)
    return home.count > 1 && home.hasSuffix("/") ? String(home.dropLast()) : home
}()

private func abbreviateHome(_ path: String) -> String {
    guard let home = realHomeDirectory, home != "/" else { return path }
    if path == home {
        return "~"
    }
    if path.hasPrefix(home + "/") {
        return "~" + path.dropFirst(home.count)
    }
    return path
}

@objc(FinderSync)
class FinderSync: FIFinderSync {

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    // MARK: - Toolbar

    override var toolbarItemName: String {
        return "Copy Pathname"
    }

    override var toolbarItemToolTip: String {
        return "Copy the pathname of the selected items to the clipboard"
    }

    override var toolbarItemImage: NSImage {
        return NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Copy Pathname")
            ?? NSImage(named: NSImage.multipleDocumentsName)!
    }

    // MARK: - Menus

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        let tag: MenuTag
        switch menuKind {
        case .contextualMenuForItems:
            tag = .items
        case .contextualMenuForContainer:
            tag = .container
        case .toolbarItemMenu:
            tag = .toolbar
        default:
            return nil
        }

        let menu = NSMenu(title: "")
        let item = menu.addItem(withTitle: "Copy Pathname", action: #selector(copyPathname(_:)), keyEquivalent: "")
        item.tag = tag.rawValue
        return menu
    }

    @IBAction func copyPathname(_ sender: AnyObject?) {
        let controller = FIFinderSyncController.default()
        let tag = (sender as? NSMenuItem).flatMap { MenuTag(rawValue: $0.tag) } ?? .items

        var urls: [URL] = []
        switch tag {
        case .container:
            if let target = controller.targetedURL() {
                urls = [target]
            }
        case .items, .toolbar:
            urls = controller.selectedItemURLs() ?? []
            if urls.isEmpty, let target = controller.targetedURL() {
                urls = [target]
            }
        }

        guard !urls.isEmpty else { return }

        let text = urls.map { abbreviateHome($0.path) }.joined(separator: "\n")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
