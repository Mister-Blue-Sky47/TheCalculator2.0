//
//  VolleyballView.swift
//  TheCalculator2.0
//
//  Created by Steffen Beier on 16.11.26.
//

import SwiftUI

private enum VolleyballSheet: Identifiable {
    case standings
    case schedule
    case bracket
    case buzzer

    var id: Self { self }
}

private enum ScheduleGroupingMode: String, CaseIterable, Identifiable {
    case chronological = "Chronologisch"
    case byCourtThenGroup = "Spielfeld → Gruppe"
    case byGroup = "Nach Gruppe"

    var id: String { rawValue }
}

struct VolleyballView: View {
    @EnvironmentObject private var store: VolleyballTournamentStore
    @Environment(\.scenePhase) private var scenePhase

    @State private var activeSheet: VolleyballSheet?
    @State private var showEndTournamentAlert = false
    @State private var exportedBracketImage: UIImage?
    @State private var scheduleGrouping: ScheduleGroupingMode = .byCourtThenGroup
    @State private var editingMatchIndex: Int?
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                headerBar

                if !store.gameStarted {
                    setupCard
                } else {
                    stageProgressBanner
                    matchSelectionBar
                    activeMatchCard
                    quickActionsCard
                }
            }
            .padding()
        }
        .navigationTitle("Volleyball Turnier")
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                store.saveState()
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .standings:
                standingsSheet
            case .schedule:
                scheduleSheet
            case .bracket:
                bracketSheet
            case .buzzer:
                buzzerSheet
            }
        }
        .alert("Turnier wirklich beenden?", isPresented: $showEndTournamentAlert) {
            Button("Abbrechen", role: .cancel) {}
            Button("Turnier beenden", role: .destructive) {
                store.endTournament()
            }
        } message: {
            Text("Alle laufenden Spielstände, Gruppen und Tabellenwerte werden gelöscht. Solange du nicht hier beendest, bleibt das Turnier auch beim App- oder Moduswechsel gespeichert.")
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Fertig") {
                    isInputFocused = false
                }
            }
        }
    }

    // MARK: - Kopfzeile mit Buttons rechts

    private var headerBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 8) {
                Text(store.gameStarted ? "Turnier" : "Konfiguration")
                    .font(.headline)

                Button {
                    store.clearBuzzerDisplay()
                    activeSheet = .buzzer
                } label: {
                    Label("Buzzer", systemImage: "bell.badge.fill")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .tint(.orange)

                if store.gameStarted {
                    Button {
                        activeSheet = .standings
                    } label: {
                        Label("Tabelle", systemImage: "list.number")
                            .font(.caption.bold())
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)

                    Button {
                        activeSheet = .schedule
                    } label: {
                        Label("Spielplan", systemImage: "calendar.badge.clock")
                            .font(.caption.bold())
                    }
                    .buttonStyle(.bordered)
                    .tint(.indigo)

                    Button {
                        activeSheet = .bracket
                    } label: {
                        Label("Baum", systemImage: "point.3.filled.connected.trianglepath.dotted")
                            .font(.caption.bold())
                    }
                    .buttonStyle(.bordered)
                    .tint(.teal)
                }
            }
        }
    }

    // MARK: - Turnier-Konfiguration (3–36 Teams, 0–6 Gruppen, 1–6 Spielfelder)

    private var setupCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("Turnier-System", selection: $store.formatMode) {
                ForEach(TournamentFormatMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)

            if store.formatMode == .rallyeCompact {
                Stepper("Rallye-Runden pro Team: \(store.rallyeRoundsCount)",
                        value: $store.rallyeRoundsCount,
                        in: 2...12)
                Text("Ideal bei vielen Teams (z. B. 26–36): Jedes Team spielt \(store.rallyeRoundsCount) Runden gegen tabellarisch passende Gegner statt endloser Gruppenspiele.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Stepper("Anzahl Teams: \(store.teamCount)", value: $store.teamCount, in: 3...36)

            Stepper("Anzahl Gruppen: \(store.groupCount == 0 ? "0 (Offen)" : "\(store.groupCount)")",
                    value: $store.groupCount,
                    in: 0...store.maxAllowedGroups)

            Stepper("Anzahl Spielfelder: \(store.courtCount)",
                    value: $store.courtCount,
                    in: 1...store.maxAllowedCourts)

            if store.tournamentTeamDraws.count == store.teamCount {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("Buzzer-Auslosung für \(store.teamCount) Teams (Gruppen & Felder) aktiv!")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                    Spacer()
                    Button("Zurücksetzen") {
                        store.resetTournamentTeamDraw()
                    }
                    .font(.caption2)
                }
                .padding(8)
                .background(Color.green.opacity(0.12))
                .cornerRadius(8)
            } else {
                if store.groupCount >= 1 {
                    Toggle("Gruppen zufällig auslosen", isOn: $store.randomizeInitialGroups)
                        .font(.subheadline)
                }

                Button {
                    store.buzzerCategory = .tournamentTeams
                    store.clearBuzzerDisplay()
                    activeSheet = .buzzer
                } label: {
                    Label("Teams live per Buzzer auf Gruppen & Felder losen", systemImage: "bell.badge.fill")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }

            if store.formatMode == .classicRoundRobin && store.groupCount >= 2 {
                Toggle("Runde 2 mit Über-Kreuz- / Snake-Setzung", isOn: $store.enableCrossSeedRound2)
                    .font(.subheadline)
            }

            Divider()

            Picker("Spiel-Modus", selection: $store.isTimeMode) {
                Text("Punkte (Klassisch)").tag(false)
                Text("Volleyball-Time").tag(true)
            }
            .pickerStyle(.segmented)

            if !store.isTimeMode {
                Picker("Sätze pro Spiel", selection: $store.maxSets) {
                    Text("1 Satz").tag(1)
                    Text("2 Sätze").tag(2)
                    Text("3 Sätze").tag(3)
                }
                .pickerStyle(.segmented)

                Stepper("Punkte pro Satz: \(store.targetPointsStandard)", value: $store.targetPointsStandard, in: 11...25)

                Text("Entscheidungssatz: \(store.effectiveDecidingSetPoints) Punkte (min. 2 Punkte Vorsprung)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Stepper("Gesamtspieldauer: \(store.matchDurationMinutes) Min.", value: $store.matchDurationMinutes, in: 2...30)

                Toggle("Halbzeit-Wechsel bei \(store.matchDurationMinutes / 2) Min. (Pause + Buzzer)", isOn: $store.enableHalftimeSwitch)
                    .font(.subheadline)
            }

            Divider()

            Text("Team-Namen (werden auch im Buzzer übernommen):")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ForEach(0..<store.teamCount, id: \.self) { index in
                TextField("Team \(index + 1)", text: Binding(
                    get: { index < store.teamNames.count ? store.teamNames[index] : "Team \(index + 1)" },
                    set: { if index < store.teamNames.count { store.teamNames[index] = $0 } }
                ))
                .textFieldStyle(.roundedBorder)
                .focused($isInputFocused)
            }

            Button {
                isInputFocused = false
                store.startTournament()
            } label: {
                Text("Turnier starten")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Phasen- & Rundenwechsel-Banner

    private var stageProgressBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Phase: \(store.currentStage.rawValue)")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(store.matches.filter { $0.isFinished }.count)/\(store.matches.count) Spiele • \(store.courtCount) Feld\(store.courtCount == 1 ? "" : "er")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if store.canGenerateNextRallyeRound {
                let nextRound = (store.matches.map { $0.roundNumber }.max() ?? 1) + 1
                Button {
                    store.startNextRallyeRound()
                } label: {
                    Label("Rallye-Runde \(nextRound) von \(store.rallyeRoundsCount) generieren", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }

            if store.canAdvanceToRound2 {
                Button {
                    store.startRound2CrossSeed()
                } label: {
                    Label("Runde 2 starten (Über Kreuz / Snake-Draft)", systemImage: "arrow.triangle.branch")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
            }

            if store.canAdvanceToPlacementRound {
                Button {
                    store.startPlacementAndFinalRound()
                } label: {
                    Label("Platzierungs- & Finalrunde starten", systemImage: "trophy.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Spielauswahl

    private var matchSelectionBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Spielauswahl (auch vorgezogen)")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(store.matches.enumerated()), id: \.element.id) { index, match in
                        let tA = store.teams[match.teamAIndex].name
                        let tB = store.teams[match.teamBIndex].name
                        let isSelected = index == store.currentMatchIndex

                        Button {
                            store.switchToMatch(index: index)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text("Sp. \(index + 1)\(store.courtCount > 1 ? " • F\(match.courtNumber)" : "") • \(match.label)")
                                        .font(.caption2)
                                        .lineLimit(1)
                                    if match.isFinished {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    }
                                }
                                .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)

                                Text("\(tA) vs \(tB)")
                                    .font(.caption.bold())
                                    .lineLimit(1)
                            }
                            .padding(8)
                            .background(isSelected ? Color.blue : (match.isFinished ? Color.green.opacity(0.14) : Color(.systemGray5)))
                            .foregroundColor(isSelected ? .white : .primary)
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Aktives Spiel & Punktestand

    private var activeMatchCard: some View {
        Group {
            if store.matches.indices.contains(store.currentMatchIndex) {
                let currentMatch = store.matches[store.currentMatchIndex]
                let tA = store.teams[currentMatch.teamAIndex]
                let tB = store.teams[currentMatch.teamBIndex]
                let refName = store.refereeName(for: currentMatch)

                VStack(spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(currentMatch.label)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if store.courtCount > 1 {
                                    Text("Feld \(currentMatch.courtNumber)")
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.teal.opacity(0.2))
                                        .foregroundColor(.teal)
                                        .cornerRadius(4)
                                }
                            }
                            Text("\(tA.name) vs \(tB.name)")
                                .font(.headline)
                        }
                        Spacer()
                        Text("Schiri: \(refName)")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(6)
                    }

                    if store.isTimeMode {
                        VStack(spacing: 6) {
                            Text("SPIELZEIT-COUNTDOWN (\(store.matchDurationMinutes) MIN.)")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text(store.timeFormatted(store.remainingSeconds))
                                .font(.system(size: 36, weight: .bold, design: .monospaced))
                                .foregroundColor(store.isHalftimePaused ? .red : .orange)

                            if store.isHalftimePaused {
                                Text("HALBZEIT – Seitenwechsel! Danach Wiederanpfiff für die 2. Hälfte.")
                                    .font(.caption.bold())
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            } else if store.remainingSeconds == 0 {
                                Text("SPIELZEIT ABGELAUFEN!")
                                    .font(.caption.bold())
                                    .foregroundColor(.red)
                            }

                            HStack(spacing: 12) {
                                Button(store.timerActive ? "Pause" : (store.isHalftimePaused ? "2. Hälfte anpfeifen" : "Start")) {
                                    store.timerActive ? store.stopTimer() : store.startTimer()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(store.isHalftimePaused ? .green : .blue)

                                Button("Reset") {
                                    store.stopTimer()
                                    store.remainingSeconds = store.matchDurationMinutes * 60
                                    store.halftimeTriggeredForCurrentMatch = false
                                    store.isHalftimePaused = false
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    } else {
                        Text("Satzstand: \(tA.name) \(store.currentSetSetsA) : \(store.currentSetSetsB) \(tB.name)")
                            .font(.subheadline.bold())
                    }

                    HStack(spacing: 16) {
                        scoreColumn(
                            title: tA.name,
                            points: store.currentSetPointsA,
                            color: .blue,
                            plusDisabled: currentMatch.isFinished || store.isSetScoreLocked,
                            onPlus: { store.currentSetPointsA += 1 },
                            onMinus: { if store.currentSetPointsA > 0 { store.currentSetPointsA -= 1 } }
                        )

                        Divider().frame(height: 100)

                        scoreColumn(
                            title: tB.name,
                            points: store.currentSetPointsB,
                            color: .green,
                            plusDisabled: currentMatch.isFinished || store.isSetScoreLocked,
                            onPlus: { store.currentSetPointsB += 1 },
                            onMinus: { if store.currentSetPointsB > 0 { store.currentSetPointsB -= 1 } }
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    if !store.isTimeMode && !currentMatch.isFinished && store.isSetValidToFinish {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.orange)
                            Text("Satzende erreicht (\(store.targetPointsToWinSet)+ Pkt. & ≥2 Vorsprung).")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Toggle("Sperre lösen", isOn: $store.overrideScoreLock)
                                .labelsHidden()
                                .scaleEffect(0.8)
                        }
                        .padding(.horizontal, 6)
                    }

                    HStack(spacing: 10) {
                        Button(store.isTimeMode ? "Spielstand speichern / beenden" : "Aktuellen Satz beenden") {
                            store.finishCurrentSet()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.indigo)
                        .disabled(currentMatch.isFinished || (!store.isTimeMode && !store.isSetValidToFinish))

                        if currentMatch.isFinished || !store.setHistory.isEmpty {
                            Button {
                                editingMatchIndex = store.currentMatchIndex
                            } label: {
                                Label("Korrigieren", systemImage: "pencil")
                                    .font(.caption.bold())
                            }
                            .buttonStyle(.bordered)
                            .tint(.orange)
                        }
                    }

                    if currentMatch.isFinished {
                        Text("Dieses Spiel ist beendet (über 'Korrigieren' jederzeit anpassbar).")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else if !store.isTimeMode && !store.isSetValidToFinish {
                        Text("Satzende erfordert min. \(store.targetPointsToWinSet) Punkte und 2 Punkte Vorsprung.")
                            .font(.caption2)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    if !store.setHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Sätze im aktuellen Spiel:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            ForEach(Array(store.setHistory.enumerated()), id: \.offset) { idx, pair in
                                if pair.count == 2 {
                                    Text("Satz \(idx + 1): \(tA.name) \(pair[0]) : \(pair[1]) \(tB.name)")
                                        .font(.caption)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                .sheet(item: Binding(
                    get: { editingMatchIndex.map { MatchEditIdentifier(index: $0) } },
                    set: { editingMatchIndex = $0?.index }
                )) { item in
                    MatchEditSheet(matchIndex: item.index)
                        .environmentObject(store)
                }
            }
        }
    }

    private func scoreColumn(
        title: String,
        points: Int,
        color: Color,
        plusDisabled: Bool,
        onPlus: @escaping () -> Void,
        onMinus: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.headline)
                .lineLimit(1)
            Text("\(points)")
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(color)
            HStack(spacing: 8) {
                Button("+1", action: onPlus)
                    .buttonStyle(.borderedProminent)
                    .disabled(plusDisabled)
                Button("-1", action: onMinus)
                    .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Export & Turnier beenden

    private var quickActionsCard: some View {
        VStack(spacing: 10) {
            ShareLink(item: store.generateExportText()) {
                Label("Turnierergebnisse & Spielplan teilen", systemImage: "square.and.arrow.up")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.indigo)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button(role: .destructive) {
                showEndTournamentAlert = true
            } label: {
                Label("Turnier beenden", systemImage: "xmark.circle")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Sheet: Tabelle

    private var standingsSheet: some View {
        NavigationStack {
            List {
                let sorted = store.sortedStandingsTeams()
                ForEach(Array(sorted.enumerated()), id: \.element.id) { idx, team in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(idx + 1). \(team.name)")
                                .font(.headline)
                            if let g = team.groupIndex {
                                Text(store.groupName(for: g))
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.15))
                                    .cornerRadius(4)
                            }
                            Spacer()
                            Text("S: \(team.matchesWon):\(team.matchesLost)")
                                .font(.subheadline.bold())
                        }
                        HStack(spacing: 12) {
                            Text("Sp: \(team.matchesPlayed)")
                            Text("Sätze: \(team.setsWon):\(team.setsLost)")
                            Text("Pkt: \(team.pointsWon):\(team.pointsLost)")
                            Text("Schiri: \(team.refereeCount)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Aktuelle Tabelle")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { activeSheet = nil }
                }
            }
        }
    }

    // MARK: - Sheet: Gesamtspielplan (1. Spielfeld, 2. Gruppe + Korrektur)

    private var scheduleSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Gliederung", selection: $scheduleGrouping) {
                    ForEach(ScheduleGroupingMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                List {
                    switch scheduleGrouping {
                    case .chronological:
                        ForEach(Array(store.matches.enumerated()), id: \.element.id) { idx, match in
                            scheduleMatchRow(idx: idx, match: match)
                        }

                    case .byCourtThenGroup:
                        let courts = Array(Set(store.matches.map { $0.courtNumber })).sorted()
                        ForEach(courts, id: \.self) { court in
                            Section(header: Text("Spielfeld \(court)").font(.headline)) {
                                let courtMatches = store.matches.enumerated()
                                    .filter { $0.element.courtNumber == court }
                                    .sorted { lhs, rhs in
                                        let gL = lhs.element.groupIndex ?? 99
                                        let gR = rhs.element.groupIndex ?? 99
                                        if gL != gR { return gL < gR }
                                        return lhs.offset < rhs.offset
                                    }
                                ForEach(courtMatches, id: \.element.id) { idx, match in
                                    scheduleMatchRow(idx: idx, match: match)
                                }
                            }
                        }

                    case .byGroup:
                        let labels = Array(NSOrderedSet(array: store.matches.map { $0.label })) as? [String] ?? []
                        ForEach(labels, id: \.self) { grpLabel in
                            Section(header: Text(grpLabel).font(.headline)) {
                                let grpMatches = store.matches.enumerated().filter { $0.element.label == grpLabel }
                                ForEach(grpMatches, id: \.element.id) { idx, match in
                                    scheduleMatchRow(idx: idx, match: match)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Spielplan")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { activeSheet = nil }
                }
            }
            .sheet(item: Binding(
                get: { editingMatchIndex.map { MatchEditIdentifier(index: $0) } },
                set: { editingMatchIndex = $0?.index }
            )) { item in
                MatchEditSheet(matchIndex: item.index)
                    .environmentObject(store)
            }
        }
    }

    private func scheduleMatchRow(idx: Int, match: VolleyballMatch) -> some View {
        let tA = store.teams[match.teamAIndex].name
        let tB = store.teams[match.teamBIndex].name
        let isCurrent = idx == store.currentMatchIndex

        return HStack(alignment: .center, spacing: 8) {
            Button {
                store.switchToMatch(index: idx)
                activeSheet = nil
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Spiel \(idx + 1) • \(match.label)\(store.courtCount > 1 ? " • Feld \(match.courtNumber)" : "")")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        Spacer()
                        if match.isFinished {
                            Text("Fertig (\(match.setsA):\(match.setsB))")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                        } else if isCurrent {
                            Text("Aktiv")
                                .font(.caption.bold())
                                .foregroundColor(.blue)
                        } else {
                            Text("Offen")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text("\(tA) vs \(tB)")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Schiedsgericht: \(store.refereeName(for: match))")
                        .font(.caption)
                        .foregroundColor(.orange)

                    if !match.setResults.isEmpty {
                        Text("Sätze: " + match.setResults.enumerated().map { sIdx, pair in
                            pair.count == 2 ? "S\(sIdx + 1): \(pair[0]):\(pair[1])" : ""
                        }.filter { !$0.isEmpty }.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            Button {
                editingMatchIndex = idx
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Sheet: Grafischer Turnierbaum (inkl. Platzhalter-Kästen für kommende Runden)

    private var bracketSheet: some View {
        NavigationStack {
            ScrollView([.horizontal, .vertical]) {
                tournamentBracketCanvas
                    .padding()
            }
            .navigationTitle("Turnierbaum")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let img = exportedBracketImage {
                        ShareLink(
                            item: Image(uiImage: img),
                            preview: SharePreview("Volleyball Turnierbaum", image: Image(uiImage: img))
                        ) {
                            Label("Grafik teilen", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Button {
                            renderBracketImage()
                        } label: {
                            Label("Grafik erzeugen", systemImage: "photo")
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { activeSheet = nil }
                }
            }
            .onAppear {
                renderBracketImage()
            }
        }
    }

    private var tournamentBracketCanvas: some View {
        let plannedStages: [TournamentStage] = {
            var stages: [TournamentStage] = [.round1]
            if store.formatMode == .classicRoundRobin && store.groupCount >= 2 && store.enableCrossSeedRound2 {
                stages.append(.round2)
            }
            stages.append(.placement)
            return stages
        }()

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Volleyball Turnierbaum • \(store.teamCount) Teams • \(store.courtCount) Feld\(store.courtCount == 1 ? "" : "er")")
                    .font(.headline)
                Spacer()
            }

            HStack(alignment: .top, spacing: 24) {
                ForEach(plannedStages, id: \.self) { stage in
                    let stageMatches = store.matches.filter { $0.stage == stage }
                    VStack(alignment: .leading, spacing: 12) {
                        Text(stage.rawValue)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.teal.opacity(0.18))
                            .foregroundColor(.teal)
                            .cornerRadius(8)

                        if !stageMatches.isEmpty {
                            ForEach(stageMatches) { match in
                                let tA = store.teams[match.teamAIndex].name
                                let tB = store.teams[match.teamBIndex].name
                                let aWon = match.isFinished && match.setsA > match.setsB
                                let bWon = match.isFinished && match.setsB > match.setsA

                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(match.label)
                                            .font(.caption2.bold())
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        if store.courtCount > 1 {
                                            Text("Feld \(match.courtNumber)")
                                                .font(.caption2)
                                                .foregroundColor(.teal)
                                        }
                                    }

                                    HStack {
                                        Text(tA)
                                            .font(.caption.weight(aWon ? .bold : .regular))
                                            .foregroundColor(aWon ? .green : .primary)
                                        Spacer()
                                        Text(match.isFinished ? "\(match.setsA)" : "-")
                                            .font(.caption.monospacedDigit().bold())
                                    }

                                    Divider()

                                    HStack {
                                        Text(tB)
                                            .font(.caption.weight(bWon ? .bold : .regular))
                                            .foregroundColor(bWon ? .green : .primary)
                                        Spacer()
                                        Text(match.isFinished ? "\(match.setsB)" : "-")
                                            .font(.caption.monospacedDigit().bold())
                                    }
                                }
                                .padding(10)
                                .frame(width: 220)
                                .background(Color(.secondarySystemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(match.isFinished ? Color.green.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 1.5)
                                )
                                .cornerRadius(10)
                            }
                        } else {
                            // Vorgefertigte Platzhalter-Kästen für noch ausstehende Runden
                            let placeholders = placeholderBoxes(for: stage)
                            ForEach(placeholders.indices, id: \.self) { pIdx in
                                let box = placeholders[pIdx]
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(box.title)
                                            .font(.caption2.bold())
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("Ausstehend")
                                            .font(.caption2)
                                            .foregroundColor(.orange)
                                    }

                                    HStack {
                                        Text(box.slotA)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .italic()
                                        Spacer()
                                        Text("–")
                                            .font(.caption.monospacedDigit())
                                            .foregroundColor(.secondary)
                                    }

                                    Divider()

                                    HStack {
                                        Text(box.slotB)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .italic()
                                        Spacer()
                                        Text("–")
                                            .font(.caption.monospacedDigit())
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(10)
                                .frame(width: 220)
                                .background(Color(.secondarySystemBackground).opacity(0.45))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                                        .foregroundColor(.gray.opacity(0.45))
                                )
                                .cornerRadius(10)
                            }
                        }
                    }
                    .frame(width: 220)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func placeholderBoxes(for stage: TournamentStage) -> [(title: String, slotA: String, slotB: String)] {
        if stage == .round2 {
            let groups = max(2, store.groupCount)
            return (0..<groups).map { gIdx in
                (
                    title: "R2 • \(store.groupName(for: gIdx))",
                    slotA: "Setzplatz (aus Runde 1)",
                    slotB: "Kreuz-Gegner (aus Runde 1)"
                )
            }
        } else {
            let pairCount = max(1, store.teamCount / 2)
            return (0..<pairCount).map { idx in
                let title = (idx == 0) ? "Finale (Platz 1–2)" : "Spiel um Platz \(idx * 2 + 1)–\(idx * 2 + 2)"
                return (
                    title: title,
                    slotA: "Qualifikant Platz \(idx * 2 + 1)",
                    slotB: "Qualifikant Platz \(idx * 2 + 2)"
                )
            }
        }
    }

    @MainActor
    private func renderBracketImage() {
        let renderer = ImageRenderer(content: tournamentBracketCanvas)
        renderer.scale = 2.0
        exportedBracketImage = renderer.uiImage
    }

    // MARK: - Sheet: Großer Buzzer & Verlosung

    private var buzzerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Buzzer-Funktion", selection: $store.buzzerCategory) {
                        ForEach(BuzzerCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        Picker("Buzzer-Ton", selection: $store.buzzerSound) {
                            ForEach(BuzzerSoundOption.allCases) { sound in
                                Text(sound.rawValue).tag(sound)
                            }
                        }
                        .pickerStyle(.menu)

                        Spacer()

                        Button {
                            store.buzzerSound.play()
                        } label: {
                            Label("Test", systemImage: "speaker.wave.2.fill")
                                .font(.caption.bold())
                        }
                        .buttonStyle(.bordered)
                    }

                    if store.buzzerCategory == .tournamentTeams {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Verlosung der \(store.teamCount) Turnier-Teams (Namen aus Seite 1) auf \(store.groupCount == 0 ? "Offene Runde" : "\(store.groupCount) Gruppen") & \(store.courtCount) Spielfeld\(store.courtCount == 1 ? "" : "er").")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack {
                                Text("Verlost: \(store.tournamentTeamDraws.count) / \(store.teamCount)")
                                    .font(.caption.bold())
                                Spacer()
                                Button("Verlosung zurücksetzen") {
                                    store.resetTournamentTeamDraw()
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    if store.buzzerCategory == .trainingTeams {
                        VStack(alignment: .leading, spacing: 10) {
                            Stepper("Personen im Training: \(store.trainingPersonCount)",
                                    value: $store.trainingPersonCount,
                                    in: 4...21)

                            Stepper("Anzahl Teams: \(store.trainingTeamCount)",
                                    value: $store.trainingTeamCount,
                                    in: 2...(store.trainingPersonCount >= 6 ? 3 : 2))

                            Toggle("Optionale Namen statt nur Team-Nr.", isOn: $store.assignOptionalNamesInTraining)
                                .font(.subheadline)

                            if store.assignOptionalNamesInTraining {
                                ForEach(0..<store.trainingPersonCount, id: \.self) { idx in
                                    TextField("Person \(idx + 1)", text: Binding(
                                        get: { idx < store.trainingPlayerNames.count ? store.trainingPlayerNames[idx] : "Spieler \(idx + 1)" },
                                        set: { if idx < store.trainingPlayerNames.count { store.trainingPlayerNames[idx] = $0 } }
                                    ))
                                    .textFieldStyle(.roundedBorder)
                                }
                            }

                            Button("Verlosung zurücksetzen") {
                                store.resetTrainingDraw()
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    // Ergebnis-Anzeige (vor der Auslösung bewusst leer!)
                    VStack(spacing: 6) {
                        Text(store.lastBuzzerHeadline.isEmpty ? " " : store.lastBuzzerHeadline)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        Text(store.lastBuzzerSubline.isEmpty ? " " : store.lastBuzzerSubline)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 84)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    // Großer Buzzer-Button
                    Button {
                        store.triggerBuzzer()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.red, Color.red.opacity(0.75)],
                                        center: .center,
                                        startRadius: 10,
                                        endRadius: 110
                                    )
                                )
                                .frame(width: 190, height: 190)
                                .shadow(color: .red.opacity(0.4), radius: 12, y: 6)

                            VStack(spacing: 4) {
                                Image(systemName: "hand.tap.fill")
                                    .font(.system(size: 36))
                                Text("BUZZER")
                                    .font(.title2.bold())
                            }
                            .foregroundColor(.white)
                        }
                    }
                    .padding(.vertical, 8)

                    if store.buzzerCategory == .tournamentTeams && !store.tournamentTeamDraws.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ausgeloste Turnier-Teams (\(store.tournamentTeamDraws.count)/\(store.teamCount)):")
                                .font(.subheadline.bold())

                            ForEach(store.tournamentTeamDraws.reversed()) { entry in
                                HStack {
                                    Text("#\(entry.drawNumber)")
                                        .font(.caption.monospacedDigit())
                                        .foregroundColor(.secondary)
                                    Text(entry.teamName)
                                        .font(.subheadline.bold())
                                    Spacer()
                                    if let g = entry.groupIndex {
                                        Text(store.groupName(for: g))
                                            .font(.caption.bold())
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color.blue.opacity(0.15))
                                            .cornerRadius(6)
                                    }
                                    Text("Feld \(entry.courtNumber)")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.teal.opacity(0.18))
                                        .foregroundColor(.teal)
                                        .cornerRadius(6)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    if store.buzzerCategory == .trainingTeams && !store.trainingDraws.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Bisher gezogene Lose (\(store.trainingDraws.count)/\(store.trainingPersonCount)):")
                                .font(.subheadline.bold())

                            ForEach(store.trainingDraws.reversed()) { entry in
                                HStack {
                                    Text("#\(entry.drawNumber)")
                                        .font(.caption.monospacedDigit())
                                        .foregroundColor(.secondary)
                                    Text(entry.playerName ?? "Los \(entry.drawNumber)")
                                        .font(.subheadline)
                                    Spacer()
                                    Text("Team \(entry.teamNumber)")
                                        .font(.subheadline.bold())
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.blue.opacity(0.15))
                                        .cornerRadius(6)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Buzzer & Verlosung")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { activeSheet = nil }
                }
            }
        }
    }
}

// MARK: - Hilfs-Sheet zur nachträglichen Ergebniskorrektur

private struct MatchEditIdentifier: Identifiable {
    let index: Int
    var id: Int { index }
}

private struct MatchEditSheet: View {
    @EnvironmentObject private var store: VolleyballTournamentStore
    @Environment(\.dismiss) private var dismiss
    let matchIndex: Int

    @State private var editableSets: [[Int]] = []
    @State private var isFinished: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                if store.matches.indices.contains(matchIndex) {
                    let match = store.matches[matchIndex]
                    let tA = store.teams[match.teamAIndex].name
                    let tB = store.teams[match.teamBIndex].name

                    Section(header: Text("\(tA) vs \(tB)")) {
                        Toggle("Spiel als beendet markieren", isOn: $isFinished)
                    }

                    Section(header: Text("Satzergebnisse korrigieren")) {
                        ForEach(editableSets.indices, id: \.self) { idx in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Satz \(idx + 1)")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)

                                Stepper("\(tA): \(editableSets[idx][0])",
                                        value: $editableSets[idx][0],
                                        in: 0...99)

                                Stepper("\(tB): \(editableSets[idx][1])",
                                        value: $editableSets[idx][1],
                                        in: 0...99)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { offsets in
                            editableSets.remove(atOffsets: offsets)
                        }

                        if editableSets.count < max(3, store.maxSets) {
                            Button {
                                editableSets.append([0, 0])
                            } label: {
                                Label("Weiteren Satz hinzufügen", systemImage: "plus.circle")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Spiel \(matchIndex + 1) korrigieren")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        store.updateMatchResult(
                            matchIndex: matchIndex,
                            newSetResults: editableSets,
                            markFinished: isFinished
                        )
                        dismiss()
                    }
                }
            }
            .onAppear {
                if store.matches.indices.contains(matchIndex) {
                    let match = store.matches[matchIndex]
                    editableSets = match.setResults.isEmpty ? [[0, 0]] : match.setResults
                    isFinished = match.isFinished
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        VolleyballView()
            .environmentObject(VolleyballTournamentStore())
    }
}
