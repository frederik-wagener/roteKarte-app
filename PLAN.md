# Rote Karte – App-Plan

Eine iOS-App für Kinder (und Eltern), die das Verhalten des Tages mit gelben und roten Karten sichtbar macht – wie beim Fußball. Im Mittelpunkt steht eine animierte **Roadmap**: vier gelbe Karten-Stationen führen zu einer Belohnung am Ende des Weges (Standard: Eis 🍦, pro Kind frei wählbar). Ist der Weg voll (oder gibt es eine rote Karte), wird die Belohnung durchgestrichen.

**Getroffene Entscheidungen**

| Frage | Entscheidung |
|---|---|
| Kann eine gute Tat das verlorene Eis zurückbringen? | **Nein.** Ist das Eis weg, bleibt es für den Tag weg. |
| Wie viele Geräte? | **Ein Gerät**, alle Daten lokal. Kein iCloud-Sync. |
| Mindest-iOS-Version? | **iOS 26** – volle Nutzung von Liquid Glass und aller aktuellen SwiftUI-APIs. |
| Wer bedient die App? | **Das Kind schaut, die Eltern handeln mit PIN.** |
| Nur Eis als Belohnung? | **Pro Kind wählbar** (Name + Emoji, Standard „Eis 🍦“). |

---

## 1. Spielregeln (Domänenlogik)

| Ereignis | Wirkung |
|---|---|
| **Gelbe Karte** | Belegt die nächste freie Station auf der Roadmap (max. 4). |
| **4. gelbe Karte** | Belohnung für heute gestrichen. |
| **Rote Karte** | Belohnung für heute sofort gestrichen – unabhängig von der Anzahl gelber Karten. |
| **Gute Tat** | Streicht die zuletzt vergebene gelbe Karte des Tages – **nur solange die Belohnung noch nicht verloren ist**. |
| **Tageswechsel (00:00 Uhr)** | Alles wird zurückgesetzt, jeder Tag startet mit freiem Weg und Belohnung. |

Detailregeln:

- Eine gute Tat kann **nur gelbe** Karten streichen, keine rote.
- **Kein Zurückverdienen:** Sobald die Belohnung verloren ist (4. gelbe Karte oder rote Karte), ist der Tag „gesperrt“. Weitere gute Taten werden gespeichert (⭐ im Tagesverlauf), ändern aber nichts mehr an der Roadmap.
- Gute Taten ohne vorhandene gelbe Karte werden ebenfalls nur gespeichert.
- Weitere Karten nach dem Verlust werden gespeichert (Verlauf), die Roadmap zeigt eine Überlauf-Markierung („+1“).
- Die Grenze von 4 gelben Karten kann in den Einstellungen angepasst werden (3–6).

Die gesamte Regel-Logik liegt in einer reinen, testbaren Funktion:

```swift
struct DayState {
    var yellowCount: Int      // aktive (nicht gestrichene) gelbe Karten
    var hasRedCard: Bool
    var rewardLost: Bool      // einmal true → bleibt für den Tag true
}

/// Geht die Ereignisse des Tages chronologisch durch:
/// - yellow:   yellowCount += 1; bei yellowCount >= limit → rewardLost = true
/// - red:      hasRedCard = true, rewardLost = true
/// - goodDeed: nur wenn !rewardLost && yellowCount > 0 → yellowCount -= 1
func evaluate(events: [CardEvent], rules: Rules) -> DayState
```

---

## 2. Zielgruppe & Bedienkonzept

- **Kinder** schauen sich die Roadmap an – groß, bunt, ohne viel Text. Ohne PIN ist nur Anschauen möglich (Roadmap, Kind wechseln, Verlauf).
- **Eltern** vergeben Karten und gute Taten – jede Aktion erfordert den **Eltern-PIN** (4 Ziffern).
- Der PIN wird beim ersten Start im Onboarding festgelegt. Nach Eingabe bleibt der Eltern-Modus 60 Sekunden entsperrt (für mehrere Aktionen hintereinander), dann sperrt er sich automatisch.
- PIN vergessen → Zurücksetzen über eine Rechenaufgabe für Erwachsene (z. B. „17 × 23“) oder Face ID / Touch ID des Geräts.
- Einstellungen sind ebenfalls PIN-geschützt.
- **Mehrere Kinder** möglich (Profil mit Name, Farbe, Avatar-Emoji, eigene Belohnung), Wechsel per Wisch oder Avatar-Leiste oben.
- Alles läuft auf **einem Gerät** (z. B. dem Familien-iPad oder Eltern-iPhone).

---

## 3. Screens

### 3.1 Hauptscreen – "Heute" (Roadmap)
```
 [ 🧒 Mia ▾ ]                          [⚙︎]

   ●────🟨────🟨────◻︎────◻︎────🍦
   Start  1     2     3     4    Eis

         „Noch 2 Karten bis zum Eis-Verbot"

   [ 🟨 Gelbe Karte ] [ 🟥 Rote Karte ]     🔒
            [ ⭐ Gute Tat ]
```
- Geschwungener Weg (Pfad als `Path`/Bezier-Kurve) mit 4 Stationen + Belohnungs-Ziel.
- Leere Station = gestrichelter Rahmen; belegt = gelbe Karte, die mit Animation "einfliegt".
- Ziel: die Belohnung des Kindes (Emoji groß, fröhlich wackelnd) → bei Verlust: rotes Durchstreichen + Verlust-Animation (beim Eis: „schmilzt“, bei anderen Belohnungen: zerbröselt/verblasst).
- Aktions-Buttons sind mit Schloss 🔒 markiert; Tippen öffnet zuerst die PIN-Eingabe.
- Ist die Belohnung verloren, wird der „Gute Tat“-Button zu „⭐ Gute Tat merken“ (nur Verlauf).
- Kleine Figur (Avatar des Kindes) steht auf der aktuellen Station und hüpft weiter.
- Unter der Roadmap: kindgerechter Status-Text.

### 3.2 Karte vergeben (Sheet)
- Auswahl **Gelb** / **Rot** als große Karten zum Antippen.
- Optional: Grund eingeben oder aus Vorschlägen wählen (z. B. „Hauen", „Nicht zuhören", „Schreien") – Vorschläge in den Einstellungen pflegbar.
- Bestätigen → Sheet schließt, Animation auf der Roadmap startet.

### 3.3 Gute Tat (Sheet)
- Optional Grund (z. B. „Aufgeräumt", „Geteilt", „Geholfen").
- Bestätigen → Stern fliegt auf die letzte gelbe Karte, diese wird durchgestrichen und fällt vom Weg.
- Ist die Belohnung schon verloren: Stern wird nur im Tagesverlauf gesammelt (Hinweis: „Toll! Das zählt morgen für einen guten Start.“ – rein motivierend, ohne Regelwirkung).

### 3.4 Verlauf / Kalender
- Monatskalender pro Kind: jeder Tag mit Belohnungs-Emoji (erhalten) oder durchgestrichenem Emoji.
- Tipp auf einen Tag → Timeline aller Ereignisse (Uhrzeit, Kartentyp, Grund, gute Taten ⭐).
- Kleine Statistik: „Belohnungs-Tage in Folge" (Streak) und gesammelte Sterne als Motivation.

### 3.5 Einstellungen
- Kinder verwalten (anlegen, umbenennen, Avatar, Farbe, löschen)
- **Belohnung pro Kind:** Name + Emoji aus Vorschlägen (🍦 Eis, 📺 Fernsehen, 🍫 Süßes, 🎮 Spielzeit, 📖 Gute-Nacht-Geschichte, 🛝 Spielplatz) oder frei wählbar
- Eltern-PIN ändern, Face ID / Touch ID als Alternative
- Gelbe-Karten-Limit (Standard 4)
- Grund-Vorschläge bearbeiten
- Sounds & Haptik an/aus

---

## 4. Animationen (Herzstück)

| Moment | Animation |
|---|---|
| Gelbe Karte | Karte erscheint groß in der Mitte, dreht sich (3D-Flip, `rotation3DEffect`), fliegt per `matchedGeometryEffect` auf ihre Station, kleiner Aufprall (Spring) + Haptik `.warning`. Figur hüpft eine Station weiter. |
| 4. gelbe Karte | Wie oben, danach wandert die Figur zur Belohnung, roter Strich wird darüber „gezeichnet" (`trim` auf einem Path), Eis schmilzt (Scale-Y + Tropfen) bzw. andere Belohnung verblasst, Haptik `.error`. Weg wird ausgegraut („gesperrt“). |
| Rote Karte | Bildschirm blitzt kurz rot, rote Karte wird wie ein Schiri „hochgehalten" (Karte kommt von unten mit Pfeifen-Sound), dann fliegt sie direkt auf die Belohnung → Durchstreichen. |
| Gute Tat | Stern mit Partikel-Glitzer (Canvas/`TimelineView` oder `SpriteKit`-Emitter), fliegt auf die letzte gelbe Karte; Karte wird durchgestrichen, kippt und fällt vom Weg. Figur geht eine Station zurück. |
| Gute Tat (Tag gesperrt) | Stern fliegt in eine kleine „Sternensammlung“ oben rechts – keine Änderung am Weg. |
| PIN entsperrt | Schloss springt auf, Buttons leuchten kurz auf. |
| Belohnung erhalten am Abend | Idle-Animation: Belohnung wackelt leicht, Konfetti beim App-Öffnen, wenn der Vortag erfolgreich war. |
| Tageswechsel | Weg wird „weggefegt" und neu gezeichnet. |

Umsetzung: SwiftUI-Animationen (`withAnimation(.spring)`, `PhaseAnimator`, `KeyframeAnimator`), `Canvas` für Partikel, `sensoryFeedback` für Haptik, animierte SF Symbols (`symbolEffect`) für Schloss, Stern & Buttons, `MeshGradient` für einen lebendigen Himmel-Hintergrund hinter der Roadmap. Optional später Lottie für aufwendige Figuren-Animationen.

Barrierefreiheit: bei „Bewegung reduzieren" (`accessibilityReduceMotion`) einfache Überblendungen statt Flug-Animationen.

---

## 5. Technik & Architektur

- **Plattform:** iOS 26+, iPhone & iPad (Hochformat, iPad auch Querformat); gebaut mit Xcode 26 / Swift 6
- **Design:** Liquid Glass – Aktions-Buttons, PIN-Pad und Kinder-Leiste als Glas-Elemente (`glassEffect`, `GlassEffectContainer`), Tab-Bar und Sheets im System-Stil von iOS 26
- **Moderne APIs ohne Rücksicht auf ältere Versionen:** SwiftData mit `#Index` (schnelle Tagesabfragen), Swift Concurrency im strikten Swift-6-Modus
- **UI:** SwiftUI
- **Persistenz:** SwiftData, ausschließlich lokal auf einem Gerät (kein Sync, kein Server)
- **PIN:** als Hash in der Keychain; Face ID / Touch ID über `LocalAuthentication`
- **Architektur:** MVVM-light mit `@Observable`-ViewModels; Regel-Logik als reiner Service (`RuleEngine`)
- **Keine Accounts, kein Tracking, keine Werbung** (Kinder-App → App-Store-Kategorie „Kids"-Anforderungen beachten)

### Datenmodell (SwiftData)

```swift
@Model class Child {
    var id: UUID
    var name: String
    var avatar: String        // Emoji
    var colorHex: String
    var rewardName: String    // Standard: "Eis"
    var rewardEmoji: String   // Standard: "🍦"
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var events: [CardEvent]
}

@Model class CardEvent {
    var id: UUID
    var kind: CardKind        // .yellow, .red, .goodDeed
    var timestamp: Date
    var day: Date             // Kalendertag (startOfDay) – für schnelle Abfragen
    var reason: String?
    var child: Child?
}

enum CardKind: String, Codable { case yellow, red, goodDeed }

struct Rules: Codable {       // in UserDefaults / AppStorage
    var yellowLimit = 4
}
```

Gespeichert werden nur die Ereignisse selbst. Welche gelbe Karte durch welche gute Tat gestrichen ist, berechnet die `RuleEngine` bei jeder Auswertung aus der chronologischen Reihenfolge – so kann der Zustand nie inkonsistent werden, und „Rückgängig" ist einfach das Löschen eines Ereignisses.

Die Spielregeln liegen im Swift-Paket `Packages/RoteKarteCore` (ohne SwiftUI/SwiftData) und werden dort getestet.

### Projektstruktur

```
RoteKarte/
├── Packages/RoteKarteCore/  RuleEngine, DayState, Rules, StatusText + Tests
├── App/                RoteKarteApp.swift, AppState
├── Models/             Child, CardEvent, EventType, Rules
├── Services/           RuleEngine, DayProvider (Tageswechsel), ParentLock (PIN/Face ID), HapticsService, SoundService
├── Features/
│   ├── Today/          TodayView, RoadmapView, StationView, RewardGoalView, AvatarRunnerView
│   ├── GiveCard/       GiveCardSheet
│   ├── GoodDeed/       GoodDeedSheet
│   ├── History/        CalendarView, DayDetailView
│   ├── Settings/       SettingsView, ChildEditView, PinSetupView
│   ├── Onboarding/     WelcomeView, PinSetupView, FirstChildView
│   └── Lock/           PinPadView
├── Animations/         CardFlyAnimation, StrikeThroughShape, MeltEffect, SparkleEmitter
├── Resources/          Assets, Sounds (Pfeife, Glitzer, Plopp), Localizable (de/en)
└── Tests/              RuleEngineTests, DayProviderTests, UI-Snapshot-Tests
```

---

## 6. Umsetzungs-Phasen

### Phase 1 – Fundament (MVP-Logik)
- Xcode-Projekt, SwiftData-Setup, Datenmodell
- `RuleEngine` + Unit-Tests für alle Regeln (4 Gelbe, Rot, gute Tat, Sperre nach Verlust, Tageswechsel)
- Ein Kind, einfacher Hauptscreen ohne Animation mit Buttons

### Phase 2 – Roadmap & Animationen
- `RoadmapView` mit geschwungenem Pfad, Stationen, Belohnungs-Ziel
- Kartenflug, Durchstreichen, Schmelzen, Stern-Glitzer, Avatar-Figur
- Haptik & Sounds, Reduce-Motion-Fallbacks

### Phase 3 – Mehrere Kinder & Eltern-Modus
- Onboarding (PIN festlegen, erstes Kind anlegen)
- Kinderprofile inkl. Belohnung pro Kind, Umschalten
- PIN-Schutz für Aktionen und Einstellungen, Face ID, Auto-Sperre
- Gründe (Vorschläge + Freitext), Rückgängig („Aus Versehen vergeben")

### Phase 4 – Verlauf & Motivation
- Kalender, Tagesdetails, Belohnungs-Streak, Sternensammlung
- Tageswechsel-Animation, Konfetti

### Phase 5 – Feinschliff & Release
- App-Icon (gelbe + rote Karte mit Eis), Launch-Screen
- Lokalisierung Deutsch/Englisch
- Optional: Home-Screen-Widget (WidgetKit) mit Roadmap des Tages
- TestFlight, Datenschutz-Angaben („keine Daten erhoben"), App-Store-Einreichung

---

## 7. Test-Szenarien (RuleEngine)

1. 0–3 gelbe Karten → Belohnung erlaubt
2. 4 gelbe Karten → Belohnung gestrichen
3. 1 rote Karte (0 gelbe) → Belohnung gestrichen
4. 3 gelbe + gute Tat → 2 aktive, Belohnung erlaubt
5. 3 gelbe + gute Tat + 2 gelbe → 4 aktive, Belohnung gestrichen
6. 4 gelbe + gute Tat → bleibt bei 4, Belohnung bleibt gestrichen (kein Zurückverdienen)
7. 1 rote + gute Tat → Belohnung bleibt gestrichen
8. Gute Tat ohne gelbe Karte → keine Wirkung auf spätere Karten (kein „Guthaben“)
9. Ereignisse von gestern → beeinflussen heute nicht
10. 5. gelbe Karte → wird gespeichert, Roadmap bleibt bei 4 (Überlauf-Anzeige „+1")
