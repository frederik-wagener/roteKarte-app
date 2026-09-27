/// Einstellbare Spielregeln.
public struct Rules: Codable, Hashable, Sendable {
    /// Erlaubter Bereich für das Gelbe-Karten-Limit.
    public static let yellowLimitRange = 3...6

    /// Standardregeln: 4 gelbe Karten bis zum Verlust der Belohnung.
    public static let standard = Rules(yellowLimit: 4)

    /// Anzahl gelber Karten, ab der die Belohnung für den Tag gestrichen ist.
    public var yellowLimit: Int {
        didSet { yellowLimit = Self.clamped(yellowLimit) }
    }

    public init(yellowLimit: Int = 4) {
        self.yellowLimit = Self.clamped(yellowLimit)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(yellowLimit: try container.decode(Int.self, forKey: .yellowLimit))
    }

    private static func clamped(_ value: Int) -> Int {
        min(max(value, yellowLimitRange.lowerBound), yellowLimitRange.upperBound)
    }
}
