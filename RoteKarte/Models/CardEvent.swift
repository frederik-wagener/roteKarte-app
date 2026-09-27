import Foundation
import RoteKarteCore
import SwiftData

@Model
final class CardEvent {
    #Index<CardEvent>([\.day], [\.timestamp])

    @Attribute(.unique) var id: UUID
    var kind: CardKind
    var timestamp: Date
    /// Beginn des Kalendertags (`startOfDay`) – für schnelle Tagesabfragen.
    var day: Date
    var reason: String?
    var child: Child?

    init(
        kind: CardKind,
        timestamp: Date = .now,
        reason: String? = nil,
        child: Child? = nil,
        calendar: Calendar = .current
    ) {
        self.id = UUID()
        self.kind = kind
        self.timestamp = timestamp
        self.day = calendar.startOfDay(for: timestamp)
        self.reason = reason
        self.child = child
    }

    /// Eingabe für die `RuleEngine`.
    var record: CardRecord {
        CardRecord(id: id, kind: kind, timestamp: timestamp)
    }
}
