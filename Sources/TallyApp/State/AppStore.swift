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
}

/// Detailed add-form fields (`this.state.f`).
struct FormState: Equatable {
    var title = ""
    var project = "Geral"
    var priority: Priority = .media
    var estimate = 30
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

    @Published var themeMode: Theme.Mode = .dark {
        didSet { UserDefaults.standard.set(themeMode.rawValue, forKey: Keys.theme) }
    }
    @Published var accentHex: String = "#0A84FF" {
        didSet { UserDefaults.standard.set(accentHex, forKey: Keys.accent) }
    }
    @Published var transparency: Double = 40 {
        didSet { UserDefaults.standard.set(transparency, forKey: Keys.transparency) }
    }
    private(set) var widgetPosition: CGPoint?

    // MARK: Ephemeral UI state

    @Published var paused = false
    @Published var addOpen = false
    @Published var quick = ""
    @Published var form = FormState()
    @Published var overlay: OverlayKind = .none
    @Published var blockId: UUID?
    @Published var blockReason = ""
    @Published var quickEntryText = ""
    @Published var reportOffset = 0
    @Published var copied = false
    @Published var nowDate = Date()

    // MARK: Window callbacks (wired by PanelController)

    var onToggleWidget: (() -> Void)?
    var onShowWidget: (() -> Void)?

    // MARK: Dependencies

    private let repository: TaskRepository
    private var timer: Timer?
    private var ticksSinceSave = 0

    private enum Keys {
        static let theme = "tally.themeMode"
        static let accent = "tally.accentHex"
        static let transparency = "tally.transparency"
        static let posX = "tally.widget.x"
        static let posY = "tally.widget.y"
    }

    // MARK: Init

    init(repository: TaskRepository = FileTaskRepository()) {
        self.repository = repository
        // All stored properties have inline defaults; finish phase 1 before we
        // touch `self` (NSObject subclass can't read instance state pre-super).
        super.init()

        let defaults = UserDefaults.standard

        // Preferences.
        if let raw = defaults.string(forKey: Keys.theme), let mode = Theme.Mode(rawValue: raw) {
            themeMode = mode
        }
        if let hex = defaults.string(forKey: Keys.accent) {
            accentHex = hex
        }
        if let value = defaults.object(forKey: Keys.transparency) as? Double {
            transparency = value
        }
        if let x = defaults.object(forKey: Keys.posX) as? Double,
           let y = defaults.object(forKey: Keys.posY) as? Double {
            widgetPosition = CGPoint(x: x, y: y)
        }

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

    // MARK: Theme

    var theme: Theme {
        Theme(mode: themeMode, accentHex: accentHex, transparency: transparency)
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
    func addTask(title: String, project: String = "Geral", priority: Priority = .media, estimate: Int = 30) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tasks = TaskEngine.add(tasks, title: trimmed, project: project, priority: priority, estimate: estimate, now: Date())
        quick = ""
        quickEntryText = ""
        addOpen = false
        overlay = .none
        form = FormState()
        persist()
    }

    func submitForm() {
        addTask(title: form.title, project: form.project, priority: form.priority, estimate: form.estimate)
    }

    func submitQuick() {
        addTask(title: quick)
    }

    func submitQuickEntry() {
        let parsed = QuickParse.parse(quickEntryText)
        addTask(
            title: parsed.title,
            project: parsed.project.map { canonicalProject($0) } ?? "Geral",
            priority: parsed.priority ?? .media,
            estimate: parsed.estimate ?? 30
        )
    }

    // MARK: Overlays / toggles

    func openQuickEntry() {
        quickEntryText = ""
        blockId = nil
        overlay = .quickEntry
    }

    func openAdd() { addOpen = true }
    func closeAdd() { addOpen = false }

    func openReport() {
        reportOffset = 0
        copied = false
        blockId = nil
        overlay = .report
    }

    func closeAll() {
        overlay = .none
        blockId = nil
        addOpen = false
        copied = false
    }

    func togglePause() {
        paused.toggle()
        persist()
    }

    func toggleTheme() {
        themeMode = themeMode == .dark ? .light : .dark
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

    func saveWidgetPosition(_ point: CGPoint) {
        widgetPosition = point
        UserDefaults.standard.set(Double(point.x), forKey: Keys.posX)
        UserDefaults.standard.set(Double(point.y), forKey: Keys.posY)
    }

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
