import Foundation

/// Wertet die Ereignisse eines Tages nach den Spielregeln aus.
///
/// Regeln (siehe PLAN.md, Abschnitt 1):
/// - Gelbe Karte: belegt die nächste Station. Beim Erreichen des Limits ist die Belohnung verloren.
/// - Rote Karte: Belohnung sofort verloren.
/// - Gute Tat: streicht die zuletzt vergebene aktive gelbe Karte – aber nur, solange die
///   Belohnung noch nicht verloren ist. Danach wird sie nur gemerkt (kein Zurückverdienen).
/// - Gute Taten bauen kein Guthaben für spätere Karten auf.
public enum RuleEngine {
    /// Wertet die übergebenen Ereignisse aus. Die Ereignisse sollten zu genau einem Tag gehören;
    /// siehe `evaluate(_:on:rules:calendar:)` zum Filtern.
    public static func evaluate(_ records: [CardRecord], rules: Rules = .standard) -> DayState {
        // Stabil nach Zeit sortieren: bei gleichem Zeitstempel zählt die Eingabe-Reihenfolge.
        let ordered = records.enumerated()
            .sorted { ($0.element.timestamp, $0.offset) < ($1.element.timestamp, $1.offset) }
            .map(\.element)

        var activeYellow: [UUID] = []
        var outcomes: [UUID: DayState.Outcome] = [:]
        var lossReason: DayState.LossReason?
        var lostBy: UUID?

        for record in ordered {
            switch record.kind {
            case .yellow:
                activeYellow.append(record.id)
                outcomes[record.id] = .activeYellow
                if lossReason == nil, activeYellow.count >= rules.yellowLimit {
                    lossReason = .yellowLimit
                    lostBy = record.id
                }

            case .red:
                outcomes[record.id] = .red
                if lossReason == nil {
                    lossReason = .redCard
                    lostBy = record.id
                }

            case .goodDeed:
                if lossReason == nil, let yellow = activeYellow.popLast() {
                    outcomes[yellow] = .struckYellow(by: record.id)
                    outcomes[record.id] = .goodDeedStruck(yellow: yellow)
                } else {
                    outcomes[record.id] = .goodDeedRemembered
                }
            }
        }

        return DayState(
            rules: rules,
            activeYellowCards: activeYellow,
            outcomes: ordered.map { DayState.EventOutcome(id: $0.id, outcome: outcomes[$0.id]!) },
            lossReason: lossReason,
            lostByEvent: lostBy
        )
    }

    /// Wertet nur die Ereignisse aus, die am Kalendertag von `day` liegen.
    public static func evaluate(
        _ records: [CardRecord],
        on day: Date,
        rules: Rules = .standard,
        calendar: Calendar = .current
    ) -> DayState {
        evaluate(records.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }, rules: rules)
    }
}
