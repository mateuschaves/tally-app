import Foundation

/// Pure state transitions over `[TaskItem]`, ported from the prototype's
/// `seed`/`norm`/`patch`/`complete`/`start`/`unblock`/`addTask` methods.
///
/// Every mutation returns a new array and stamps `updatedAt` on changed items so
/// the (future) sync layer has a monotonic clock. A `now:` parameter is threaded
/// through instead of reading the clock internally, keeping the engine
/// deterministic and unit-testable.
public enum TaskEngine {

    // MARK: - Seed

    /// Deterministic sample data matching the prototype's `seed()`.
    /// Fixed UUIDs keep tests stable. NOTE: this is a test/demo fixture only —
    /// the app starts with an empty task list (no sample data).
    public static func seed(now: Date) -> [TaskItem] {
        func fixedID(_ n: Int) -> UUID {
            UUID(uuidString: "00000000-0000-0000-0000-0000000000" + String(format: "%02d", n))!
        }
        return [
            TaskItem(id: fixedID(1), title: "Revisar PR do módulo de pagamentos",
                     project: "Backend", priority: .alta, estimate: 45, seconds: 1385,
                     state: .now, createdAt: now, updatedAt: now),
            TaskItem(id: fixedID(2), title: "Atualizar fluxo de onboarding no Figma",
                     project: "Design", priority: .media, estimate: 60, seconds: 0,
                     state: .next, createdAt: now, updatedAt: now),
            TaskItem(id: fixedID(3), title: "Preparar demo da sprint",
                     project: "Reuniões", priority: .alta, estimate: 30, seconds: 0,
                     state: .next, createdAt: now, updatedAt: now),
            TaskItem(id: fixedID(4), title: "Responder feedback do QA",
                     project: "Backend", priority: .baixa, estimate: 15, seconds: 0,
                     state: .next, createdAt: now, updatedAt: now),
            TaskItem(id: fixedID(5), title: "Publicar release 2.4",
                     project: "Backend", priority: .alta, estimate: 20, seconds: 760,
                     state: .blocked, reason: "Aguardando aprovação da revisão de segurança",
                     createdAt: now, updatedAt: now),
            TaskItem(id: fixedID(6), title: "Daily standup",
                     project: "Reuniões", priority: .media, estimate: 15, seconds: 900,
                     state: .done, doneAt: now.addingTimeInterval(-4 * 3600),
                     createdAt: now, updatedAt: now),
            TaskItem(id: fixedID(7), title: "Corrigir bug de sessão no login",
                     project: "Backend", priority: .alta, estimate: 30, seconds: 2290,
                     state: .done, doneAt: now.addingTimeInterval(-2 * 3600),
                     createdAt: now, updatedAt: now)
        ]
    }

    // MARK: - Normalization

    /// If nothing is `.now`, promote the first `.next` task. Ported from `norm`.
    public static func normalize(_ tasks: [TaskItem], now: Date) -> [TaskItem] {
        if tasks.contains(where: { $0.state == .now }) { return tasks }
        guard let index = tasks.firstIndex(where: { $0.state == .next }) else { return tasks }
        var out = tasks
        out[index].state = .now
        out[index].updatedAt = now
        return out
    }

    // MARK: - Mutations

    /// Apply `mutation` to the task with `id`, stamp `updatedAt`, then normalize.
    /// Ported from `patch`.
    private static func patch(_ tasks: [TaskItem], id: UUID, now: Date, _ mutation: (inout TaskItem) -> Void) -> [TaskItem] {
        let mapped = tasks.map { task -> TaskItem in
            guard task.id == id else { return task }
            var copy = task
            mutation(&copy)
            copy.updatedAt = now
            return copy
        }
        return normalize(mapped, now: now)
    }

    /// Mark a task done. Ported from `complete`.
    public static func complete(_ tasks: [TaskItem], id: UUID, now: Date) -> [TaskItem] {
        patch(tasks, id: id, now: now) { task in
            task.state = .done
            task.doneAt = now
            task.reason = nil
        }
    }

    /// Make a task the active one, demoting the previous `.now` to `.next`.
    /// Ported from `start` (no normalize — the swap already leaves one `.now`).
    /// If `id` is not present the tasks are returned unchanged, so we never
    /// demote the active task without promoting a replacement. The promoted task
    /// also has any stale `doneAt`/`reason` cleared.
    public static func start(_ tasks: [TaskItem], id: UUID, now: Date) -> [TaskItem] {
        guard tasks.contains(where: { $0.id == id }) else { return tasks }
        return tasks.map { task -> TaskItem in
            if task.id == id {
                var copy = task
                copy.state = .now
                copy.doneAt = nil
                copy.reason = nil
                copy.updatedAt = now
                return copy
            }
            if task.state == .now {
                var copy = task
                copy.state = .next
                copy.updatedAt = now
                return copy
            }
            return task
        }
    }

    /// Mark a task blocked with a reason. Ported from `confirmBlock` → `patch`.
    public static func block(_ tasks: [TaskItem], id: UUID, reason: String, now: Date) -> [TaskItem] {
        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        return patch(tasks, id: id, now: now) { task in
            task.state = .blocked
            task.reason = trimmed.isEmpty ? "Sem motivo informado" : trimmed
        }
    }

    /// Return a blocked task to the queue. Ported from `unblock`.
    public static func unblock(_ tasks: [TaskItem], id: UUID, now: Date) -> [TaskItem] {
        patch(tasks, id: id, now: now) { task in
            task.state = .next
            task.reason = nil
        }
    }

    /// Add a new task. New tasks become `.now` only if nothing is active yet,
    /// otherwise they join the queue. Ported from `addTask`.
    /// Returns the tasks unchanged when the title is empty.
    public static func add(
        _ tasks: [TaskItem],
        title: String,
        details: String = "",
        project: String = "Geral",
        priority: Priority = .media,
        estimate: Int = 60,
        now: Date
    ) -> [TaskItem] {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return tasks }
        let hasActive = tasks.contains { $0.state == .now }
        let newTask = TaskItem(
            title: trimmed,
            details: details.trimmingCharacters(in: .whitespacesAndNewlines),
            project: project,
            priority: priority,
            estimate: estimate,
            seconds: 0,
            state: hasActive ? .next : .now,
            createdAt: now,
            updatedAt: now
        )
        return tasks + [newTask]
    }

    /// Remove a task entirely (it leaves the queue and the day report), then
    /// normalize so deleting the active task promotes the next one. Ported from
    /// the prototype's `confirmDel`.
    public static func delete(_ tasks: [TaskItem], id: UUID, now: Date) -> [TaskItem] {
        normalize(tasks.filter { $0.id != id }, now: now)
    }

    /// Advance the active task's timer by one second. Ported from the 1s interval
    /// in `componentDidMount`. `paused` freezes the increment but still returns
    /// the array unchanged so callers can keep a single code path.
    public static func tick(_ tasks: [TaskItem], paused: Bool, now: Date) -> [TaskItem] {
        guard !paused else { return tasks }
        return tasks.map { task -> TaskItem in
            guard task.state == .now else { return task }
            var copy = task
            copy.seconds += 1
            copy.updatedAt = now
            return copy
        }
    }
}
