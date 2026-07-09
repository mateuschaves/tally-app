import Foundation

/// Lifecycle state of a task. Ported from the prototype's `st` field.
///
/// Invariant enforced by `TaskEngine.norm`: there is at most one `.now` task,
/// and if any `.next` task exists there is exactly one `.now`.
public enum TaskState: String, Codable, Sendable {
    /// The single task currently being timed ("AGORA").
    case now
    /// Queued task ("A SEGUIR").
    case next
    /// Impeded task with a reason ("IMPEDIDAS").
    case blocked
    /// Completed task (has a `doneAt`).
    case done
}
