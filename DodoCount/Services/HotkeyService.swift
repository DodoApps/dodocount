import Foundation
import Carbon
import AppKit

class HotkeyService {
    static let shared = HotkeyService()

    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?

    // Callback to toggle popover
    var onTogglePopover: (() -> Void)?

    private init() {}

    // MARK: - Register Global Hotkey

    func registerHotkey() {
        guard SettingsManager.shared.settings.globalHotkeyEnabled else { return }

        // Unregister existing hotkey first
        unregisterHotkey()

        // Define hotkey: Ctrl + Shift + G
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x444F444F) // "DODO" in hex
        hotKeyID.id = 1

        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)

        // Install event handler
        let callback: EventHandlerUPP = { _, event, _ -> OSStatus in
            HotkeyService.shared.handleHotkey()
            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            &eventType,
            nil,
            &eventHandler
        )

        // Register the hotkey (Ctrl + Shift + G)
        // Key code for 'G' is 5
        let modifiers: UInt32 = UInt32(controlKey | shiftKey)
        RegisterEventHotKey(
            UInt32(kVK_ANSI_G),
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregisterHotkey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    private func handleHotkey() {
        DispatchQueue.main.async {
            self.onTogglePopover?()
        }
    }

    // MARK: - Local Keyboard Shortcuts

    func handleLocalKeyPress(_ event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command) else { return false }

        switch event.charactersIgnoringModifiers {
        case "c":
            // Cmd+C: Copy quick stats
            ShareService.shared.copyQuickStats()
            return true

        case "r":
            // Cmd+R: Refresh
            AnalyticsService.shared.refreshData()
            return true

        case ",":
            // Cmd+,: Open settings
            NSApp.sendAction(#selector(AppDelegate.openSettingsWindow), to: nil, from: nil)
            return true

        default:
            return false
        }
    }
}

// MARK: - Key Codes
private let kVK_ANSI_G: Int = 0x05
