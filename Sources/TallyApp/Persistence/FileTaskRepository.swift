import Foundation

/// Stores the snapshot as JSON in Application Support/Tally/store.json.
/// Writes are atomic. Failures are swallowed (best-effort local cache), exactly
/// like the prototype's `try { localStorage… } catch {}`.
final class FileTaskRepository: TaskRepository {
    private let url: URL
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()
    private let decoder = JSONDecoder()

    init(filename: String = "store.json") {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Tally", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        self.url = base.appendingPathComponent(filename)
    }

    func load() -> StoreSnapshot? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(StoreSnapshot.self, from: data)
    }

    func save(_ snapshot: StoreSnapshot) {
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
