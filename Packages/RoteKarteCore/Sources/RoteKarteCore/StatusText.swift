/// Kindgerechter Status-Text unter der Roadmap.
public enum StatusText {
    public static func make(for state: DayState, rewardName: String) -> String {
        switch state.lossReason {
        case .redCard:
            return "Rote Karte! \(rewardName) ist für heute gestrichen."
        case .yellowLimit:
            return "\(state.rules.yellowLimit) gelbe Karten – \(rewardName) ist für heute gestrichen."
        case nil:
            break
        }

        switch state.remainingYellowCards {
        case state.rules.yellowLimit:
            return "Super! Heute gibt es \(rewardName)."
        case 1:
            return "Achtung! Noch 1 gelbe Karte, dann ist \(rewardName) gestrichen."
        case let remaining:
            return "Noch \(remaining) gelbe Karten, dann ist \(rewardName) gestrichen."
        }
    }
}
