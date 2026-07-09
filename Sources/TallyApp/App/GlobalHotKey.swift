import AppKit
import Carbon.HIToolbox

/// A single global hotkey via Carbon `RegisterEventHotKey`. Chosen over an
/// `NSEvent` global monitor because it fires system-wide **without** requiring
/// Accessibility/Input-Monitoring permission. Used for ⌘K "new task anywhere".
final class GlobalHotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let onFire: () -> Void

    /// - Parameters:
    ///   - keyCode: a virtual key code (e.g. `kVK_ANSI_K`).
    ///   - modifiers: Carbon modifier mask (e.g. `cmdKey`).
    init?(keyCode: UInt32, modifiers: UInt32, onFire: @escaping () -> Void) {
        self.onFire = onFire

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData -> OSStatus in
                guard let userData else { return noErr }
                let instance = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
                instance.onFire()
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
        guard installStatus == noErr else { return nil }

        let hotKeyID = EventHotKeyID(signature: OSType(0x54414C59), id: 1) // 'TALY'
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        guard registerStatus == noErr else {
            if let eventHandler { RemoveEventHandler(eventHandler) }
            return nil
        }
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }
}
