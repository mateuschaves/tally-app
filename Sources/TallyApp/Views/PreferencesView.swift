import SwiftUI
import AppKit
import TallyCore

/// Preferências — a faithful port of the prototype's settings window: a sidebar
/// with the "Aparência" and "Atalhos" tabs, the shortcuts manager (search,
/// re-record, enable/disable, restore defaults, conflict message) and the
/// appearance controls (theme incl. "Sistema", material transparency and the
/// 7-color accent palette).
struct PreferencesView: View {
    @EnvironmentObject private var store: AppStore

    private enum Tab: String, CaseIterable {
        case aparencia, atalhos
    }

    @State private var tab: Tab = .atalhos
    @State private var keyMonitor: Any?

    private var theme: Theme { store.theme }

    private var versionLabel: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return "Tally \(v ?? "1.0")"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                sidebar
                detail
            }
            .frame(maxHeight: .infinity)
            footer
        }
        .frame(width: 720, height: 540)
        .background(
            ZStack {
                VisualEffectBackground(
                    material: theme.vibrancyMaterial,
                    appearance: theme.vibrancyAppearance
                )
                theme.popover(0.96)
            }
        )
        .foregroundColor(theme.tx1)
        .environment(\.theme, theme)
        .onChange(of: store.recordingId) { _, newValue in
            if newValue != nil { startRecordingMonitor() } else { stopRecordingMonitor() }
        }
        .onDisappear {
            stopRecordingMonitor()
            store.cancelRecording()
        }
    }

    // MARK: Sidebar

    private struct TabInfo {
        let tab: Tab
        let name: String
        let icon: String
        let color: Color
    }

    private var tabs: [TabInfo] {
        [
            TabInfo(tab: .aparencia, name: "Aparência", icon: "◐", color: Color(hex: "#FF9F0A")),
            TabInfo(tab: .atalhos, name: "Atalhos", icon: "⌘", color: theme.accent)
        ]
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(tabs, id: \.tab) { info in
                SidebarTabRow(info: info, selected: tab == info.tab) {
                    tab = info.tab
                    store.cancelRecording()
                }
            }
            Spacer(minLength: 0)
            Text(versionLabel)
                .font(.system(size: 10.5))
                .foregroundColor(theme.tx3)
                .padding(.horizontal, 8)
                .padding(.bottom, 2)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .frame(width: 176)
        .frame(maxHeight: .infinity)
        .background(theme.material(0.25))
        .overlay(alignment: .trailing) { theme.line.frame(width: 1) }
    }

    private struct SidebarTabRow: View {
        @Environment(\.theme) private var theme
        let info: TabInfo
        let selected: Bool
        let action: () -> Void
        @State private var hover = false

        var body: some View {
            Button(action: action) {
                HStack(spacing: 9) {
                    Text(info.icon)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(info.color)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Text(info.name)
                        .font(.system(size: 12.5, weight: selected ? .semibold : .regular))
                        .foregroundColor(theme.tx1)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background((selected || hover) ? theme.selection : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { hover = $0 }
        }
    }

    // MARK: Detail

    @ViewBuilder
    private var detail: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                switch tab {
                case .atalhos: shortcutsTab
                case .aparencia: appearanceTab
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Atalhos tab

    private var groupColors: [String: Color] {
        ["CAPTURA": theme.accent, "FOCO": Color(hex: "#30D158"), "JANELA": Color(hex: "#BF5AF2")]
    }

    private var visibleGroups: [(name: String, rows: [ShortcutSpec])] {
        ShortcutCatalog.groups.compactMap { group in
            let rows = store.shortcuts.filter {
                $0.group == group && ShortcutCatalog.matches($0, query: store.prefQuery)
            }
            return rows.isEmpty ? nil : (name: group, rows: rows)
        }
    }

    @ViewBuilder
    private var shortcutsTab: some View {
        Text("Atalhos de teclado")
            .font(.system(size: 16, weight: .bold))
        Text("Clique em um atalho para regravá-lo, ou use o botão para desativá-lo.")
            .font(.system(size: 12))
            .foregroundColor(theme.tx2)
            .padding(.top, 2)

        // Search field.
        HStack(spacing: 8) {
            MagnifierIcon()
                .foregroundColor(theme.tx3)
            TextField("Buscar atalho…", text: $store.prefQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 12.5))
                .foregroundColor(theme.tx1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(theme.selection)
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.top, 14)
        .padding(.bottom, 2)

        ForEach(visibleGroups, id: \.name) { group in
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 7) {
                    Circle()
                        .fill(groupColors[group.name] ?? theme.accent)
                        .frame(width: 5, height: 5)
                    Text(group.name)
                        .font(.system(size: 10.5, weight: .bold))
                        .kerning(1.0)
                        .foregroundColor(theme.tx3)
                }
                .padding(.bottom, 6)

                VStack(spacing: 0) {
                    ForEach(group.rows) { spec in
                        ShortcutRow(
                            spec: spec,
                            groupColor: groupColors[group.name] ?? theme.accent,
                            isRecording: store.recordingId == spec.id,
                            onRecord: { store.beginRecording(spec.id) },
                            onToggle: { store.toggleShortcut(spec.id) }
                        )
                        .overlay(alignment: .bottom) { theme.line.frame(height: 1) }
                    }
                }
                .overlay(alignment: .top) { theme.line.frame(height: 1) }
            }
            .padding(.top, 16)
        }

        if visibleGroups.isEmpty {
            Text("Nenhum atalho encontrado.")
                .font(.system(size: 12.5))
                .foregroundColor(theme.tx3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 34)
        }
    }

    private struct ShortcutRow: View {
        @Environment(\.theme) private var theme
        let spec: ShortcutSpec
        let groupColor: Color
        let isRecording: Bool
        let onRecord: () -> Void
        let onToggle: () -> Void
        @State private var hover = false

        var body: some View {
            HStack(spacing: 12) {
                Text(spec.icon)
                    .font(.system(size: 13.5))
                    .foregroundColor(spec.enabled ? groupColor : theme.tx3)
                    .frame(width: 26, height: 26)
                    .background((spec.enabled ? groupColor : Color.gray).opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                VStack(alignment: .leading, spacing: 1) {
                    Text(spec.name)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(spec.enabled ? theme.tx1 : theme.tx3)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if !spec.hint.isEmpty {
                        Text(spec.hint)
                            .font(.system(size: 11))
                            .foregroundColor(theme.tx3)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Capture area: recording pill / "Desativado" / keycaps.
                Button {
                    if spec.enabled { onRecord() }
                } label: {
                    HStack(spacing: 4) {
                        if isRecording {
                            HStack(spacing: 7) {
                                PulseDot(color: theme.accent, size: 7)
                                Text("Pressione as teclas")
                                    .font(.system(size: 11.5, weight: .semibold))
                                    .foregroundColor(theme.accent)
                                    .fixedSize()
                            }
                            .padding(.horizontal, 11)
                            .padding(.vertical, 3)
                            .background(theme.accent.opacity(0.2))
                            .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).strokeBorder(theme.accent, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        } else if !spec.enabled {
                            Text("Desativado")
                                .font(.system(size: 11.5))
                                .italic()
                                .foregroundColor(theme.tx3)
                                .padding(.horizontal, 4)
                        } else {
                            ForEach(Array(spec.keys.enumerated()), id: \.offset) { _, cap in
                                KeyCap(text: cap)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 3)
                    .frame(minHeight: 26)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(spec.enabled ? "Clique para regravar" : "Ative para usar")

                ToggleSwitch(isOn: spec.enabled, action: onToggle)
                    .help(spec.enabled ? "Desativar atalho" : "Ativar atalho")
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 9)
            .background(hover ? theme.selection : .clear)
            .onHover { hover = $0 }
        }
    }

    private struct KeyCap: View {
        @Environment(\.theme) private var theme
        let text: String

        var body: some View {
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.tx1)
                .padding(.horizontal, 7)
                .frame(minWidth: 22, minHeight: 22)
                .background(theme.selection)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(theme.line, lineWidth: 1)
                )
                .overlay(alignment: .bottom) {
                    // The keycap's thicker bottom edge (`border-bottom-width: 2px`).
                    theme.line
                        .frame(height: 1)
                        .padding(.horizontal, 5)
                }
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }

    /// iOS-style switch drawn to the prototype's metrics (38×22, knob 18).
    private struct ToggleSwitch: View {
        let isOn: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? Color(hex: "#30D158") : Color(.sRGB, red: 120/255, green: 120/255, blue: 128/255, opacity: 0.32))
                    Circle()
                        .fill(.white)
                        .shadow(color: .black.opacity(0.35), radius: 1.5, y: 1)
                        .frame(width: 18, height: 18)
                        .padding(2)
                }
                .frame(width: 38, height: 22)
                .animation(.easeOut(duration: 0.16), value: isOn)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private struct MagnifierIcon: View {
        var body: some View {
            Path { p in
                p.addEllipse(in: CGRect(x: 1.5, y: 1.5, width: 8, height: 8))
                p.move(to: CGPoint(x: 8.5, y: 8.5))
                p.addLine(to: CGPoint(x: 11.5, y: 11.5))
            }
            .stroke(style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            .frame(width: 13, height: 13)
        }
    }

    // MARK: Aparência tab

    private static let accentPalette: [(hex: String, name: String)] = [
        ("#0A84FF", "Azul"), ("#5AC8FA", "Ciano"), ("#30D158", "Verde"),
        ("#FFD60A", "Amarelo"), ("#FF9F0A", "Laranja"), ("#FF375F", "Rosa"),
        ("#BF5AF2", "Roxo")
    ]

    @ViewBuilder
    private var appearanceTab: some View {
        Text("Aparência")
            .font(.system(size: 16, weight: .bold))
        Text("Ajuste o visual do Tally sobre a sua mesa.")
            .font(.system(size: 12))
            .foregroundColor(theme.tx2)
            .padding(.top, 2)
            .padding(.bottom, 20)

        sectionLabel("TEMA")
            .padding(.bottom, 9)
        HStack(spacing: 3) {
            themeOption("Escuro", .dark)
            themeOption("Claro", .light)
            themeOption("Sistema", .system)
        }
        .padding(3)
        .background(theme.selection)
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).strokeBorder(theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

        sectionLabel("TRANSPARÊNCIA DO MATERIAL")
            .padding(.top, 26)
            .padding(.bottom, 10)
        HStack(spacing: 14) {
            Slider(
                value: Binding(get: { store.transparency }, set: { store.setTransparency($0) }),
                in: 0...85, step: 5
            )
            .tint(theme.accent)
            Text("\(Int(store.transparency))%")
                .font(.system(size: 12))
                .monospacedDigit()
                .foregroundColor(theme.tx2)
                .frame(minWidth: 34, alignment: .trailing)
        }
        .frame(maxWidth: 380, alignment: .leading)

        sectionLabel("COR DE DESTAQUE")
            .padding(.top, 26)
            .padding(.bottom, 12)
        HStack(spacing: 13) {
            ForEach(Self.accentPalette, id: \.hex) { swatch in
                accentSwatch(swatch.hex, name: swatch.name)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10.5, weight: .bold))
            .kerning(1.0)
            .foregroundColor(theme.tx3)
    }

    private func themeOption(_ label: String, _ pref: ThemePreference) -> some View {
        let selected = store.themePreference == pref
        return Button {
            store.setThemePreference(pref)
        } label: {
            Text(label)
                .font(.system(size: 12, weight: selected ? .semibold : .regular))
                .foregroundColor(theme.tx1)
                .padding(.horizontal, 16)
                .padding(.vertical, 5)
                .background(selected ? theme.popover(1) : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .shadow(color: selected ? .black.opacity(0.2) : .clear, radius: 2, y: 1)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func accentSwatch(_ hex: String, name: String) -> some View {
        let isSelected = store.accentHex.lowercased() == hex.lowercased()
        return Button {
            store.setAccent(hex)
        } label: {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: 26, height: 26)
                .overlay(
                    Circle()
                        .strokeBorder(theme.popover(1), lineWidth: isSelected ? 2 : 0)
                        .padding(isSelected ? -1 : 0)
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color(hex: hex), lineWidth: isSelected ? 2 : 0)
                        .padding(-4)
                )
        }
        .buttonStyle(.plain)
        .help(name)
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 10) {
            if tab == .atalhos {
                Button {
                    store.restoreShortcuts()
                } label: {
                    Text("Restaurar padrões")
                        .font(.system(size: 12))
                        .foregroundColor(theme.tx1)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 6)
                        .background(theme.selection)
                        .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).strokeBorder(theme.line, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            if !store.conflictMsg.isEmpty {
                HStack(spacing: 6) {
                    Text("⚠").font(.system(size: 13))
                    Text(store.conflictMsg).font(.system(size: 11.5))
                }
                .foregroundColor(Color(hex: "#FF9F0A"))
            }
            Spacer(minLength: 0)
            Button {
                store.cancelRecording()
                NSApplication.shared.keyWindow?.performClose(nil)
            } label: {
                Text("Concluído")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .overlay(alignment: .top) { theme.line.frame(height: 1) }
    }

    // MARK: Key recording (NSEvent local monitor)

    private func startRecordingMonitor() {
        stopRecordingMonitor()
        // Keys feed the recording; a click anywhere cancels it (the prototype's
        // window-level `cancelRecord`) but still reaches its target, so clicking
        // another row's capture area starts recording that one.
        keyMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .leftMouseDown, .rightMouseDown]
        ) { event in
            guard store.recordingId != nil else { return event }
            guard event.type == .keyDown else {
                store.cancelRecording()
                return event
            }
            if event.keyCode == 53 { // esc cancels the recording
                store.cancelRecording()
                return nil
            }
            let combo = KeyComboTranslator.combo(from: event)
            store.recordCombo(
                keys: combo.keys,
                keyCode: combo.keyCode,
                carbonModifiers: combo.carbonModifiers,
                isSpecialKey: combo.isSpecial
            )
            return nil
        }
    }

    private func stopRecordingMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }
}

/// Turns an `NSEvent` into the prototype's combo representation
/// (`comboFromEvent`/`symKey`): modifier symbols in ⌃⌥⇧⌘ order plus the
/// display name of the key, with the Carbon data needed to register it.
enum KeyComboTranslator {

    struct Combo {
        let keys: [String]
        let keyCode: UInt16
        let carbonModifiers: UInt32
        let isSpecial: Bool
    }

    private static let specialByKeyCode: [UInt16: String] = [
        36: "⏎", 76: "⏎",           // return / keypad enter
        49: "Espaço",
        123: "←", 124: "→", 125: "↓", 126: "↑",
        51: "⌫", 117: "⌦", 48: "⇥", 53: "esc"
    ]

    static func combo(from event: NSEvent) -> Combo {
        var mods: [String] = []
        var carbon: UInt32 = 0
        let flags = event.modifierFlags
        if flags.contains(.control) { mods.append("⌃"); carbon |= ShortcutCatalog.Modifier.control }
        if flags.contains(.option) { mods.append("⌥"); carbon |= ShortcutCatalog.Modifier.option }
        if flags.contains(.shift) { mods.append("⇧"); carbon |= ShortcutCatalog.Modifier.shift }
        if flags.contains(.command) { mods.append("⌘"); carbon |= ShortcutCatalog.Modifier.command }

        let display: String
        var isSpecial = false
        if let special = specialByKeyCode[event.keyCode] {
            display = special
            isSpecial = true
        } else if event.keyCode >= 96, let name = fKeyName(event.keyCode) {
            display = name
            isSpecial = true
        } else {
            let raw = event.charactersIgnoringModifiers ?? ""
            display = raw.uppercased()
        }

        return Combo(
            keys: mods + [display],
            keyCode: event.keyCode,
            carbonModifiers: carbon,
            isSpecial: isSpecial
        )
    }

    /// F-key names for the (non-contiguous) function-key virtual codes.
    private static func fKeyName(_ keyCode: UInt16) -> String? {
        let map: [UInt16: String] = [
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
            98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12"
        ]
        return map[keyCode]
    }
}
