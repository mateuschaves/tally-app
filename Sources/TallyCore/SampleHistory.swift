import Foundation

/// Sample historical days for the "Resumo do dia" back-navigation (offsets 1…7),
/// ported verbatim from the prototype's `histFor`. Weekends are empty.
///
/// This reproduces the design's report history exactly. A real implementation
/// would instead aggregate persisted `.done` tasks by `doneAt`; `HistoryProviding`
/// is the seam for swapping this out without touching `ReportBuilder`.
public enum SampleHistory {

    public struct Done: Equatable, Sendable {
        public let title: String
        public let project: String
        public let seconds: Int
        public init(_ title: String, _ project: String, _ seconds: Int) {
            self.title = title; self.project = project; self.seconds = seconds
        }
    }

    public struct Blocked: Equatable, Sendable {
        public let title: String
        public let reason: String
        public init(_ title: String, _ reason: String) {
            self.title = title; self.reason = reason
        }
    }

    public struct Plan: Equatable, Sendable {
        public let title: String
        public let estimate: Int
        public init(_ title: String, _ estimate: Int) {
            self.title = title; self.estimate = estimate
        }
    }

    public struct Day: Equatable, Sendable {
        public let date: Date
        public let isEmpty: Bool
        public let done: [Done]
        public let blocked: [Blocked]
        public let plan: [Plan]
    }

    /// The 7 rotating day templates from the prototype.
    private static let templates: [(done: [Done], blocked: [Blocked], plan: [Plan])] = [
        (
            done: [Done("Especificar API de cupons", "Backend", 5460),
                   Done("Revisar tokens de cor no Figma", "Design", 3120),
                   Done("Planning da sprint", "Reuniões", 3600),
                   Done("Triagem de bugs da semana", "Geral", 1440)],
            blocked: [Blocked("Migração do banco de staging", "Aguardando janela de manutenção")],
            plan: [Plan("Implementar API de cupons", 120), Plan("Refinar fluxo de onboarding", 60)]
        ),
        (
            done: [Done("Implementar endpoint de reembolso", "Backend", 7260),
                   Done("Protótipo do fluxo de convites", "Design", 4380),
                   Done("Daily standup", "Reuniões", 900)],
            blocked: [],
            plan: [Plan("Testes do endpoint de reembolso", 45), Plan("Handoff do fluxo de convites", 30)]
        ),
        (
            done: [Done("Corrigir memory leak no worker", "Backend", 6540),
                   Done("1:1 com a liderança", "Reuniões", 1800),
                   Done("Documentar API de webhooks", "Geral", 2640)],
            blocked: [Blocked("Deploy do serviço de e-mails", "Dependência de terceiros")],
            plan: [Plan("Monitorar worker em produção", 30), Plan("Revisar PRs pendentes", 45)]
        ),
        (
            done: [Done("Testes de integração do checkout", "Backend", 5100),
                   Done("Ajustes de acessibilidade no modal", "Design", 2460),
                   Done("Refinamento do backlog", "Reuniões", 2700)],
            blocked: [],
            plan: [Plan("Corrigir memory leak no worker", 90), Plan("Documentar API de webhooks", 45)]
        ),
        (
            done: [Done("Migrar autenticação para tokens curtos", "Backend", 8040),
                   Done("Ilustrações do estado vazio", "Design", 3300),
                   Done("Retro da sprint", "Reuniões", 2700)],
            blocked: [Blocked("Atualização do SDK de pagamento", "Sem acesso ou permissão")],
            plan: [Plan("Testes de integração do checkout", 60), Plan("Preparar demo interna", 30)]
        ),
        (
            done: [Done("Revisão de código do time", "Backend", 4920),
                   Done("Auditoria de espaçamentos", "Design", 2820),
                   Done("Sync com produto", "Reuniões", 1980)],
            blocked: [],
            plan: [Plan("Migrar autenticação para tokens curtos", 120)]
        ),
        (
            done: [Done("Configurar alertas de erro", "Backend", 4260),
                   Done("Benchmark de concorrentes", "Geral", 3540),
                   Done("Kickoff do projeto de convites", "Reuniões", 2820)],
            blocked: [Blocked("Acesso ao painel de métricas", "Sem acesso ou permissão")],
            plan: [Plan("Revisão de código do time", 60), Plan("Auditoria de espaçamentos", 45)]
        )
    ]

    /// The day `offset` days before `now` (1 = yesterday). Ported from `histFor`:
    /// anchor at noon, subtract `offset` days; weekend → empty; else template
    /// `(offset - 1) % 7`. `offset` is clamped to `>= 1` so this public API never
    /// indexes with a negative value.
    public static func day(offset: Int, now: Date) -> Day {
        let offset = max(1, offset)
        let calendar = PtBrDates.calendar
        let comps = calendar.dateComponents([.year, .month, .day], from: now)
        let noon = calendar.date(from: DateComponents(
            year: comps.year, month: comps.month, day: comps.day, hour: 12))!
        let date = calendar.date(byAdding: .day, value: -offset, to: noon)!

        if PtBrDates.isWeekend(date) {
            return Day(date: date, isEmpty: true, done: [], blocked: [], plan: [])
        }
        let template = templates[(offset - 1) % templates.count]
        return Day(date: date, isEmpty: false, done: template.done, blocked: template.blocked, plan: template.plan)
    }
}

/// Seam for supplying report history. `SampleHistory` is the default (matches the
/// design); a future implementation can aggregate real persisted completions.
public protocol HistoryProviding: Sendable {
    func day(offset: Int, now: Date) -> SampleHistory.Day
}

public struct SampleHistoryProvider: HistoryProviding {
    public init() {}
    public func day(offset: Int, now: Date) -> SampleHistory.Day {
        SampleHistory.day(offset: offset, now: now)
    }
}
