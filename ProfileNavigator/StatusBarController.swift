import Cocoa

class StatusBarController {
    private var statusItem: NSStatusItem

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        refreshAppearance()
        rebuildMenu()
    }

    func refreshAppearance() {
        guard let button = statusItem.button else { return }

        if ConfigStore.shared.config.useProfileSymbolInMenuBar == true {
            // Use a native template SF Symbol so macOS tints it like other status items.
            statusItem.length = NSStatusItem.squareLength
            button.title = ""
            let image = NSImage(systemSymbolName: "person.crop.circle.badge.checkmark", accessibilityDescription: "Profile Navigator")
                ?? NSImage(systemSymbolName: "person.crop.circle", accessibilityDescription: "Profile Navigator")
            image?.isTemplate = true
            button.image = image
            button.imagePosition = .imageOnly
        } else {
            statusItem.length = NSStatusItem.squareLength
            let image = NSImage(systemSymbolName: "safari", accessibilityDescription: "Profile Navigator")
            image?.isTemplate = true
            button.image = image
            button.title = ""
            button.imagePosition = .imageOnly
        }
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

        let ruleCount = ConfigStore.shared.config.rules?.count ?? 0
        let rulesTitle = ruleCount == 1 ? "1 Remembered Rule" : "\(ruleCount) Remembered Rules"
        let rulesSummary = menu.addItem(withTitle: rulesTitle, action: nil, keyEquivalent: "")
        rulesSummary.isEnabled = false

        let manageRules = menu.addItem(withTitle: "Manage Rules in Settings…", action: #selector(openRulesSettings), keyEquivalent: "")
        manageRules.target = self

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

    @objc func openSettings(_ sender: Any?) {
        (NSApp.delegate as? AppDelegate)?.openSettingsWindow()
    }

    @objc func openRulesSettings(_ sender: Any?) {
        (NSApp.delegate as? AppDelegate)?.openSettingsWindow(tab: .rules)
    }

}
