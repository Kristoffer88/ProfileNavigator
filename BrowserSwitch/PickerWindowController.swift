import Cocoa
import SwiftUI

// Shared state between NSPanel key handling and SwiftUI view
class PickerState: ObservableObject {
    @Published var selectedIndex: Int
    @Published var remember: Bool = true
    let profiles: [Profile]
    var onConfirm: ((Profile, Bool) -> Void)?
    var onCancel: (() -> Void)?

    init(profiles: [Profile], defaultProfile: Profile?) {
        self.profiles = profiles
        self.selectedIndex = profiles.firstIndex(where: { $0.id == defaultProfile?.id }) ?? 0
    }

    func confirm() {
        guard !profiles.isEmpty else { return }
        let profile = profiles[selectedIndex]
        onConfirm?(profile, remember)
    }

    func moveSelection(by delta: Int) {
        guard !profiles.isEmpty else { return }
        selectedIndex = (selectedIndex + delta + profiles.count) % profiles.count
    }
}

// NSPanel subclass that captures key events before SwiftUI sees them
private class PickerPanel: NSPanel {
    var state: PickerState?

    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard let state else { super.keyDown(with: event); return }

        let chars = event.charactersIgnoringModifiers ?? ""

        switch event.keyCode {
        case 125: // ↓
            state.moveSelection(by: 1)
        case 126: // ↑
            state.moveSelection(by: -1)
        case 36, 76: // Enter / numpad Enter
            state.confirm()
        case 53: // Esc
            state.onCancel?()
        case 48: // Tab
            state.remember.toggle()
        default:
            if let n = Int(chars), n >= 1 && n <= state.profiles.count {
                state.selectedIndex = n - 1
                state.confirm()
            } else if chars.lowercased() == "r" {
                state.remember.toggle()
            } else {
                super.keyDown(with: event)
            }
        }
    }
}

class PickerWindowController: NSWindowController {
    private let state: PickerState

    init(url: URL, profiles: [Profile], defaultProfile: Profile?) {
        let st = PickerState(profiles: profiles, defaultProfile: defaultProfile)
        self.state = st

        let panel = PickerPanel(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.state = st

        super.init(window: panel)

        st.onConfirm = { [weak self] profile, remember in
            if remember, let host = url.host, !host.isEmpty {
                ConfigStore.shared.setRule(host: host, profileId: profile.id)
            }
            BrowserLauncher.open(url: url, profile: profile)
            self?.close()
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.statusBar?.rebuildMenu()
            }
        }

        st.onCancel = { [weak self] in
            self?.close()
        }

        let view = PickerView(url: url, state: st)
        let hosting = NSHostingView(rootView: view)
        hosting.frame.size = hosting.fittingSize
        panel.contentView = hosting
        panel.setContentSize(hosting.fittingSize)
        panel.center()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func showWindow(_ sender: Any?) {
        guard let panel = window else { return }
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(sender)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
    }
}
