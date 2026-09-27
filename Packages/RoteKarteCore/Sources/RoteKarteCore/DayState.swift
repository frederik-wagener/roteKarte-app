import Foundation

/// Ergebnis der Regelauswertung für einen Tag.
public struct DayState: Hashable, Sendable {
    /// Grund, warum die Belohnung verloren ging.
    public enum LossReason: Hashable, Sendable {
        /// Das Gelbe-Karten-Limit wurde erreicht.
        case yellowLimit
        /// Es gab eine rote Karte.
        case redCard
    }

    /// Wirkung eines einzelnen Ereignisses nach Auswertung aller Regeln.
    public enum Outcome: Hashable, Sendable {
        /// Gelbe Karte liegt auf der Roadmap.
        case activeYellow
        /// Gelbe Karte wurde durch die gute Tat mit dieser ID gestrichen.
        case struckYellow(by: UUID)
        /// Rote Karte.
        case red
        /// Gute Tat hat die gelbe Karte mit dieser ID gestrichen.
        case goodDeedStruck(yellow: UUID)
        /// Gute Tat wurde nur gemerkt (keine gelbe Karte vorhanden oder Tag gesperrt).
        case goodDeedRemembered
    }

    public struct EventOutcome: Hashable, Sendable {
        public let id: UUID
        public let outcome: Outcome
    }

    public let rules: Rules
    /// Aktive (nicht gestrichene) gelbe Karten in Vergabe-Reihenfolge.
    public let activeYellowCards: [UUID]
    /// Wirkung jedes Ereignisses, in chronologischer Reihenfolge.
    public let outcomes: [EventOutcome]
    /// Gesetzt, sobald die Belohnung verloren ist – bleibt für den Rest des Tages bestehen.
    public let lossReason: LossReason?
    /// Ereignis, das den Verlust ausgelöst hat.
    public let lostByEvent: UUID?

    public var activeYellowCount: Int { activeYellowCards.count }
    public var hasRedCard: Bool { outcomes.contains { $0.outcome == .red } }
    public var rewardLost: Bool { lossReason != nil }
    public var rewardAllowed: Bool { !rewardLost }

    /// Belegte Stationen auf der Roadmap (höchstens `rules.yellowLimit`).
    public var filledStations: Int { min(activeYellowCount, rules.yellowLimit) }
    /// Gelbe Karten über dem Limit (Überlauf-Anzeige „+n").
    public var overflowCount: Int { max(0, activeYellowCount - rules.yellowLimit) }
    /// Wie viele gelbe Karten noch fehlen, bis die Belohnung verloren ist (0, wenn schon verloren).
    public var remainingYellowCards: Int { rewardLost ? 0 : rules.yellowLimit - activeYellowCount }
    /// Anzahl aller guten Taten des Tages (Sternensammlung).
    public var goodDeedCount: Int {
        outcomes.count { entry in
            switch entry.outcome {
            case .goodDeedStruck, .goodDeedRemembered: true
            default: false
            }
        }
    }

    public func outcome(for id: UUID) -> Outcome? {
        outcomes.first { $0.id == id }?.outcome
    }
}
