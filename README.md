# Rote Karte

iOS-App für Kinder: gelbe und rote Karten für den Tag, gute Taten streichen gelbe Karten – und am Ende des Weges wartet die Belohnung (z. B. Eis 🍦). Details siehe [PLAN.md](PLAN.md).

## Voraussetzungen

- Xcode 26 oder neuer
- iPhone/iPad mit iOS 26 oder neuer (oder Simulator)

## Loslegen

1. `RoteKarte.xcodeproj` in Xcode öffnen.
2. Unter *Signing & Capabilities* das eigene Team wählen und die Bundle-ID (`com.example.rotekarte`) auf eine eigene ändern.
3. Schema **RoteKarte** wählen und starten (⌘R). Tests laufen mit ⌘U.

## Aufbau

| Ordner | Inhalt |
|---|---|
| `Packages/RoteKarteCore` | Spielregeln als reines Swift-Paket (`RuleEngine`, `DayState`, `Rules`, `StatusText`) mit Tests – ohne UI und ohne Datenbank |
| `RoteKarte/` | App: SwiftData-Modelle (`Child`, `CardEvent`) und SwiftUI-Screens |
| `project.yml` | [XcodeGen](https://github.com/yonaskolb/XcodeGen)-Spezifikation, aus der `RoteKarte.xcodeproj` erzeugt wird |

Neue Dateien in `RoteKarte/` oder Einstellungsänderungen: in `project.yml` pflegen und `xcodegen generate` ausführen.

## Tests der Spielregeln

```sh
cd Packages/RoteKarteCore
swift test
```

Läuft auch unter Linux (z. B. im Docker-Image `swift:6.2`) und in der CI bei jedem Push.

## Stand

- ✅ Phase 1 – Fundament: Datenmodell, Spielregeln mit Tests, einfacher Heute-Screen
- ⏳ Phase 2 – Roadmap & Animationen
- ⏳ Phase 3 – Mehrere Kinder & Eltern-Modus (PIN)
- ⏳ Phase 4 – Verlauf & Motivation
- ⏳ Phase 5 – Feinschliff & Release
