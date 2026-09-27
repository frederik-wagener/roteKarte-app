/// Art eines Ereignisses im Tagesverlauf eines Kindes.
public enum CardKind: String, Codable, CaseIterable, Sendable {
    /// Gelbe Karte – belegt eine Station auf der Roadmap.
    case yellow
    /// Rote Karte – Belohnung ist sofort für den Tag gestrichen.
    case red
    /// Gute Tat – streicht die zuletzt vergebene gelbe Karte (solange die Belohnung nicht verloren ist).
    case goodDeed
}
