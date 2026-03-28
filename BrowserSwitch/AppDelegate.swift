import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBar: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBar = StatusBarController()
        setupMainMenu()

        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURL(_:replyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    // Build a minimal app menu so Cmd+, and Cmd+Q work when the app is active
    private func setupMainMenu() {
        let mainMenu = NSMenu()

        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Profile Navigator", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc func openSettings() {
        SettingsWindowController.shared.open()
    }

    @objc func handleURL(_ event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString) else { return }
        URLHandler.shared.handle(url: url)
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        URLHandler.shared.handle(url: URL(fileURLWithPath: filename))
        return true
    }
}

// Called by SettingsWindowController to toggle the app's visibility in the menu bar
extension AppDelegate {
    func becomeVisibleApp() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func becomeMenuBarApp() {
        NSApp.setActivationPolicy(.accessory)
    }
}
