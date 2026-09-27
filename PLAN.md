# Rote Karte – App-Plan

Eine iOS-App für Kinder (und Eltern), die das Verhalten des Tages mit gelben und roten Karten sichtbar macht – wie beim Fußball. Im Mittelpunkt steht eine animierte **Roadmap**: vier gelbe Karten-Stationen führen zu einem Eis am Ende des Weges. Ist der Weg voll (oder gibt es eine rote Karte), wird das Eis durchgestrichen.

---

## 1. Spielregeln (Domänenlogik)

| Ereignis | Wirkung |
|---|---|
| **Gelbe Karte** | Belegt die nächste freie Station auf der Roadmap (max. 4). |
| **4. gelbe Karte** | Eis für heute gestrichen. |
| **Rote Karte** | Eis für heute sofort gestrichen – unabhängig von der Anzahl gelber Karten. |
| **Gute Tat** | Streicht die zuletzt vergebene gelbe Karte des Tages. |
| **Tageswechsel (00:00 Uhr)** | Alles wird zurückgesetzt, jeder Tag startet mit freiem Weg und Eis. |

Festgelegte Detailregeln (als Standard, später in den Einstellungen änderbar):

- Eine gute Tat kann **nur gelbe** Karten streichen, keine rote.
- Fällt die Zahl gelber Karten durch eine gute Tat wieder unter 4 (und gibt es keine rote Karte), ist das **Eis wieder erlaubt** ("Eis zurückverdienen"). Einstellbar: *an/aus*.
- Gute Taten ohne vorhandene gelbe Karte werden trotzdem gespeichert (als ⭐ im Tagesverlauf), haben aber keine Wirkung auf die Roadmap.
- Die Grenze von 4 gelben Karten ist als Konstante hinterlegt und kann in den Einstellungen angepasst werden (3–6).

Die gesamte Regel-Logik liegt in einer reinen, testbaren Funktion:

```swift
struct DayState {
    var yellowCount: Int      // aktive (nicht gestrichene) gelbe Karten
    var hasRedCard: Bool
    var iceCreamAllowed: Bool { !hasRedCard && yellowCount < yellowLimit }
}

func evaluate(events: [CardEvent], rules: Rules) -> DayState
```

---

## 2. Zielgruppe & Bedienkonzept

- **Eltern** vergeben Karten und gute Taten.
- **Kinder** schauen sich die Roadmap an – groß, bunt, ohne viel Text.
- Optionaler **Eltern-PIN** (4 Ziffern), damit Kinder sich nicht selbst Karten streichen können. Die Roadmap ist ohne PIN sichtbar, Aktionen (Karte geben / streichen) erfordern den PIN.
- **Mehrere Kinder** möglich (Profil mit Name, Farbe, Avatar-Emoji), Wechsel per Wisch oder Avatar-Leiste oben.

---

## 3. Screens

### 3.1 Hauptscreen – "Heute" (Roadmap)
```
 [ 🧒 Mia ▾ ]                          [⚙︎]

   ●────🟨────🟨────◻︎────◻︎────🍦
   Start  1     2     3     4    Eis

         „Noch 2 Karten bis zum Eis-Verbot"

   [ 🟨 Gelbe Karte ] [ 🟥 Rote Karte ]
            [ ⭐ Gute Tat ]
```
- Geschwungener Weg (Pfad als `Path`/Bezier-Kurve) mit 4 Stationen + Eis-Ziel.
- Leere Station = gestrichelter Rahmen; belegt = gelbe Karte, die mit Animation "einfliegt".
- Eis-Ziel: fröhliches, wackelndes Eis 🍦 → bei Verbot: rotes Durchstreichen + Eis "schmilzt".
- Kleine Figur (Avatar des Kindes) steht auf der aktuellen Station und hüpft weiter.
- Unter der Roadmap: kindgerechter Status-Text.

### 3.2 Karte vergeben (Sheet)
- Auswahl **Gelb** / **Rot** als große Karten zum Antippen.
- Optional: Grund eingeben oder aus Vorschlägen wählen (z. B. „Hauen", „Nicht zuhören", „Schreien") – Vorschläge in den Einstellungen pflegbar.
- Bestätigen → Sheet schließt, Animation auf der Roadmap startet.

### 3.3 Gute Tat (Sheet)
- Optional Grund (z. B. „Aufgeräumt", „Geteilt", „Geholfen").
- Bestätigen → Stern fliegt auf die letzte gelbe Karte, diese wird durchgestrichen und fällt vom Weg.

### 3.4 Verlauf / Kalender
- Monatskalender: jeder Tag mit Symbol 🍦 (Eis erlaubt) oder durchgestrichenes 🍦.
- Tipp auf einen Tag → Timeline aller Ereignisse (Uhrzeit, Kartentyp, Grund).
- Kleine Statistik: „Eis-Tage in Folge" (Streak) als Motivation.

### 3.5 Einstellungen
- Kinder verwalten (anlegen, umbenennen, Avatar, Farbe, löschen)
- Eltern-PIN an/aus/ändern
- Gelbe-Karten-Limit (Standard 4)
- „Eis zurückverdienen" an/aus
- Grund-Vorschläge bearbeiten
- Sounds & Haptik an/aus

---

## 4. Animationen (Herzstück)

| Moment | Animation |
|---|---|
| Gelbe Karte | Karte erscheint groß in der Mitte, dreht sich (3D-Flip, `rotation3DEffect`), fliegt per `matchedGeometryEffect` auf ihre Station, kleiner Aufprall (Spring) + Haptik `.warning`. Figur hüpft eine Station weiter. |
| 4. gelbe Karte | Wie oben, danach wandert die Figur zum Eis, roter Strich wird über das Eis „gezeichnet" (`trim` auf einem Path), Eis schmilzt (Scale-Y + Tropfen), Haptik `.error`. |
| Rote Karte | Bildschirm blitzt kurz rot, rote Karte wird wie ein Schiri „hochgehalten" (Karte kommt von unten mit Pfeifen-Sound), dann fliegt sie direkt aufs Eis → Durchstreichen. |
| Gute Tat | Stern mit Partikel-Glitzer (Canvas/`TimelineView` oder `SpriteKit`-Emitter), fliegt auf die letzte gelbe Karte; Karte wird durchgestrichen, kippt und fällt vom Weg. Figur geht eine Station zurück. Ggf. Eis „taut wieder auf". |
| Eis erlaubt am Abend | Idle-Animation: Eis wackelt leicht, Konfetti beim App-Öffnen, wenn der Vortag „eis-positiv" war. |
| Tageswechsel | Weg wird „weggefegt" und neu gezeichnet. |

Umsetzung: SwiftUI-Animationen (`withAnimation(.spring)`, `PhaseAnimator`, `KeyframeAnimator` ab iOS 17), `Canvas` für Partikel, `sensoryFeedback` für Haptik. Optional später Lottie für aufwendige Figuren-Animationen.

Barrierefreiheit: bei „Bewegung reduzieren" (`accessibilityReduceMotion`) einfache Überblendungen statt Flug-Animationen.

---

## 5. Technik & Architektur

- **Plattform:** iOS 17+, iPhone & iPad (Hochformat, iPad auch Querformat)
- **UI:** SwiftUI
- **Persistenz:** SwiftData (lokal), optional später iCloud-Sync via CloudKit (für zwei Elternteile)
- **Architektur:** MVVM-light mit `@Observable`-ViewModels; Regel-Logik als reiner Service (`RuleEngine`)
- **Keine Accounts, kein Tracking, keine Werbung** (Kinder-App → App-Store-Kategorie „Kids"-Anforderungen beachten)

### Datenmodell (SwiftData)

```swift
@Model class Child {
    var id: UUID
    var name: String
    var avatar: String        // Emoji
    var colorHex: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var events: [CardEvent]
}

@Model class CardEvent {
    var id: UUID
    var type: EventType       // .yellow, .red, .goodDeed
    var timestamp: Date
    var day: Date             // Kalendertag (startOfDay) – für schnelle Abfragen
    var reason: String?
    var cancelledBy: UUID?    // gute Tat, die diese gelbe Karte gestrichen hat
    var child: Child?
}

enum EventType: String, Codable { case yellow, red, goodDeed }

struct Rules: Codable {       // in UserDefaults / AppStorage
    var yellowLimit = 4
    var allowEarnBack = true
}
```

Karten werden nie gelöscht, sondern nur als gestrichen markiert → vollständiger Verlauf bleibt erhalten, Rückgängig-Funktion ist einfach.

### Projektstruktur

```
RoteKarte/
├── App/                RoteKarteApp.swift, AppState
├── Models/             Child, CardEvent, EventType, Rules
├── Services/           RuleEngine, DayProvider (Tageswechsel), HapticsService, SoundService
├── Features/
│   ├── Today/          TodayView, RoadmapView, StationView, IceCreamGoalView, AvatarRunnerView
│   ├── GiveCard/       GiveCardSheet
│   ├── GoodDeed/       GoodDeedSheet
│   ├── History/        CalendarView, DayDetailView
│   ├── Settings/       SettingsView, ChildEditView, PinSetupView
│   └── Lock/           PinPadView
├── Animations/         CardFlyAnimation, StrikeThroughShape, MeltEffect, SparkleEmitter
├── Resources/          Assets, Sounds (Pfeife, Glitzer, Plopp), Localizable (de/en)
└── Tests/              RuleEngineTests, DayProviderTests, UI-Snapshot-Tests
```

---

## 6. Umsetzungs-Phasen

### Phase 1 – Fundament (MVP-Logik)
- Xcode-Projekt, SwiftData-Setup, Datenmodell
- `RuleEngine` + Unit-Tests für alle Regeln (4 Gelbe, Rot, gute Tat, Zurückverdienen, Tageswechsel)
- Ein Kind, einfacher Hauptscreen ohne Animation mit Buttons

### Phase 2 – Roadmap & Animationen
- `RoadmapView` mit geschwungenem Pfad, Stationen, Eis-Ziel
- Kartenflug, Durchstreichen, Schmelzen, Stern-Glitzer, Avatar-Figur
- Haptik & Sounds, Reduce-Motion-Fallbacks

### Phase 3 – Mehrere Kinder & Eltern-Modus
- Kinderprofile, Umschalten
- PIN-Schutz für Aktionen
- Gründe (Vorschläge + Freitext), Rückgängig („Aus Versehen vergeben")

### Phase 4 – Verlauf & Motivation
- Kalender, Tagesdetails, Eis-Streak
- Tageswechsel-Animation, Konfetti

### Phase 5 – Feinschliff & Release
- App-Icon (gelbe + rote Karte mit Eis), Launch-Screen
- Lokalisierung Deutsch/Englisch
- Optional: Home-Screen-Widget (WidgetKit) mit Roadmap des Tages
- Optional: iCloud-Sync zwischen Geräten der Eltern
- TestFlight, Datenschutz-Angaben („keine Daten erhoben"), App-Store-Einreichung

---

## 7. Test-Szenarien (RuleEngine)

1. 0–3 gelbe Karten → Eis erlaubt
2. 4 gelbe Karten → Eis gestrichen
3. 1 rote Karte (0 gelbe) → Eis gestrichen
4. 4 gelbe + 1 gute Tat → 3 aktive, Eis wieder erlaubt (bei „Zurückverdienen" an) / bleibt gestrichen (aus)
5. 1 rote + gute Tat → Eis bleibt gestrichen
6. Gute Tat ohne gelbe Karte → keine Wirkung
7. Ereignisse von gestern → beeinflussen heute nicht
8. 5. gelbe Karte → wird gespeichert, Roadmap bleibt bei 4 (Überlauf-Anzeige „+1")

---

## 8. Offene Fragen

- Soll das „Zurückverdienen" des Eises nach der 4. gelben Karte standardmäßig erlaubt sein? (Plan: ja, abschaltbar)
- Nur ein Gerät (Eltern-Handy) oder Sync zwischen mehreren Geräten gewünscht?
- Darf das Kind selbst Karten sehen/antippen (Kinder-Modus) oder ist die App reines Eltern-Werkzeug?
- Soll es neben „Eis" auch andere Belohnungen geben (frei wählbares Emoji/Belohnung pro Kind)?
