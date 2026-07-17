import SwiftUI
import Combine
import TallyCore

/// Which full-screen overlay is showing (they are mutually exclusive, like the
/// prototype's `qeOpen` / `blockId` / `reportOpen`).
enum OverlayKind: Equatable {
    case none
    case quickEntry
    case block
    case report
    case newProject
    case deleteTask
    case editTask
}

/// Theme selection in Preferências — `system` follows macOS, mirroring the
/// prototype's `themeOverride: null` ("Sistema").
enum ThemePreference: String, Codable {
    case system, dark, light
}

/// Detailed add-form fields (`this.state.f`).
struct FormState: Equatable {
    var title = ""
    var details = ""
    var project = "Geral"
    var priority: Priority = .media
    var estimate = 60
}

/// Fields for the "Editar tarefa" overlay (`editId` targets the task). Unlike the
/// add form these are seeded from the existing task and the logged time is
/// editable, so it carries `loggedSeconds` alongside the estimate.
struct EditFormState: Equatable {
    var project = "Geral"
    var priority: Priority = .media
    /// Estimate in minutes (matches `TaskItem.estimate`).
    var estimate = 60
    /// Logged time in seconds (matches `TaskItem.seconds`).
    var loggedSeconds = 0
}

/// The single source of truth — a direct port of the prototype's React component
/// state + methods. Owns the task list, preferences, ephemeral UI state and the
/// 1-second timer; every mutation goes through `TallyCore.TaskEngine`.
@MainActor
final class AppStore: NSObject, ObservableObject {

    // MARK: Domain (persisted via repository)

    @Published var tasks: [TaskItem] = []
    @Published var projects: [ProjectInfo] = ProjectPalette.defaults

    // MARK: Preferences (persisted via UserDefaults)

    @Published var themePreference: ThemePreference = .system {
        didSet { UserDefaults.standard.set(themePreference.rawValue, forKey: Keys.theme) }
    }
    /// Tracks the macOS appearance so `.system` re-renders on theme changes.
    @Published private(set) var systemIsDark = true
    @Published var accentHex: String = "#0A84FF" {
        didSet { UserDefaults.standard.set(accentHex, forKey: Keys.accent) }
    }
    @Published var transparency: Double = 40 {
        didSet { UserDefaults.standard.set(transparency, forKey: Keys.transparency) }
    }
    /// Configurable keyboard shortcuts (Preferências → Atalhos). Always the
    /// full catalog: persisted entries only override combo/enabled.
    @Published var shortcuts: [ShortcutSpec] = ShortcutCatalog.defaults {
        didSet {
            if let data = try? JSONEncoder().encode(shortcuts) {
                UserDefaults.standard.set(data, forKey: Keys.shortcuts)
            }
        }
    }

    // MARK: Ephemeral UI state

    @Published var paused = false
    @Published var addOpen = false
    @Published var quick = ""
    @Published var form = FormState()
    @Published var overlay: OverlayKind = .none
    @Published var blockId: UUID?
    @Published var blockReason = ""
    @Published var quickEntryText = ""
    @Published var quickEntryDetails = ""
    @Published var reportOffset = 0
    @Published var copied = false
    @Published var nowDate = Date()
    /// New-project modal fields (`npName`/`npColor`).
    @Published var newProjectName = ""
    @Published var newProjectColor = "#5AC8FA"
    /// Task pending delete confirmation (`delId`).
    @Published var deleteId: UUID?
    /// Task being edited in the "Editar tarefa" overlay, plus its working fields.
    @Published var editId: UUID?
    @Published var editForm = EditFormState()
    /// Shortcut being re-recorded in Preferências (`recordingId`), plus the
    /// validation message shown in the window footer (`conflictMsg`).
    @Published var recordingId: String?
    @Published var conflictMsg = ""
    /// Search query of the shortcuts screen (`prefQuery`).
    @Published var prefQuery = ""
    /// Bumped whenever something (hotkey, menu) asks for the Settings window;
    /// a view with `@Environment(\.openSettings)` reacts to it.
    @Published var settingsRequestID = 0
    /// Whether the floating widget panel is currently on screen. Not persisted:
    /// the widget always appears (centered) on launch, and this only tracks the
    /// in-session close (×) / show state, driving the menu-bar "Ocultar/Mostrar" label.
    @Published var widgetVisible = true

    // MARK: Window callbacks (wired by PanelController)

    var onToggleWidget: (() -> Void)?
    var onShowWidget: (() -> Void)?
    var onHideWidget: (() -> Void)?
    var onCenterWidget: (() -> Void)?

    // MARK: Dependencies

    private let repository: TaskRepository
    private var timer: Timer?
    private var ticksSinceSave = 0

    private enum Keys {
        static let theme = "tally.themeMode"
        static let accent = "tally.accentHex"
        static let transparency = "tally.transparency"
        static let shortcuts = "tally.shortcuts"
    }

    // MARK: Init

    init(repository: TaskRepository = SQLiteTaskRepository()) {
        self.repository = repository
        // All stored properties have inline defaults; finish phase 1 before we
        // touch `self` (NSObject subclass can't read instance state pre-super).
        super.init()

        let defaults = UserDefaults.standard

        // Preferences. The theme key also accepts the pre-"Sistema" values
        // ("dark"/"light"), which map 1:1 onto ThemePreference.
        if let raw = defaults.string(forKey: Keys.theme), let pref = ThemePreference(rawValue: raw) {
            themePreference = pref
        }
        if let hex = defaults.string(forKey: Keys.accent) {
            accentHex = hex
        }
        if let value = defaults.object(forKey: Keys.transparency) as? Double {
            transparency = value
        }
        if let data = defaults.data(forKey: Keys.shortcuts),
           let saved = try? JSONDecoder().decode([ShortcutSpec].self, from: data) {
            shortcuts = ShortcutCatalog.merge(saved: saved)
        }

        // Follow the macOS appearance for the "Sistema" theme.
        systemIsDark = Self.readSystemIsDark()
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(systemThemeChanged),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"), object: nil
        )

        // Domain — restore from disk, or start empty (no sample data). Restored
        // tasks are normalized so the "one active task" invariant holds even if
        // the saved snapshot lost its `.now`.
        if let snapshot = repository.load() {
            tasks = TaskEngine.normalize(snapshot.tasks, now: Date())
            projects = snapshot.projects.isEmpty ? ProjectPalette.defaults : snapshot.projects
        } else {
            tasks = []
        }

        startTimer()
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    // MARK: Theme

    /// The dark/light mode actually in effect (resolves `.system`).
    var effectiveMode: Theme.Mode {
        switch themePreference {
        case .dark: return .dark
        case .light: return .light
        case .system: return systemIsDark ? .dark : .light
        }
    }

    var theme: Theme {
        Theme(mode: effectiveMode, accentHex: accentHex, transparency: transparency)
    }

    nonisolated private static func readSystemIsDark() -> Bool {
        // The global appearance preference; absent means light.
        UserDefaults.standard.string(forKey: "AppleInterfaceStyle")?.lowercased() == "dark"
    }

    /// Distributed notifications arrive off the main thread; hop before
    /// touching published state.
    @objc nonisolated private func systemThemeChanged() {
        Task { @MainActor [weak self] in
            self?.systemIsDark = Self.readSystemIsDark()
        }
    }

    // MARK: Derived task views

    var current: TaskItem? { tasks.first { $0.state == .now } }
    var nextTasks: [TaskItem] { tasks.filter { $0.state == .next } }
    var blockedTasks: [TaskItem] { tasks.filter { $0.state == .blocked } }
    var doneTasks: [TaskItem] { tasks.filter { $0.state == .done } }
    var doneCount: Int { doneTasks.count }
    var hasCurrent: Bool { current != nil }
    var hasBlocked: Bool { !blockedTasks.isEmpty }
    var noNext: Bool { nextTasks.isEmpty }

    var focusSeconds: Int { tasks.reduce(0) { $0 + $1.seconds } }

    /// "restam <tempo>": remaining time on the active task + the queue estimates.
    var remainLabel: String {
        let currentRemaining = current.map { max(0, Double($0.estimate) - Double($0.seconds) / 60) } ?? 0
        let queued = nextTasks.reduce(0.0) { $0 + Double($1.estimate) }
        return "restam " + TimeFormat.minutes(currentRemaining + queued)
    }

    /// Fraction of tasks completed (for reference by callers that need it).
    var dayFraction: Double {
        tasks.isEmpty ? 0 : Double(doneTasks.count) / Double(tasks.count)
    }

    func color(for project: String) -> Color {
        Color(hex: projects.first { $0.name == project }?.colorHex ?? "#98989D")
    }

    var report: ReportBuilder.Report {
        ReportBuilder.build(tasks: tasks, offset: reportOffset, now: nowDate)
    }

    // MARK: Task actions (ported from the component methods)

    func complete(_ id: UUID) {
        tasks = TaskEngine.complete(tasks, id: id, now: Date())
        persist()
    }

    func completeCurrent() {
        if let current { complete(current.id) }
    }

    func start(_ id: UUID) {
        tasks = TaskEngine.start(tasks, id: id, now: Date())
        persist()
    }

    func unblock(_ id: UUID) {
        tasks = TaskEngine.unblock(tasks, id: id, now: Date())
        persist()
    }

    func openBlock(_ id: UUID) {
        blockId = id
        blockReason = ""
        overlay = .block
    }

    func blockCurrent() {
        if let current { openBlock(current.id) }
    }

    func confirmBlock() {
        guard let id = blockId else { return }
        tasks = TaskEngine.block(tasks, id: id, reason: blockReason, now: Date())
        blockId = nil
        blockReason = ""
        overlay = .none
        persist()
    }

    /// Core add path. Resets the entry surfaces on success (`addTask`).
    func addTask(title: String, details: String = "", project: String = "Geral", priority: Priority = .media, estimate: Int = 60) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tasks = TaskEngine.add(tasks, title: trimmed, details: details, project: project, priority: priority, estimate: estimate, now: Date())
        quick = ""
        quickEntryText = ""
        quickEntryDetails = ""
        addOpen = false
        overlay = .none
        form = FormState()
        persist()
    }

    func submitForm() {
        addTask(title: form.title, details: form.details, project: form.project, priority: form.priority, estimate: form.estimate)
    }

    func submitQuick() {
        addTask(title: quick)
    }

    func submitQuickEntry() {
        let parsed = QuickParse.parse(quickEntryText)
        addTask(
            title: parsed.title,
            details: quickEntryDetails,
            project: parsed.project.map { canonicalProject($0) } ?? "Geral",
            priority: parsed.priority ?? .media,
            estimate: parsed.estimate ?? 60
        )
    }

    // MARK: Overlays / toggles

    func openQuickEntry() {
        quickEntryText = ""
        quickEntryDetails = ""
        blockId = nil
        overlay = .quickEntry
    }

    // MARK: New project

    /// Open the "Novo projeto" modal (from the add form's "+ Novo" chip).
    func openNewProject() {
        newProjectName = ""
        newProjectColor = "#5AC8FA"
        overlay = .newProject
    }

    func closeNewProject() {
        overlay = .none
    }

    /// Add (or reuse) a project with the given color; returns the canonical name.
    /// Case-insensitive dedup, mirroring the prototype's `addProject`.
    @discardableResult
    func addProject(name: String, color: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let existing = projects.first(where: { $0.name.lowercased() == trimmed.lowercased() }) {
            return existing.name
        }
        projects.append(ProjectInfo(name: trimmed, colorHex: color))
        persist()
        return trimmed
    }

    /// Confirm the modal: create the project and select it in the add form.
    func confirmNewProject() {
        guard let key = addProject(name: newProjectName, color: newProjectColor) else { return }
        form.project = key
        newProjectName = ""
        overlay = .none
    }

    func openAdd() { addOpen = true }
    func closeAdd() { addOpen = false }

    // MARK: Delete task (ported from `openDel`/`confirmDel`)

    func openDelete(_ id: UUID) {
        deleteId = id
        blockId = nil
        overlay = .deleteTask
    }

    var deleteTask: TaskItem? {
        deleteId.flatMap { id in tasks.first { $0.id == id } }
    }

    func confirmDelete() {
        guard let id = deleteId else { return }
        deleteId = nil
        overlay = .none
        tasks = TaskEngine.delete(tasks, id: id, now: Date())
        persist()
    }

    // MARK: Edit task (estimate, logged time, priority, project)

    /// Open the "Editar tarefa" overlay, seeding the form from the target task.
    func openEdit(_ id: UUID) {
        guard let task = tasks.first(where: { $0.id == id }) else { return }
        editId = id
        editForm = EditFormState(
            project: task.project,
            priority: task.priority,
            estimate: task.estimate,
            loggedSeconds: task.seconds
        )
        blockId = nil
        deleteId = nil
        overlay = .editTask
    }

    var editTask: TaskItem? {
        editId.flatMap { id in tasks.first { $0.id == id } }
    }

    /// Apply the edited fields to the task and close the overlay.
    func submitEdit() {
        guard let id = editId else { return }
        tasks = TaskEngine.edit(
            tasks, id: id,
            project: editForm.project,
            priority: editForm.priority,
            estimate: editForm.estimate,
            seconds: editForm.loggedSeconds,
            now: Date()
        )
        editId = nil
        overlay = .none
        persist()
    }

    func openReport() {
        reportOffset = 0
        copied = false
        blockId = nil
        overlay = .report
    }

    func closeAll() {
        overlay = .none
        blockId = nil
        deleteId = nil
        editId = nil
        addOpen = false
        copied = false
    }

    func togglePause() {
        paused.toggle()
        persist()
    }

    func setThemePreference(_ pref: ThemePreference) {
        themePreference = pref
    }

    // MARK: Shortcuts (Preferências → Atalhos)

    func beginRecording(_ id: String) {
        recordingId = id
        conflictMsg = ""
    }

    func cancelRecording() {
        recordingId = nil
        conflictMsg = ""
    }

    /// Store a recorded combo on the shortcut being recorded, enforcing the
    /// prototype's rules: needs a modifier (unless it's a special key) and must
    /// not clash with another enabled shortcut.
    func recordCombo(keys: [String], keyCode: UInt16?, carbonModifiers: UInt32, isSpecialKey: Bool) {
        guard let id = recordingId else { return }
        guard carbonModifiers != 0 || isSpecialKey else {
            conflictMsg = "Combine uma tecla com ⌘, ⌥, ⌃ ou ⇧."
            return
        }
        let combo = keys.joined(separator: "+")
        if let clash = ShortcutCatalog.conflict(in: shortcuts, combo: combo, excluding: id) {
            conflictMsg = "«\(clash.name)» já usa esse atalho."
            return
        }
        shortcuts = shortcuts.map { spec in
            guard spec.id == id else { return spec }
            var out = spec
            out.keys = keys
            out.keyCode = keyCode
            out.carbonModifiers = carbonModifiers
            out.enabled = true
            return out
        }
        recordingId = nil
        conflictMsg = ""
    }

    func toggleShortcut(_ id: String) {
        shortcuts = shortcuts.map { spec in
            guard spec.id == id else { return spec }
            var out = spec
            out.enabled.toggle()
            return out
        }
        if recordingId == id {
            recordingId = nil
            conflictMsg = ""
        }
    }

    func restoreShortcuts() {
        shortcuts = ShortcutCatalog.defaults
        recordingId = nil
        conflictMsg = ""
    }

    func shortcut(_ id: String) -> ShortcutSpec? {
        shortcuts.first { $0.id == id }
    }

    /// Ask a view holding `@Environment(\.openSettings)` to open Preferências.
    func requestPreferences() {
        settingsRequestID += 1
    }

    /// Dispatch a configured shortcut, ported from the prototype's `runAction`.
    /// (`confirmAdd` is inherently local to the capture fields, so it's a no-op.)
    func runAction(_ id: String) {
        switch id {
        case "new": openQuickEntry()
        case "report": openReport()
        case "prefs": requestPreferences()
        case "toggleWidget": onToggleWidget?()
        case "complete": completeCurrent()
        case "block": blockCurrent()
        case "pause": togglePause()
        case "close": closeAll()
        default: break
        }
    }

    func reportPrev() { reportOffset = min(7, reportOffset + 1) }
    func reportNext() { reportOffset = max(0, reportOffset - 1) }
    func reportToday() { reportOffset = 0 }

    func copyReport() {
        ClipboardService.copy(report.text)
        copied = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            self?.copied = false
        }
    }

    // MARK: Projects

    /// Non-mutating canonical name for previews (chips) — never creates a project
    /// (safe to call from a SwiftUI `body`).
    func canonicalProjectPreview(_ raw: String) -> String {
        if let existing = projects.first(where: { $0.name.lowercased() == raw.lowercased() }) {
            return existing.name
        }
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }

    /// Canonicalize a raw project token from quick-entry, creating a new project
    /// (with an assigned color) when it doesn't exist. Ported from `canonProj`.
    func canonicalProject(_ raw: String) -> String {
        if let existing = projects.first(where: { $0.name.lowercased() == raw.lowercased() }) {
            return existing.name
        }
        let name = raw.prefix(1).uppercased() + raw.dropFirst()
        let customIndex = max(0, projects.count - ProjectPalette.defaults.count)
        let color = ProjectPalette.customColors[customIndex % ProjectPalette.customColors.count]
        projects.append(ProjectInfo(name: name, colorHex: color))
        persist()
        return name
    }

    // MARK: Preferences setters

    func setAccent(_ hex: String) { accentHex = hex }
    func setTransparency(_ value: Double) { transparency = value }

    // MARK: Timer

    private func startTimer() {
        // Target/selector timer (no @Sendable closure capturing self) added to
        // .common mode so the clock keeps ticking during menu/drag tracking.
        let timer = Timer(timeInterval: 1, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    @objc private func timerFired() {
        tick()
    }

    private func tick() {
        nowDate = Date()
        // Only mutate + throttle-save when the active timer actually advances.
        // When paused or idle nothing changes, so we avoid needless disk writes.
        guard !paused, current != nil else { return }
        tasks = TaskEngine.tick(tasks, paused: paused, now: nowDate)
        ticksSinceSave += 1
        if ticksSinceSave >= 5 {
            ticksSinceSave = 0
            persist()
        }
    }

    // MARK: Persistence

    func persist() {
        repository.save(StoreSnapshot(tasks: tasks, projects: projects))
    }
}
