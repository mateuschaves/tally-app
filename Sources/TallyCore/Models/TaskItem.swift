import Foundation

/// A single task. Named `TaskItem` (not `Task`) to avoid colliding with Swift
/// Concurrency's `Task`.
///
/// Value type so the engine can transform `[TaskItem]` immutably, exactly like
/// the prototype's `this.state.tasks.map(...)` style. Sync-ready fields
/// (`id`/`updatedAt`/`deletedAt`) are present now so a future
/// `SyncingTaskRepository` can diff/merge without a schema change.
public struct TaskItem: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    /// Project name (canonical). Color is resolved in the UI layer.
    public var project: String
    public var priority: Priority
    /// Estimate in minutes.
    public var estimate: Int
    /// Seconds spent (accumulated by the 1s timer while `state == .now`).
    public var seconds: Int
    public var state: TaskState
    /// Reason, present only when `state == .blocked`.
    public var reason: String?
    /// Completion timestamp, present only when `state == .done`.
    public var doneAt: Date?
    public var createdAt: Date
    public var updatedAt: Date
    /// Soft-delete marker (nil = live). Kept for future sync.
    public var deletedAt: Date?

    public init(
        id: UUID = UUID(),
        title: String,
        project: String = "Geral",
        priority: Priority = .media,
        estimate: Int = 30,
        seconds: Int = 0,
        state: TaskState = .next,
        reason: String? = nil,
        doneAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.project = project
        self.priority = priority
        self.estimate = estimate
        self.seconds = seconds
        self.state = state
        self.reason = reason
        self.doneAt = doneAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    /// Progress percentage `sec / (est*60)`, clamped to 100.
    /// Ported from `deco`: `Math.min(100, Math.round(sec / max(1, est*60) * 100))`.
    public var progressPercent: Int {
        let denom = Double(max(1, estimate * 60))
        return min(100, Int((Double(seconds) / denom * 100).rounded()))
    }
}
