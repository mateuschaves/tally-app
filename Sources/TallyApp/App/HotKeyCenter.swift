import AppKit
import Carbon.HIToolbox
import TallyCore

/// System-wide hotkeys via Carbon `RegisterEventHotKey` — chosen over an
/// `NSEvent` global monitor because it fires everywhere **without** requiring
/// Accessibility/Input-Monitoring permission.
///
/// Registers every enabled `ShortcutSpec` that has a key code and at least one
/// modifier (plain ⏎/esc stay local to the app's own windows — swallowing them
/// system-wide would break other apps). Call `apply(_:)` again whenever the
/// user re-records or toggles a shortcut; the registry is rebuilt in place.
final class HotKeyCenter {

    private struct Registered {
        let ref: EventHotKeyRef
        let shortcutId: String
    }

    private var eventHandler: EventHandlerRef?
    private var registered: [UInt32: Registered] = [:]
    private var nextId: UInt32 = 1
    private let onFire: (String) -> Void

    private static let signature = OSType(0x5441_4C59) // 'TALY'

    /// `onFire` receives the `ShortcutSpec.id` of the pressed hotkey.
    init?(onFire: @escaping (String) -> Void) {
        self.onFire = onFire

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let userData, let event else { return noErr }
                var hotKeyID = EventHotKeyID()
                let err = GetEventParameter(
                    event, EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID), nil,
                    MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID
                )
                guard err == noErr, hotKeyID.signature == HotKeyCenter.signature else { return noErr }
                let center = Unmanaged<HotKeyCenter>.fromOpaque(userData).takeUnretainedValue()
                center.fire(id: hotKeyID.id)
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
        guard status == noErr else { return nil }
    }

    /// Rebuild the registry to match `shortcuts`. Safe to call repeatedly.
    func apply(_ shortcuts: [ShortcutSpec]) {
        unregisterAll()
        for spec in shortcuts {
            guard spec.enabled, let keyCode = spec.keyCode, spec.carbonModifiers != 0 else { continue }
            let id = nextId
            nextId += 1
            let hotKeyID = EventHotKeyID(signature: Self.signature, id: id)
            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(
                UInt32(keyCode), spec.carbonModifiers, hotKeyID,
                GetApplicationEventTarget(), 0, &ref
            )
            if status == noErr, let ref {
                registered[id] = Registered(ref: ref, shortcutId: spec.id)
            }
        }
    }

    private func fire(id: UInt32) {
        guard let entry = registered[id] else { return }
        onFire(entry.shortcutId)
    }

    private func unregisterAll() {
        for entry in registered.values { UnregisterEventHotKey(entry.ref) }
        registered.removeAll()
    }

    deinit {
        unregisterAll()
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }
}
