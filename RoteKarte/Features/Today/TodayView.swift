import Combine
import RoteKarteCore
import SwiftData
import SwiftUI

/// Hauptscreen „Heute": Roadmap, Status-Text und Aktionen.
/// Phase 1: noch ohne Animationen und ohne PIN-Schutz.
struct TodayView: View {
    let child: Child

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("yellowLimit") private var yellowLimit = Rules.standard.yellowLimit
    @State private var today = Date.now

    private var rules: Rules { Rules(yellowLimit: yellowLimit) }
    private var todaysEvents: [CardEvent] { child.dayEvents(for: today) }
    private var state: DayState { RuleEngine.evaluate(todaysEvents.map(\.record), rules: rules) }

    var body: some View {
        let state = self.state

        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    RoadmapView(state: state, rewardEmoji: child.rewardEmoji, accent: Color(hex: child.colorHex))

                    Text(StatusText.make(for: state, rewardName: child.rewardName))
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    ActionButtons(rewardLost: state.rewardLost, add: add)

                    EventLogView(events: todaysEvents, state: state, delete: delete)
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 16)
            }
            .navigationTitle("\(child.avatar) \(child.name)")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            today = .now
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { today = .now }
        }
    }

    private func add(_ kind: CardKind) {
        today = .now
        let event = CardEvent(kind: kind, timestamp: today, child: child)
        modelContext.insert(event)
    }

    private func delete(_ event: CardEvent) {
        modelContext.delete(event)
    }
}

// MARK: - Roadmap

/// Start → Stationen → Belohnung. Phase 2 ersetzt dies durch den geschwungenen, animierten Weg.
struct RoadmapView: View {
    let state: DayState
    let rewardEmoji: String
    let accent: Color

    var body: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(accent)
                .frame(width: 18, height: 18)
                .accessibilityLabel("Start")

            ForEach(0..<state.rules.yellowLimit, id: \.self) { index in
                PathSegment()
                StationView(number: index + 1, filled: index < state.filledStations)
            }

            PathSegment()
            RewardGoalView(emoji: rewardEmoji, lost: state.rewardLost)
        }
        .overlay(alignment: .topTrailing) {
            if state.overflowCount > 0 {
                Text("+\(state.overflowCount)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.yellow, in: .capsule)
                    .offset(x: 4, y: -18)
                    .accessibilityLabel("\(state.overflowCount) zusätzliche gelbe Karten")
            }
        }
    }
}

private struct PathSegment: View {
    var body: some View {
        Capsule()
            .fill(.secondary.opacity(0.35))
            .frame(height: 4)
            .frame(minWidth: 6, maxWidth: .infinity)
    }
}

struct StationView: View {
    let number: Int
    let filled: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 6)
        ZStack {
            if filled {
                shape.fill(.yellow)
                    .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
            } else {
                shape.strokeBorder(.secondary, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
            }
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(filled ? .black : .secondary)
        }
        .frame(width: 34, height: 46)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(filled ? "Station \(number): gelbe Karte" : "Station \(number): frei")
    }
}

struct RewardGoalView: View {
    let emoji: String
    let lost: Bool

    var body: some View {
        Text(emoji)
            .font(.system(size: 52))
            .opacity(lost ? 0.45 : 1)
            .overlay {
                if lost {
                    Capsule()
                        .fill(.red)
                        .frame(width: 70, height: 6)
                        .rotationEffect(.degrees(-35))
                }
            }
            .accessibilityLabel(lost ? "Belohnung gestrichen" : "Belohnung")
    }
}

// MARK: - Aktionen

private struct ActionButtons: View {
    let rewardLost: Bool
    let add: (CardKind) -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button { add(.yellow) } label: {
                    Label("Gelbe Karte", systemImage: "rectangle.portrait.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(.yellow)
                .foregroundStyle(.black)

                Button { add(.red) } label: {
                    Label("Rote Karte", systemImage: "rectangle.portrait.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(.red)
            }

            Button { add(.goodDeed) } label: {
                Label(rewardLost ? "Gute Tat merken" : "Gute Tat", systemImage: "star.fill")
                    .frame(maxWidth: .infinity)
            }
            .tint(.green)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .font(.headline)
    }
}

// MARK: - Tagesverlauf

private struct EventLogView: View {
    let events: [CardEvent]
    let state: DayState
    let delete: (CardEvent) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Heute")
                .font(.headline)

            if events.isEmpty {
                Text("Noch keine Ereignisse.")
                    .foregroundStyle(.secondary)
            }

            ForEach(events.reversed()) { event in
                HStack {
                    Text(icon(for: event.kind))
                    VStack(alignment: .leading) {
                        Text(title(for: event))
                            .strikethrough(isStruck(event))
                        Text(event.timestamp, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(10)
                .background(.background.secondary, in: .rect(cornerRadius: 12))
                .contextMenu {
                    Button("Löschen", systemImage: "trash", role: .destructive) { delete(event) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func icon(for kind: CardKind) -> String {
        switch kind {
        case .yellow: "🟨"
        case .red: "🟥"
        case .goodDeed: "⭐"
        }
    }

    private func isStruck(_ event: CardEvent) -> Bool {
        if case .struckYellow = state.outcome(for: event.id) { true } else { false }
    }

    private func title(for event: CardEvent) -> String {
        switch state.outcome(for: event.id) {
        case .activeYellow: "Gelbe Karte"
        case .struckYellow: "Gelbe Karte (gestrichen)"
        case .red: "Rote Karte"
        case .goodDeedStruck: "Gute Tat – gelbe Karte gestrichen"
        case .goodDeedRemembered, nil: "Gute Tat"
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Child.self, CardEvent.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let child = Child(name: "Mia", avatar: "👧")
    container.mainContext.insert(child)
    for kind in [CardKind.yellow, .yellow, .goodDeed, .yellow] {
        container.mainContext.insert(CardEvent(kind: kind, child: child))
    }
    return TodayView(child: child)
        .modelContainer(container)
}
