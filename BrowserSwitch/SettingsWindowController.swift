import Cocoa
import SwiftUI

// NSWindow subclass — handles all keyboard shortcuts so SwiftUI List focus doesn't interfere
private class SettingsWindow: NSWindow {
    weak var vm: SettingsViewModel?

    override var canBecomeKey: Bool { true }

    // sendEvent intercepts before the List (first responder) sees anything
    override func sendEvent(_ event: NSEvent) {
        guard event.type == .keyDown, let vm, vm.editingProfileId == nil else {
            super.sendEvent(event)
            return
        }

        let cmd = event.modifierFlags.contains(.command)
        switch event.keyCode {
        case 125 where cmd: // Cmd+↓
            moveSelected(vm, by: 1)
        case 126 where cmd: // Cmd+↑
            moveSelected(vm, by: -1)
        case 36, 76 where vm.profileSelection != nil: // Return → rename
            vm.editingProfileId = vm.profileSelection
        case 49 where vm.profileSelection != nil: // Space → set default
            if let p = selectedProfile(vm) { vm.setDefault(p) }
        default:
            super.sendEvent(event)
        }
    }

    private func selectedProfile(_ vm: SettingsViewModel) -> Profile? {
        guard let id = vm.profileSelection else { return nil }
        return vm.visibleProfiles.first(where: { $0.id == id })
    }

    private func moveSelected(_ vm: SettingsViewModel, by delta: Int) {
        guard let p = selectedProfile(vm) else { return }
        if delta < 0 { vm.moveUp(p) } else { vm.moveDown(p) }
    }
}

class SettingsWindowController: NSWindowController, NSWindowDelegate {
    static let shared = SettingsWindowController()
    let vm = SettingsViewModel()

    private init() {
        let window = SettingsWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "BrowserSwitch"
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.delegate = self
        window.vm = vm
        window.contentView = NSHostingView(rootView: SettingsView(vm: vm))
        window.setContentSize(window.contentView!.fittingSize)
    }

    required init?(coder: NSCoder) { fatalError() }

    func open() {
        if window?.isVisible == false { window?.center() }
        vm.reload()
        (NSApp.delegate as? AppDelegate)?.becomeVisibleApp()
        showWindow(nil)
    }

    func windowWillClose(_ notification: Notification) {
        (NSApp.delegate as? AppDelegate)?.becomeMenuBarApp()
    }
}
