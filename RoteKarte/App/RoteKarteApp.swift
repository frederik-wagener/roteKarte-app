import SwiftData
import SwiftUI

@main
struct RoteKarteApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Child.self, CardEvent.self])
    }
}

/// Zeigt den Heute-Screen für das erste Kind.
/// Phase 1: Gibt es noch kein Kind, wird ein Standardprofil angelegt (Onboarding folgt in Phase 3).
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Child.createdAt) private var children: [Child]

    var body: some View {
        Group {
            if let child = children.first {
                TodayView(child: child)
            } else {
                ProgressView()
            }
        }
        .task {
            if children.isEmpty {
                modelContext.insert(Child(name: "Mein Kind"))
            }
        }
    }
}
