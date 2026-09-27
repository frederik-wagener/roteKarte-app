import Foundation

/// Unveränderliche Sicht auf ein gespeichertes Ereignis – Eingabe für die `RuleEngine`.
///
/// Die App bildet ihre SwiftData-Modelle auf diesen Typ ab, damit die Regeln
/// ohne Datenbank getestet werden können.
public struct CardRecord: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let kind: CardKind
    public let timestamp: Date

    public init(id: UUID = UUID(), kind: CardKind, timestamp: Date) {
        self.id = id
        self.kind = kind
        self.timestamp = timestamp
    }
}
