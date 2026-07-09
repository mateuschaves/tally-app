import Foundation
import TallyCore

/// Persisted snapshot of the user's data.
struct StoreSnapshot: Codable {
    var tasks: [TaskItem]
    var projects: [ProjectInfo]
}

/// Local-first persistence seam. The app depends only on this protocol, so a
/// future `SyncingTaskRepository` (CloudKit or a custom API) can replace the
/// local file store without touching the UI or the store.
protocol TaskRepository {
    func load() -> StoreSnapshot?
    func save(_ snapshot: StoreSnapshot)
}
