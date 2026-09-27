import Foundation
import RoteKarteCore
import SwiftData

@Model
final class Child {
    @Attribute(.unique) var id: UUID
    var name: String
    /// Emoji-Avatar, z. B. "🧒".
    var avatar: String
    var colorHex: String
    /// Name der Belohnung, z. B. "Eis".
    var rewardName: String
    /// Emoji der Belohnung, z. B. "🍦".
    var rewardEmoji: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CardEvent.child)
    var events: [CardEvent] = []

    init(
        name: String,
        avatar: String = "🧒",
        colorHex: String = "#FF8A3D",
        rewardName: String = "Eis",
        rewardEmoji: String = "🍦",
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.name = name
        self.avatar = avatar
        self.colorHex = colorHex
        self.rewardName = rewardName
        self.rewardEmoji = rewardEmoji
        self.createdAt = createdAt
    }

    /// Ereignisse des Kalendertags von `date`, chronologisch sortiert.
    func dayEvents(for date: Date, calendar: Calendar = .current) -> [CardEvent] {
        let day = calendar.startOfDay(for: date)
        return events
            .filter { $0.day == day }
            .sorted { $0.timestamp < $1.timestamp }
    }
}
