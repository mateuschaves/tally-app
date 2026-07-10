import Foundation
import SQLite3
import TallyCore

/// Local persistence backed by SQLite (the system `libsqlite3` — no external
/// dependency). Implements the same `TaskRepository` seam as before, so nothing
/// else in the app changes and a future sync layer can still swap it out.
///
/// A fresh database contains no rows, so the app starts empty — there is no
/// seeded/mock data anywhere in the persistence layer.
final class SQLiteTaskRepository: TaskRepository {

    private var db: OpaquePointer?

    /// Tells SQLite to copy bound text immediately (safe with transient Swift strings).
    private let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    init(filename: String = "tally.sqlite3") {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Tally", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        let url = base.appendingPathComponent(filename)

        if sqlite3_open(url.path, &db) == SQLITE_OK {
            createTables()
        } else {
            db = nil
        }
    }

    deinit {
        if let db { sqlite3_close(db) }
    }

    // MARK: Schema

    private func createTables() {
        exec("""
        CREATE TABLE IF NOT EXISTS tasks (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            details TEXT NOT NULL DEFAULT '',
            project TEXT NOT NULL,
            priority TEXT NOT NULL,
            estimate INTEGER NOT NULL,
            seconds INTEGER NOT NULL,
            state TEXT NOT NULL,
            reason TEXT,
            doneAt REAL,
            createdAt REAL NOT NULL,
            updatedAt REAL NOT NULL,
            deletedAt REAL
        );
        CREATE TABLE IF NOT EXISTS projects (
            name TEXT PRIMARY KEY,
            colorHex TEXT NOT NULL,
            ord INTEGER NOT NULL
        );
        """)
        // Migration for databases created before `details` existed. A duplicate
        // column error on newer DBs is expected and ignored.
        exec("ALTER TABLE tasks ADD COLUMN details TEXT NOT NULL DEFAULT '';")
    }

    // MARK: TaskRepository

    func load() -> StoreSnapshot? {
        guard db != nil else { return nil }
        return StoreSnapshot(tasks: loadTasks(), projects: loadProjects())
    }

    /// Persist the full snapshot in a single transaction (replace-all). The data
    /// set is tiny, so rewriting the rows is cheaper and simpler than diffing.
    func save(_ snapshot: StoreSnapshot) {
        guard let db else { return }
        exec("BEGIN IMMEDIATE TRANSACTION;")
        exec("DELETE FROM tasks;")
        for task in snapshot.tasks where task.deletedAt == nil {
            insertTask(task)
        }
        exec("DELETE FROM projects;")
        for (index, project) in snapshot.projects.enumerated() {
            insertProject(project, ord: index)
        }
        if sqlite3_exec(db, "COMMIT;", nil, nil, nil) != SQLITE_OK {
            sqlite3_exec(db, "ROLLBACK;", nil, nil, nil)
        }
    }

    // MARK: Reads

    private func loadTasks() -> [TaskItem] {
        var result: [TaskItem] = []
        let sql = """
        SELECT id,title,project,priority,estimate,seconds,state,reason,doneAt,createdAt,updatedAt,deletedAt,details
        FROM tasks WHERE deletedAt IS NULL;
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return result }
        defer { sqlite3_finalize(stmt) }

        while sqlite3_step(stmt) == SQLITE_ROW {
            guard
                let idString = columnText(stmt, 0), let id = UUID(uuidString: idString),
                let title = columnText(stmt, 1),
                let project = columnText(stmt, 2),
                let priorityRaw = columnText(stmt, 3), let priority = Priority(rawValue: priorityRaw),
                let stateRaw = columnText(stmt, 6), let state = TaskState(rawValue: stateRaw)
            else { continue }

            result.append(TaskItem(
                id: id,
                title: title,
                details: columnText(stmt, 12) ?? "",
                project: project,
                priority: priority,
                estimate: Int(sqlite3_column_int64(stmt, 4)),
                seconds: Int(sqlite3_column_int64(stmt, 5)),
                state: state,
                reason: columnText(stmt, 7),
                doneAt: columnDate(stmt, 8),
                createdAt: columnDate(stmt, 9) ?? Date(),
                updatedAt: columnDate(stmt, 10) ?? Date(),
                deletedAt: columnDate(stmt, 11)
            ))
        }
        return result
    }

    private func loadProjects() -> [ProjectInfo] {
        var result: [ProjectInfo] = []
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT name,colorHex FROM projects ORDER BY ord ASC;", -1, &stmt, nil) == SQLITE_OK else {
            return result
        }
        defer { sqlite3_finalize(stmt) }
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let name = columnText(stmt, 0), let color = columnText(stmt, 1) else { continue }
            result.append(ProjectInfo(name: name, colorHex: color))
        }
        return result
    }

    // MARK: Writes

    private func insertTask(_ task: TaskItem) {
        let sql = """
        INSERT INTO tasks (id,title,project,priority,estimate,seconds,state,reason,doneAt,createdAt,updatedAt,deletedAt,details)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?);
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }

        bindText(stmt, 1, task.id.uuidString)
        bindText(stmt, 2, task.title)
        bindText(stmt, 3, task.project)
        bindText(stmt, 4, task.priority.rawValue)
        sqlite3_bind_int64(stmt, 5, Int64(task.estimate))
        sqlite3_bind_int64(stmt, 6, Int64(task.seconds))
        bindText(stmt, 7, task.state.rawValue)
        bindTextOrNull(stmt, 8, task.reason)
        bindDateOrNull(stmt, 9, task.doneAt)
        sqlite3_bind_double(stmt, 10, task.createdAt.timeIntervalSince1970)
        sqlite3_bind_double(stmt, 11, task.updatedAt.timeIntervalSince1970)
        bindDateOrNull(stmt, 12, task.deletedAt)
        bindText(stmt, 13, task.details)

        sqlite3_step(stmt)
    }

    private func insertProject(_ project: ProjectInfo, ord: Int) {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "INSERT INTO projects (name,colorHex,ord) VALUES (?,?,?);", -1, &stmt, nil) == SQLITE_OK else {
            return
        }
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, 1, project.name)
        bindText(stmt, 2, project.colorHex)
        sqlite3_bind_int64(stmt, 3, Int64(ord))
        sqlite3_step(stmt)
    }

    // MARK: Low-level helpers

    @discardableResult
    private func exec(_ sql: String) -> Bool {
        guard let db else { return false }
        return sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK
    }

    private func bindText(_ stmt: OpaquePointer?, _ index: Int32, _ value: String) {
        sqlite3_bind_text(stmt, index, value, -1, transient)
    }

    private func bindTextOrNull(_ stmt: OpaquePointer?, _ index: Int32, _ value: String?) {
        if let value {
            sqlite3_bind_text(stmt, index, value, -1, transient)
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }

    private func bindDateOrNull(_ stmt: OpaquePointer?, _ index: Int32, _ value: Date?) {
        if let value {
            sqlite3_bind_double(stmt, index, value.timeIntervalSince1970)
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }

    private func columnText(_ stmt: OpaquePointer?, _ column: Int32) -> String? {
        guard let cString = sqlite3_column_text(stmt, column) else { return nil }
        return String(cString: cString)
    }

    private func columnDate(_ stmt: OpaquePointer?, _ column: Int32) -> Date? {
        guard sqlite3_column_type(stmt, column) != SQLITE_NULL else { return nil }
        return Date(timeIntervalSince1970: sqlite3_column_double(stmt, column))
    }
}
