#  # Developer & User Documentation - TheCalculator 2.0

## Modul: IPv6 Subnetz- & Präfix-Calculator

### 1. Technische Architektur & Code-Design (`IPv6Calculator.swift`)
- **Zielstellung:** Berechnung von IPv6-Adressstrukturen ohne externe Libraries.
- **Expandierung:** Der Algorithmus bündelt fehlende Hex-Blöcke (`::`) auf exakt 8 Blöcke à 4 Zeichen (`expandIPv6`).
- **Präfix-Berechnung:** Bit-Shift-Analogie auf String-Ebene zur Ermittlung des Network-Prefix anhand der CIDR-Länge.
- **Subnetz-Kapazität:** Berechnung möglicher `/64`-Netze über $2^{(64 - \text{Präfix})}$.

### 2. Bedienungsanleitung (Anwenderebene)
1. **Eingabe:** Eingabe einer beliebigen IPv6-Adresse (Shortened oder Full Notation, z.B. `2001:db8::1`).
2. **Präfix-Wahl:** Auswahl der Subnetzmaske (z.B. `/48` für Firmennetze oder `/64` für Standard-Subnetze).
3. **Ausgabe:** 
   - Vollständige 128-Bit-Darstellung (Expandiert).
   - Ermitteltes Netzwerk-Präfix.
   - Anzahl der daraus erzeugbaren `/64`-Subnetze.

---

## Modul: Network Diagnostic Suite (MAC OUI & Field Tools)

### 1. Technische Architektur (`NetworkDiagnosticCalculator.swift`)
- **MAC OUI Lookup:** Offline-Parsing der ersten 3 Bytes (6 Hex-Zeichen) einer MAC-Adresse.
- **Format-Bereinigung:** Tolerante Verarbeitung von Eingaben im Format `AA:BB:CC`, `AA-BB-CC` oder `AABBCC`.
- **Hersteller-Zuordnung:** Integrierte Offline-Datenbank gängiger IT- und Netzwerkkomponenten (Cisco, AVM, Raspberry Pi, VMware, Apple etc.).

### 2. Anwendungsbereich im Außendienst
- Schnelle Zuordnung unbekannter Endgeräte in Kundennetzwerken anhand der ARP-Tabelle.

### 3. Praxis-Hinweis: Private MAC-Adressen (MAC Randomization)
- **Verhalten:** Moderne mobile Betriebssysteme (z. B. iOS ab v14, Android ab v10) nutzen standardmäßig zufallsgenerierte MAC-Adressen zur Wahrung der Privatsphäre.
- **Kennzeichnung:** Bei zufälligen Adressen (wie z. B. `1E:EF:2D...`) ist das 2. Bit des ersten Bytes (Locally Administered Bit) auf `1` gesetzt. 
- **Ergebnis:** Solche Adressen sind in keiner offiziellen OUI-Herstellerdatenbank registriert und werden in der Diagnose korrekt als *Unbekannter Hersteller* bzw. private Adresse eingestuft.

---

## Modul: Scientific Calculator (Wissenschaftliche Funktionen)

### 1. Technische Erweiterung (`ContentView.swift`)
- **Trigonometrie:** Berechnungen von `sin`, `cos` und `tan` mit automatischer Grad-in-Bogenmaß-Konvertierung ($\text{rad} = \text{deg} \cdot \frac{\pi}{180}$).
- **Potenz- & Wurzelfunktionen:** Direktberechnung von $x^2$, $x^y$ via `pow(base, exp)`, $\sqrt{x}$ sowie Kehrwert $1/x$.
- **Konstanten:** Integrierte Kreiszahl $\pi$ mit doppelter Präzision (`Double.pi`) sowie Naturkonstanten-Sheet.

---

## Modul: Qualitätssicherung & Integrationstest

### 1. Testprotokoll (Systemintegration)
- **Modus-Switching:** Fehlerfreier Wechsel über den Segmented Picker ohne State-Verlust im Hauptdisplay.
- **Layout & UI-Adaptive:** Validiert unter Light- und Dark-Mode sowie auf verschiedenen Screen-Größen (iPhone SE, Pro, Max).
- **Mathematische Genauigkeit:** Verifizierung aller wissenschaftlichen und Netzwerk-Algorithmen gegen Standard-CLI-Tools (`ipcalc`, `ping`, `galculator`).

### 2. Release-Status Version 2.0
- **Build-Status:** Succeeded
- **Git Commit Tag:** `v2.0-final`

---

## Modul: Version 2.1 Refinement & UX Fixes

### 1. Behobene UI/UX Punkte
- **Keyboard Handling:** Automatisches Ausblenden der Bildschirmtastatur im Formularbetrieb (Elektro/Subnet) per Tap-Gesture.
- **Button Style Clean Up:** Einheitliches Flat-Corner Radius Design ohne störende Ränder.
- **Memory & Storage:** Wiederherstellung der `MC`, `MR`, `M+`, `M-` Funktionen inklusive optischem Indikator.
- **Easteregg & Fun:** "Ultimate Answer (42)" Trigger bei Rechenergebnis 42 sowie Info-PopUp bei der Taste "42".
- **Math Upgrade:** Einbau von $x^y$, $n!$, Trigonometrie-Inversen ($\arcsin, \arccos, \arctan$) und ASCII-Umwandlung im Base-Modus.

---

## Modul: Version 2.1 Refinement & Advanced Features

### 1. UX- & UI-Optimierungen
- **Tastatur-Management:** Automatisches Ausblenden der Bildschirmtastatur (`dismissKeyboardOnTap`) beim Tippen außerhalb von Eingabefeldern sowie bei Formular-Submissions (`.submitLabel(.done)` / `.onSubmit`).
- **Design-Korrekturen:** Bereinigung des Button-Styles (`.buttonStyle(.plain)`) zur Vermeidung ungewollter System-Grauschleier und Ränder.

### 2. Erweiterte Berechnungs- & Konvertierungsfunktionen
- **Speicherfunktionen:** Vollständige Integration von `MC`, `MR`, `M+`, `M-` mit visueller Statusanzeige im Display.
- **Erweiterte Mathematik:** Unterstützung von flexiblen Potenzen ($x^y$), Fakultät ($n!$), natürlichen und dekadischen Logarithmen ($\ln$, $\log_{10}$), inversen Winkelfunktionen ($\arcsin$, $\arccos$, $\arctan$) und Modulo (`mod`).
- **Bidirektionale ASCII-Konvertierung:**
  1. Zahl $\rightarrow$ ASCII-Zeichen (im `BASE/HEX`-Modus).
  2. Reverse ASCII: Direktes Zeichen-Eingabefeld zur Echtzeit-Ermittlung von Dezimal-, Hex- (0x) und Binär-Codes (0b).

### 3. Entertainment & Eastereggs
- **Ultimate Answer (42):** Automatische Display-Anzeige `(Ultimate Answer)` bei Erreichen des Rechenergebnisses 42 sowie dedizierte Nerd-Fact-Taste mit rotierenden mathematischen und popkulturellen Zitaten.

---

## Modul: Version 3.0 Roadmap Start - Einheiten & Währungen

### 1. Technische Architektur (`UnitCalculator.swift` & `UnitConverterView.swift`)
- **Längen- & Distanzumrechnung:** Zoll/Inch, Zentimeter, Meter, Fuß, Meilen sowie astronomische Einheiten (Lichtjahre, AU).
- **Temperaturkonvertierung:** Exakte Umrechnung zwischen Celsius, Fahrenheit und Kelvin.
- **Währungsrechner:** Festkurs-Modul für EUR, USD, GBP, CHF, JPY.

---

## Modul: Version 3.0 Work-in-Progress (Einheiten & Math-Engine)

- **Einheiten- & Währungs-Rechner:** Layout und Berechnungslogik integriert (`UnitCalculator.swift` & `UnitConverterView.swift`).
- **Known Issues / Offene Punkte für die nächste Session:**
  * Re-Design der Science-Grid Tastenhöhen im `SCIENTIFIC`-Modus.
  * Ersetzen der `NSExpression`-Evaluierung durch einen eigenen Parser zur Vermeidung von Modulo-Crashes (`%`).

## Stand 02.11.2026 (Korrektur & Tastatur-Feinschliff)
- **Tischrechner-Modus:** Klammerauflösung (z.B. `2×(5+5) = 20`) korrigiert.
- **Prozentrechnung:** Trennung zwischen mathematischem `%` und kaufmännischem `% (Tisch)` (`100 × 2% = 2`).
- **Tastaturlayout:** `42`-Taste in der Größe an Standard-Buttons angepasst; `%-Tisch`-Taste ergänzt.

## Stand 02.11.2026 (Fixes & Layout)
- **Modulo & Evaluator:** Absturz bei doppelten Is-Gleich-Zeichen (`==`) und String-Laufzeitfehlern behoben.
- **Tastatur-Layout:** `=` breiter gestaltet, `42` und `% (Tisch)` als gleichgroße Zusatz-Buttons angeordnet.
- **Prozentrechnung:** Mathematische `%`-Umrechnung wandelt Eingabewerte sauber in Hundertstel um (`100 × 2% = 2`).

## Stand 02.11.2026 (Refactoring Eingabe & Layout)
- **Tastaturlayout:** Doppelte Prozenttaste entfernt; unterste Zeile bereinigt mit breiter `=`-Taste.
- **Intelligente %-Taste:** Schaltet automatisch zwischen mathematischer Hundertstel-Umrechnung und kaufmännischer Prozentrechnung (Tischrechner-Modus) um.
- **Trenn-Reset:** Nach `=` wird bei Zahleneingabe die alte Formel gelöscht; bei Operatoreingabe mit dem Ergebnis weitergerechnet.

## Stand 02.11.2026 (Fix: Prozentrechnung & Layout-Gewichtung)
- **Breitenverhältnis:** Unterste Zeile per `GeometryReader` exakt aufgeteilt (42 = 25%, `=` = 75%).
- **Prozent-Bugbehebung:** Zusammenkleben von Zahlenstrings bei der Prozentrechnung behoben (`100 × 2%` ergibt im Math-Modus exakt `2`).
- **Input-Reset:** Nach Ergebnissevaluierung startet die Nächste Zahl garantiert eine frische Formel.

## Stand 02.11.2026 (Abschluss Basis-Core & Formellogik)
- **Formellogik:** `hasEvaluatedResult`-Flag eingeführt für saubere Trennung zwischen Folgerechnung mit Ergebnis und Neuanfang.
- **Math vs. Tischrechner:** `2 + 8 × 2` evaluiert korrekt zu `12` (Math) bzw. `20` (Sequentiell).
- **Prozentrechnung:** Funktioniert stabil in beiden Modi.
- **Tastaturlayout:** Unterste Zeile im exakten 1/4 (42) zu 3/4 (=) Breitenverhältnis fixiert.

## Stand 02.11.2026 (Stabilität & Scientific-Erweiterung)
- **Division durch 0:** Zeigt klar `"Division durch 0 nicht möglich"` an.
- **DEG/RAD Umschalter:** Umschaltung zwischen Grad (DEG) und Bogenmaß (RAD) für Winkelfunktionen im Scientific-Modus integriert.
- **Potenzierung ($x^y$):** Übersetzer auf `**` angepasst ($3^5 = 243$).
- **Crash-Schutz bei logarithmischen/Winkel-Funktionen:** Schutzabfragen bei `ln(<=0)`, `log(<=0)`, `sqrt(<0)` und `asin/acos(|x|>1)` verhindern Anwendungsabstürze.

## Stand 02.11.2026 (Einheiten-Modul Erweiterung & Fixes)
- **Kategorie-Wechsel Fix:** Automatischer Reset der `fromUnit` / `toUnit`-Auswahllisten beim Wechsel der Kategorie.
- **Währungen ergänzt:** Nachbarländer-Währungen `PLN` (Polen), `CZK` (Tschechien), `DKK` (Dänemark) hinzugefügt.
- **Kategorien erweitert:** Masse/Gewicht, Längen, IT-Speichergrößen, Datenraten und Temperaturen vollständig integriert.

## Stand 02.11.2026 (IEC Speichergrößen - MiB/GiB Integration)
- **IT-Speichergrößen:** Erweiterung um binäre Präfixe nach IEC-Norm (KiB, MiB, GiB, TiB, PiB auf 1024er Basis) im direkten Vergleich zu dezimalen Präfixen (KB, MB, GB, TB, PB auf 1000er Basis).

---

## 4. System-Bereinigung & Xcode-Struktur-Stabilisierung (06. November 2026)

### 4.1. SSD-Speicherplatzfreigabe (Systemdaten / AssetsV2)
- **Problemstellung:** Über 90 GB temporäre iOS-Simulator-Caches und Assets lagen verwaist im Systemverzeichnis `/System/Volumes/Data/System/Library/AssetsV2/`.
- **Lösung:** Erteilung von Festplattenvollzugriff für Terminal.app sowie gezielte Bereinigung der Laufzeit-Assets.
- **Ergebnis:** Freier Speicherplatz von 13 GiB auf **220 GiB (38 % Belegung)** erweitert.
- **Wartungsskript:** Automatisches Aufräum-Skript unter `~/clean_caches.sh` hinterlegt.

### 4.2. Behebung von Pfad-Verschachtelungen & Scheme-Verlust in Xcode
- **Fehlerbild:** Xcode verlor das Haupt-Target (`No Selection`), der Play-Button war inaktiv und das Öffnen meldete `does not contain a project definition file`.
- **Ursause:** Doppelte Ordnerstrukturen und Null-Byte-Relikte durch Pfadverschiebung zwischen Home-Directory (`~`) und `~/Documents`.
- **Korrekturmaßnahme:**
  1. Bereinigung verwaister Einträge im Xcode-Startfenster (*Remove from Recents*).
  2. Entfernung fehlerhafter 0-Byte `.xcodeproj`-Hüllen auf Wurzelebene.
  3. Vollständiger Neustart von Xcode zur automatischen Neugenerierung des Build-Schemes `TheCalculator2.0`.
- **Status:** Build und Simulation auf iOS-Zielgerät (*iPhone 17e*) voll funktionsfähig (`Build Succeeded`).

### 4.3. Git-Versionierung & Stand-Sicherung
- **Aktueller Stand:** Codebase stabilisiert (inkl. Formellogik, Scientific-Modulen, Themes, Einheiten-Umrechner).
- **Repository-Stand:** Hauptzweig `main` auf GitHub (`Mister-Blue-Sky47/TheCalculator2.0`) synchronisiert.

---

## 5. Evaluator-Refactoring, Theme-Standardisation & Hardware-Deployment (10. November 2026)

### 5.1. Entkopplung von Exponentiation ($x^y$) und Bitwise-XOR ($\text{^}$)
- **Problemstellung:** Bei Eingabe von `3 ^ 4` lieferte die App fälschlicherweise das Ergebnis `7` ($3 \text{ XOR } 4 = 7$). Ursache war, dass das Dach-Symbol `^` in der Steuerfunktion `containsHexOrBitwise` pauschal als Bitwise-XOR klassifiziert und vor dem mathematischen Evaluator abgefangen wurde.
- **Lösung:**
  1. Anpassung von `containsHexOrBitwise`: Das Symbol `^` löst den Bitwise-Modus nur noch aus, wenn explizite Hex-Buchstaben (`A-F`) in den Tokens vorkommen.
  2. Reihung in `evaluateMathExpression`: Die Potenz-Evaluation mittels `pow(base, exp)` erfolgt strikt an **erster Stelle**, bevor Bitwise/Hex-Operationen geprüft werden.
- **Ergebnis:** Standard-Potenzen wie $3^4 = 81$ oder $2^4 = 16$ berechnen einwandfrei im Scientific-Modus.

### 5.2. Theme-Standardisation & Xcode-Pfad-Verhalten
- **Default Theme:** Festlegung von `AppTheme.proDark` als Standard-Farbschema beim Anwendungsstart (`@State private var currentTheme: AppTheme = .proDark`).
- **Xcode-Erkenntnis ("No Selection"):** Die Anzeige "No Selection" in der oberen Xcode-Navigationsleiste tritt rein darstellungsbedingt auf, wenn sich der Textcursor auf der letzten schließenden Klammer `}` oder in einer Leerzeile hinter der Datei befindet.

### 5.3. Display-Layout-Anpassung für physisches iPhone 17e
- **Problemstellung:** Auf dem physischen Display des iPhone 17e wurde der `DEG/RAD`-Winkelschalter am rechten Bildschirmrand zu etwa 25 % abgeschnitten, während der `Tisch/Math`-Umschalter gestaucht dargestellt wurde.
- **Lösung:** Entzerrung der Header-Zeile mittels flexibler `.fixedSize()`-Modifikatoren, Reduzierung der festen Frame-Breite des `DEG/RAD`-Pickers auf 76 Pixel sowie Einbettung in ein vorlagengetreues `headerControls`-Grid.
- **Status:** Erfolgreich auf das physische Zielgerät (*iPhone 17e*) übertragen und getestet (`Build Succeeded`).
# DOKUMENTATION_v2.md - TheCalculator 2.0

## 1. Projektübersicht & Architektur
- **Projektname:** TheCalculator 2.0
- **Plattform:** iOS (SwiftUI), optimiert für iPhone-Formfaktoren (inkl. kompaktem iPhone 17e Layout).
- **Architektur:** Modulare Swift-Dateistruktur (15 Swift-Dateien), aufgeteilt in Core-View (`ContentView.swift`), spezialisierte Rechner-Module (Scientific, Electrical, Unit, IPv6, Network Diagnostics) sowie UI-Extensions und Overlays.

## 2. Kürzlich implementierte Meilensteine & Fixes (Stand: November 2026)

### A. UI/UX Header-Refactoring (iPhone 17e Optimierung)
- **Problem:** Horizontale Überläufe und abgeschnittene Ränder in der Ein-Zeilen-Kopfzeile auf kleineren Displays (z. B. Modus-Picker links und DEG/RAD-Toggle rechts).
- **Lösung:** Umstellung auf ein robustes, **zweizeiliges Header-Layout**:
  - *Zeile 1:* Modus-Auswahl-Picker (mit erzwungener horizontaler Ausrichtung via `.fixedSize`) und Schnellzugriffs-Buttons für Verlauf (`History`), Einstellungen (`Settings`) und IT-Overlays (`ITOverlays`).
  - *Zeile 2:* Kontextabhängige Schalter für den Berechnungsmodus (`Math` [Punkt-vor-Strich] vs. `Tischrechner` [Sequentiell]) sowie den Trigonometrie-Modus (`RAD` / `DEG`).

### B. Erweitertes Einheiten- und Speicher-Modul
- Integration vollständiger IEC-Speichergrößen (`KiB`, `MiB`, `GiB`, `TiB`, `PiB` auf 1024er-Basis) parallel zu den dezimalen Einheiten.
- Erweiterung des Einheiten-Konverters um grenznahe Währungen (`PLN`, `CZK`, `DKK`).

### C. Math-Core & Evaluator-Stabilität
- Trennung von Exponentiation ($x^y$) und Bitwise-XOR (`^`).
- Saubere Unterscheidung zwischen mathematischem Modulo/Prozent und kaufmännischer Tischrechner-Prozentrechnung (`% (Tisch)`).
- Umfassender Crash-Schutz bei mathematischen Grenzwerten (Division durch 0, negative Argumente in Logarithmen/Wurzeln).

### D. Offline-Netzwerk-Diagnostik & OUI-Datenbank
- Vorbereitung einer performanten, integrierten Offline-OUI-Herstellererkennung für MAC-Adressen im `NetworkDiagnosticCalculator.swift`, um auch ohne Internetverbindung im Außendienst Netzwerkhardware sofort identifizieren zu können.

## 3. Ausblick & Nächste Schritte
- Vollständige Implementierung des OUI-Hersteller-Wörterbuchs für die MAC-Analyse.
- Verfeinerung des Dark-Mode-Verhaltens und systemunabhängiger Theme-Optionen.
