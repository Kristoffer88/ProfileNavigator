import Cocoa

class StatusBarController {
    private var statusItem: NSStatusItem

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "safari", accessibilityDescription: "Profile Navigator")
            button.image?.isTemplate = true
        }
        rebuildMenu()
    }

    func rebuildMenu() {
        let menu = NSMenu()
        let profiles = ProfileDetector.visible()
        let config = ConfigStore.shared.config

        if profiles.isEmpty {
            menu.addItem(withTitle: "No profiles detected", action: nil, keyEquivalent: "")
        } else {
            let header = menu.addItem(withTitle: "Set Default Profile", action: nil, keyEquivalent: "")
            header.isEnabled = false

            for profile in profiles {
                let title = "\(profile.name)  —  \(profile.browserApp)"
                let item = NSMenuItem(title: title, action: #selector(setDefault(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = profile.id
                item.state = profile.id == config.defaultProfileId ? .on : .off
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())

        let rulesItem = menu.addItem(withTitle: "Remembered Rules", action: nil, keyEquivalent: "")
        rulesItem.isEnabled = false

        let rules = ConfigStore.shared.config.rules ?? [:]
        if rules.isEmpty {
            let none = menu.addItem(withTitle: "  (none)", action: nil, keyEquivalent: "")
            none.isEnabled = false
        } else {
            for (host, profileId) in rules.sorted(by: { $0.key < $1.key }) {
                let title = "  \(host)  →  \(profileId)"
                let item = NSMenuItem(title: title, action: #selector(removeRule(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = host
                item.toolTip = "Click to remove this rule"
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())
        let settings = menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(withTitle: "Quit Profile Navigator", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        statusItem.menu = menu
    }

    @objc func setDefault(_ sender: NSMenuItem) {
        guard let profileId = sender.representedObject as? String else { return }
        ConfigStore.shared.setDefault(profileId: profileId)
        rebuildMenu()
    }

    @objc func removeRule(_ sender: NSMenuItem) {
        guard let host = sender.representedObject as? String else { return }
        ConfigStore.shared.removeRule(host: host)
        rebuildMenu()
    }

    @objc func openSettings(_ sender: Any?) {
        SettingsWindowController.shared.open()
    }
}
