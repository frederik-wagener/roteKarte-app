import Foundation
import Testing
@testable import RoteKarteCore

/// Baut eine Ereignisfolge mit aufsteigenden Zeitstempeln (eine Minute Abstand).
private func records(_ kinds: [CardKind]) -> [CardRecord] {
    let start = Date(timeIntervalSince1970: 1_790_000_000)
    return kinds.enumerated().map { index, kind in
        CardRecord(kind: kind, timestamp: start.addingTimeInterval(Double(index) * 60))
    }
}

private func day(_ kinds: CardKind...) -> [CardRecord] {
    records(kinds)
}

private func day(repeating kind: CardKind, count: Int) -> [CardRecord] {
    records(Array(repeating: kind, count: count))
}

@Suite("RuleEngine – Spielregeln")
struct RuleEngineTests {
    @Test("Leerer Tag: Belohnung erlaubt, Weg frei")
    func emptyDay() {
        let state = RuleEngine.evaluate([])
        #expect(state.rewardAllowed)
        #expect(state.activeYellowCount == 0)
        #expect(state.remainingYellowCards == 4)
        #expect(state.lossReason == nil)
    }

    @Test("0–3 gelbe Karten: Belohnung erlaubt", arguments: 0...3)
    func belowLimit(count: Int) {
        let state = RuleEngine.evaluate(day(repeating: .yellow, count: count))
        #expect(state.rewardAllowed)
        #expect(state.filledStations == count)
        #expect(state.remainingYellowCards == 4 - count)
    }

    @Test("4 gelbe Karten: Belohnung gestrichen")
    func fourYellow() {
        let records = day(.yellow, .yellow, .yellow, .yellow)
        let state = RuleEngine.evaluate(records)
        #expect(state.rewardLost)
        #expect(state.lossReason == .yellowLimit)
        #expect(state.lostByEvent == records[3].id)
        #expect(state.filledStations == 4)
        #expect(state.remainingYellowCards == 0)
    }

    @Test("1 rote Karte ohne gelbe: Belohnung gestrichen")
    func redOnly() {
        let records = day(.red)
        let state = RuleEngine.evaluate(records)
        #expect(state.rewardLost)
        #expect(state.lossReason == .redCard)
        #expect(state.lostByEvent == records[0].id)
        #expect(state.hasRedCard)
        #expect(state.filledStations == 0)
    }

    @Test("3 gelbe + gute Tat: 2 aktive, letzte gelbe gestrichen, Belohnung erlaubt")
    func goodDeedStrikesLastYellow() {
        let records = day(.yellow, .yellow, .yellow, .goodDeed)
        let state = RuleEngine.evaluate(records)
        #expect(state.rewardAllowed)
        #expect(state.activeYellowCards == [records[0].id, records[1].id])
        #expect(state.outcome(for: records[2].id) == .struckYellow(by: records[3].id))
        #expect(state.outcome(for: records[3].id) == .goodDeedStruck(yellow: records[2].id))
    }

    @Test("3 gelbe + gute Tat + 2 gelbe: 4 aktive, Belohnung gestrichen")
    func yellowAfterGoodDeed() {
        let records = day(.yellow, .yellow, .yellow, .goodDeed, .yellow, .yellow)
        let state = RuleEngine.evaluate(records)
        #expect(state.activeYellowCount == 4)
        #expect(state.lossReason == .yellowLimit)
        #expect(state.lostByEvent == records[5].id)
    }

    @Test("4 gelbe + gute Tat: kein Zurückverdienen")
    func noEarnBackAfterYellowLimit() {
        let records = day(.yellow, .yellow, .yellow, .yellow, .goodDeed)
        let state = RuleEngine.evaluate(records)
        #expect(state.rewardLost)
        #expect(state.activeYellowCount == 4)
        #expect(state.outcome(for: records[4].id) == .goodDeedRemembered)
        #expect(state.goodDeedCount == 1)
    }

    @Test("Rote + gute Tat: Belohnung bleibt gestrichen")
    func noEarnBackAfterRed() {
        let records = day(.yellow, .red, .goodDeed)
        let state = RuleEngine.evaluate(records)
        #expect(state.lossReason == .redCard)
        #expect(state.activeYellowCount == 1)
        #expect(state.outcome(for: records[2].id) == .goodDeedRemembered)
    }

    @Test("Gute Tat ohne gelbe Karte: kein Guthaben für spätere Karten")
    func goodDeedWithoutYellowGivesNoCredit() {
        let records = day(.goodDeed, .yellow, .yellow, .yellow, .yellow)
        let state = RuleEngine.evaluate(records)
        #expect(state.outcome(for: records[0].id) == .goodDeedRemembered)
        #expect(state.activeYellowCount == 4)
        #expect(state.rewardLost)
    }

    @Test("5. gelbe Karte: Roadmap bleibt bei 4, Überlauf +1")
    func overflow() {
        let records = day(.yellow, .yellow, .yellow, .yellow, .yellow)
        let state = RuleEngine.evaluate(records)
        #expect(state.filledStations == 4)
        #expect(state.overflowCount == 1)
        #expect(state.lostByEvent == records[3].id)
    }

    @Test("Rote Karte nach Verlust durch gelbe ändert den Verlustgrund nicht")
    func firstLossWins() {
        let records = day(.yellow, .yellow, .yellow, .yellow, .red)
        let state = RuleEngine.evaluate(records)
        #expect(state.lossReason == .yellowLimit)
        #expect(state.hasRedCard)
    }

    @Test("Reihenfolge ergibt sich aus dem Zeitstempel, nicht aus der Eingabe")
    func sortsByTimestamp() {
        let records = day(.yellow, .yellow, .goodDeed)
        let state = RuleEngine.evaluate(records.reversed())
        #expect(state.outcome(for: records[1].id) == .struckYellow(by: records[2].id))
        #expect(state.outcomes.map(\.id) == records.map(\.id))
    }

    @Test("Gleicher Zeitstempel: Eingabe-Reihenfolge entscheidet")
    func stableForEqualTimestamps() {
        let now = Date()
        let yellow = CardRecord(kind: .yellow, timestamp: now)
        let deed = CardRecord(kind: .goodDeed, timestamp: now)
        #expect(RuleEngine.evaluate([yellow, deed]).activeYellowCount == 0)
        #expect(RuleEngine.evaluate([deed, yellow]).activeYellowCount == 1)
    }

    @Test("Eigenes Limit wird beachtet", arguments: Rules.yellowLimitRange)
    func customLimit(limit: Int) {
        let rules = Rules(yellowLimit: limit)
        let justBelow = RuleEngine.evaluate(day(repeating: .yellow, count: limit - 1), rules: rules)
        let atLimit = RuleEngine.evaluate(day(repeating: .yellow, count: limit), rules: rules)
        #expect(justBelow.rewardAllowed)
        #expect(atLimit.rewardLost)
    }
}

@Suite("RuleEngine – Tageswechsel")
struct DayBoundaryTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar
    }()

    func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute))!
    }

    @Test("Ereignisse von gestern beeinflussen heute nicht")
    func yesterdayIsIgnored() {
        let records = [
            CardRecord(kind: .yellow, timestamp: date(26, 9)),
            CardRecord(kind: .yellow, timestamp: date(26, 10)),
            CardRecord(kind: .red, timestamp: date(26, 23, 59)),
            CardRecord(kind: .yellow, timestamp: date(27, 0, 1)),
        ]
        let today = RuleEngine.evaluate(records, on: date(27, 12), calendar: calendar)
        #expect(today.rewardAllowed)
        #expect(today.activeYellowCards == [records[3].id])

        let yesterday = RuleEngine.evaluate(records, on: date(26, 12), calendar: calendar)
        #expect(yesterday.lossReason == .redCard)
    }
}

@Suite("Rules")
struct RulesTests {
    @Test("Limit wird auf 3–6 begrenzt")
    func clamping() {
        #expect(Rules(yellowLimit: 1).yellowLimit == 3)
        #expect(Rules(yellowLimit: 10).yellowLimit == 6)
        var rules = Rules.standard
        rules.yellowLimit = 0
        #expect(rules.yellowLimit == 3)
    }

    @Test("Dekodieren begrenzt ebenfalls")
    func decodingClamps() throws {
        let rules = try JSONDecoder().decode(Rules.self, from: Data(#"{"yellowLimit":99}"#.utf8))
        #expect(rules.yellowLimit == 6)
    }
}

@Suite("StatusText")
struct StatusTextTests {
    @Test func texts() {
        func text(_ kinds: CardKind...) -> String {
            StatusText.make(for: RuleEngine.evaluate(records(kinds)), rewardName: "Eis")
        }
        #expect(text() == "Super! Heute gibt es Eis.")
        #expect(text(.yellow, .yellow) == "Noch 2 gelbe Karten, dann ist Eis gestrichen.")
        #expect(text(.yellow, .yellow, .yellow) == "Achtung! Noch 1 gelbe Karte, dann ist Eis gestrichen.")
        #expect(text(.yellow, .yellow, .yellow, .yellow) == "4 gelbe Karten – Eis ist für heute gestrichen.")
        #expect(text(.red) == "Rote Karte! Eis ist für heute gestrichen.")
    }
}
