//
//  VolleyballView.swift
//  TheCalculator2.0
//
//  Created by Steffen Beier on 16.11.26.
//

import SwiftUI
import Combine

struct VolleyballTeam: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var matchesPlayed: Int = 0
    var matchesWon: Int = 0
    var matchesLost: Int = 0
    var setsWon: Int = 0
    var setsLost: Int = 0
    var pointsWon: Int = 0
    var pointsLost: Int = 0
     
    var setDifference: Int { setsWon - setsLost }
    var pointDifference: Int { pointsWon - pointsLost }
     
    var rankScore: Int {
        (matchesWon * 1000) + (setDifference * 100) + pointDifference
    }
}

struct VolleyballMatch: Identifiable {
    let id = UUID()
    let teamAIndex: Int
    let teamBIndex: Int
    var setsA: Int = 0
    var setsB: Int = 0
    var isFinished: Bool = false
    var setResults: [(Int, Int)] = [] // Gespeicherte Sätze dieses Matches
}

struct VolleyballView: View {
    @State private var teamCount = 4
    @State private var teamNames: [String] = ["Alpha", "Beta", "Gamma", "Delta", "Echo", "Foxtrot"]
    @State private var maxSets = 3 // 1, 2 oder 3 Sätze
    @State private var targetPointsStandard = 25
     
    // Neuer State für Volleyball-Time Modus
    @State private var isTimeMode = false
    @State private var matchDurationMinutes = 10 // Konfigurierbare Minuten (ab 1 Min)
    @State private var remainingSeconds = 600
    @State private var timerActive = false
    @State private var timerCancellable: AnyCancellable? = nil
     
    @State private var teams: [VolleyballTeam] = []
    @State private var matches: [VolleyballMatch] = []
    @State private var currentMatchIndex = 0
     
    @State private var currentSetPointsA = 0
    @State private var currentSetPointsB = 0
    @State private var currentSetSetsA = 0
    @State private var currentSetSetsB = 0
    @State private var setHistory: [(Int, Int)] = []
     
    @State private var gameStarted = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !gameStarted {
                    setupView
                } else {
                    matchSelectionView
                    matchPlayView
                    completedMatchesView
                    liveTableView
                }
            }
            .padding()
        }
        .navigationTitle("Volleyball Turnier-Manager")
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Fertig") {
                    isInputFocused = false
                }
            }
        }
    }
     
    // MARK: - Setup / Konfiguration
    private var setupView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Turnier-Konfiguration")
                .font(.headline)
             
            Stepper("Anzahl Teams: \(teamCount)", value: $teamCount, in: 3...6)
                .onChange(of: teamCount) { _, newValue in
                    while teamNames.count < newValue {
                        teamNames.append("Team \(teamNames.count + 1)")
                    }
                }
             
            Picker("Spiel-Modus", selection: $isTimeMode) {
                Text("Punkte (Klassisch)").tag(false)
                Text("Volleyball-Time (Zeitspiel)").tag(true)
            }
            .pickerStyle(.segmented)
             
            if !isTimeMode {
                Picker("Anzahl Sätze pro Spiel", selection: $maxSets) {
                    Text("1 Satz").tag(1)
                    Text("2 Sätze").tag(2)
                    Text("3 Sätze (Best of 3)").tag(3)
                }
                .pickerStyle(.segmented)
                 
                Stepper("Punkte pro Satz: \(targetPointsStandard)", value: $targetPointsStandard, in: 11...25)
                Text("Entscheidungssatz wird angepasst: \(effectiveDecidingSetPoints) Punkte")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Stepper("Spieldauer (Min): \(matchDurationMinutes)", value: $matchDurationMinutes, in: 1...30)
                    .font(.subheadline)
                    .onChange(of: matchDurationMinutes) { _, newVal in
                        remainingSeconds = newVal * 60
                    }
            }
             
            Text("Team-Namen anpassen:")
                .font(.subheadline)
                .foregroundColor(.secondary)
             
            ForEach(0..<teamCount, id: \.self) { index in
                TextField("Team \(index + 1)", text: Binding(
                    get: { index < teamNames.count ? teamNames[index] : "" },
                    set: { if index < teamNames.count { teamNames[index] = $0 } }
                ))
                .textFieldStyle(.roundedBorder)
            }
             
            Button(action: startTournament) {
                Text("Turnier starten")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
      
    // MARK: - Manuelle Spielauswahl
    private var matchSelectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Spielauswahl (auch vorgezogen)")
                .font(.subheadline)
                .bold()
             
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(matches.enumerated()), id: \.offset) { index, match in
                        let tA = teams[match.teamAIndex].name
                        let tB = teams[match.teamBIndex].name
                         
                        Button(action: {
                            switchToMatch(index: index)
                        }) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("Spiel \(index + 1)")
                                        .font(.caption2)
                                    if match.isFinished {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    }
                                }
                                .foregroundColor(index == currentMatchIndex ? .white : .secondary)
                                
                                Text("\(tA) vs \(tB)")
                                    .font(.caption)
                                    .bold()
                                    .lineLimit(1)
                            }
                            .padding(8)
                            .background(index == currentMatchIndex ? Color.blue : (match.isFinished ? Color(.systemGreen).opacity(0.15) : Color(.systemGray5)))
                            .foregroundColor(index == currentMatchIndex ? .white : .primary)
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
      
    // MARK: - Spielansicht & Schiedsgericht
    private var matchPlayView: some View {
        let currentMatch = matches[currentMatchIndex]
        let tA = teams[currentMatch.teamAIndex]
        let tB = teams[currentMatch.teamBIndex]
        let refereeName = getRefereeName(for: currentMatch)
          
        return VStack(spacing: 15) {
            HStack {
                Text("Aktives Spiel: \(tA.name) vs \(tB.name)")
                    .font(.headline)
                Spacer()
                Text("Schiri: \(refereeName)")
                    .font(.caption)
                    .bold()
                    .padding(6)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(6)
            }
              
            if isTimeMode {
                VStack(spacing: 6) {
                    Text("SPIELZEIT-COUNTDOWN")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(timeFormatted(remainingSeconds))
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                    
                    HStack(spacing: 12) {
                        Button(timerActive ? "Pause" : "Start") {
                            if timerActive {
                                stopTimer()
                            } else {
                                startTimer()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Reset") {
                            stopTimer()
                            remainingSeconds = matchDurationMinutes * 60
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            } else {
                Text("Satzstand: \(tA.name) \(currentSetSetsA) : \(currentSetSetsB) \(tB.name)")
                    .font(.subheadline)
                    .bold()
            }
              
            HStack(spacing: 20) {
                VStack {
                    Text(tA.name)
                        .font(.headline)
                    Text("\(currentSetPointsA)")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.blue)
                      
                    HStack {
                        Button("+1") { currentSetPointsA += 1 }
                            .buttonStyle(.borderedProminent)
                        Button("-1") { if currentSetPointsA > 0 { currentSetPointsA -= 1 } }
                            .buttonStyle(.bordered)
                    }
                }
                  
                Divider().frame(height: 100)
                  
                VStack {
                    Text(tB.name)
                        .font(.headline)
                    Text("\(currentSetPointsB)")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.green)
                      
                    HStack {
                        Button("+1") { currentSetPointsB += 1 }
                            .buttonStyle(.borderedProminent)
                        Button("-1") { if currentSetPointsB > 0 { currentSetPointsB -= 1 } }
                            .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
              
            Button(isTimeMode ? "Spielstand speichern / beenden" : "Aktuellen Satz beenden") {
                finishCurrentSet()
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .disabled(currentMatch.isFinished || (!isTimeMode && !isSetValidToFinish))
              
            if currentMatch.isFinished {
                Text("Dieses Spiel ist bereits beendet.")
                    .font(.caption)
                    .foregroundColor(.green)
            } else if !isTimeMode && !isSetValidToFinish {
                Text("Satzende erfordert min. \(targetPointsToWinSet) Punkte und 2 Punkte Vorsprung.")
                    .font(.caption2)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
              
            if !setHistory.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Beendete Sätze in diesem laufenden Spiel:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ForEach(Array(setHistory.enumerated()), id: \.offset) { idx, set in
                        Text("Satz \(idx + 1): \(tA.name) \(set.0) : \(set.1) \(tB.name)")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    // MARK: - Vergangene Spiele (Historie)
    private var completedMatchesView: some View {
        let finished = matches.filter { $0.isFinished }
        
        return Group {
            if !finished.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bereits beendete Spiele")
                        .font(.headline)
                    
                    ForEach(finished) { match in
                        let tA = teams[match.teamAIndex].name
                        let tB = teams[match.teamBIndex].name
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(tA) vs \(tB)")
                                    .bold()
                                Spacer()
                                Text("Sätze: \(match.setsA) : \(match.setsB)")
                                    .foregroundColor(.secondary)
                            }
                            
                            ForEach(Array(match.setResults.enumerated()), id: \.offset) { sIdx, sRes in
                                Text("• Satz \(sIdx + 1): \(sRes.0) : \(sRes.1)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(.systemGray5).opacity(0.5))
                .cornerRadius(12)
            }
        }
    }
      
    // MARK: - Live Tabelle & Export
    private var liveTableView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Live-Tabelle (Gesamtwertung)")
                .font(.headline)
             
            let sortedTeams = teams.sorted { $0.rankScore > $1.rankScore }
             
            ForEach(Array(sortedTeams.enumerated()), id: \.element.id) { index, team in
                HStack {
                    Text("\(index + 1).")
                        .bold()
                        .frame(width: 25, alignment: .leading)
                    Text(team.name)
                        .frame(width: 100, alignment: .leading)
                    Spacer()
                    Text("Sp: \(team.matchesPlayed)")
                    Text("S: \(team.matchesWon):\(team.matchesLost)")
                    Text("Pkt: \(team.pointsWon):\(team.pointsLost)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(index == 0 ? Color.yellow.opacity(0.2) : Color(.systemGray6))
                .cornerRadius(8)
            }
             
            // Export / Teilen Button
            ShareLink(item: generateExportText()) {
                Label("Turnierergebnisse exportieren", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.indigo)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 5)

            Button("Turnier zurücksetzen") {
                stopTimer()
                gameStarted = false
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .padding(.top, 5)
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
      
    // MARK: - Export Text Generator
    private func generateExportText() -> String {
        var report = "=== VOLLEYBALL TURNIER-ERGEBNISSE ===\n\n"
        
        report += "--- LIVE-TABELLE (Gesamtwertung) ---\n"
        let sortedTeams = teams.sorted { $0.rankScore > $1.rankScore }
        for (index, team) in sortedTeams.enumerated() {
            report += "\(index + 1). \(team.name) | Sp: \(team.matchesPlayed) | S: \(team.matchesWon):\(team.matchesLost) | Sätze: \(team.setsWon):\(team.setsLost) | Pkt: \(team.pointsWon):\(team.pointsLost)\n"
        }
        
        report += "\n--- BEENDETE SPIELE & SÄTZE ---\n"
        let finished = matches.filter { $0.isFinished }
        if finished.isEmpty {
            report += "Bisher keine Spiele abgeschlossen.\n"
        } else {
            for match in finished {
                let tA = teams[match.teamAIndex].name
                let tB = teams[match.teamBIndex].name
                report += "\n\(tA) vs \(tB) (Endstand Sätze: \(match.setsA):\(match.setsB))\n"
                for (sIdx, sRes) in match.setResults.enumerated() {
                    report += "  - Satz \(sIdx + 1): \(sRes.0) : \(sRes.1)\n"
                }
            }
        }
        
        return report
    }

    // MARK: - Logik & Hilfsmethoden
    private var effectiveDecidingSetPoints: Int {
        max(10, Int(Double(targetPointsStandard) * 0.6))
    }
      
    private var targetPointsToWinSet: Int {
        let isDecidingSet = (maxSets > 1) && (currentSetSetsA == (maxSets / 2)) && (currentSetSetsB == (maxSets / 2))
        return isDecidingSet ? effectiveDecidingSetPoints : targetPointsStandard
    }
      
    private var isSetValidToFinish: Bool {
        if isTimeMode { return true }
        let target = targetPointsToWinSet
        let diff = abs(currentSetPointsA - currentSetPointsB)
        let maxP = max(currentSetPointsA, currentSetPointsB)
        return maxP >= target && diff >= 2
    }
     
    private func startTimer() {
        timerActive = true
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if remainingSeconds > 0 {
                    remainingSeconds -= 1
                } else {
                    stopTimer()
                }
            }
    }
     
    private func stopTimer() {
        timerActive = false
        timerCancellable?.cancel()
        timerCancellable = nil
    }
     
    private func timeFormatted(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
      
    private func switchToMatch(index: Int) {
        currentMatchIndex = index
        let match = matches[index]
        currentSetPointsA = 0
        currentSetPointsB = 0
        currentSetSetsA = match.setsA
        currentSetSetsB = match.setsB
        setHistory = match.setResults
        
        if isTimeMode {
            remainingSeconds = matchDurationMinutes * 60
            stopTimer()
        }
    }
      
    private func finishCurrentSet() {
        setHistory.append((currentSetPointsA, currentSetPointsB))
          
        var match = matches[currentMatchIndex]
        var tA = teams[match.teamAIndex]
        var tB = teams[match.teamBIndex]
          
        tA.pointsWon += currentSetPointsA
        tA.pointsLost += currentSetPointsB
        tB.pointsWon += currentSetPointsB
        tB.pointsLost += currentSetPointsA
          
        if currentSetPointsA > currentSetPointsB {
            currentSetSetsA += 1
            tA.setsWon += 1
            tB.setsLost += 1
        } else if currentSetPointsB > currentSetPointsA {
            currentSetSetsB += 1
            tB.setsWon += 1
            tA.setsLost += 1
        }
          
        teams[match.teamAIndex] = tA
        teams[match.teamBIndex] = tB
          
        match.setsA = currentSetSetsA
        match.setsB = currentSetSetsB
        match.setResults = setHistory
        
        let setsNeededToWin = isTimeMode ? 1 : (maxSets / 2) + 1
        if isTimeMode || currentSetSetsA == setsNeededToWin || currentSetSetsB == setsNeededToWin {
            stopTimer()
            match.isFinished = true
            
            var finalA = teams[match.teamAIndex]
            var finalB = teams[match.teamBIndex]
            finalA.matchesPlayed += 1
            finalB.matchesPlayed += 1
             
            if currentSetSetsA > currentSetSetsB {
                finalA.matchesWon += 1
                finalB.matchesLost += 1
            } else if currentSetSetsB > currentSetSetsA {
                finalB.matchesWon += 1
                finalA.matchesLost += 1
            }
            teams[match.teamAIndex] = finalA
            teams[match.teamBIndex] = finalB
             
            matches[currentMatchIndex] = match
            
            // Zum nächsten unfertigen Spiel springen falls vorhanden
            if let nextIdx = matches.firstIndex(where: { !$0.isFinished }) {
                switchToMatch(index: nextIdx)
            }
        } else {
            matches[currentMatchIndex] = match
            currentSetPointsA = 0
            currentSetPointsB = 0
        }
    }
      
    private func resetMatchState() {
        currentSetPointsA = 0
        currentSetPointsB = 0
        currentSetSetsA = 0
        currentSetSetsB = 0
        setHistory.removeAll()
    }
      
    private func startTournament() {
        teams = (0..<teamCount).map { i in
            VolleyballTeam(name: teamNames[i])
        }
          
        var generatedMatches: [VolleyballMatch] = []
        for i in 0..<teamCount {
            for j in (i + 1)..<teamCount {
                generatedMatches.append(VolleyballMatch(teamAIndex: i, teamBIndex: j))
            }
        }
        matches = generatedMatches
        currentMatchIndex = 0
        remainingSeconds = matchDurationMinutes * 60
        resetMatchState()
        gameStarted = true
    }
      
    private func getRefereeName(for match: VolleyballMatch) -> String {
        for i in 0..<teamCount {
            if i != match.teamAIndex && i != match.teamBIndex {
                return teams[i].name
            }
        }
        return "Extern"
    }
}

#Preview {
    NavigationView {
        VolleyballView()
    }
}
