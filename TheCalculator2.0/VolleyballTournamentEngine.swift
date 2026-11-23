//
//  VolleyballTournamentEngine.swift
//  TheCalculator2.0
//
//  Created by Steffen Beier on 21.11.26.
//

import Foundation
import SwiftUI
import Combine
import AudioToolbox

// MARK: - Datenmodelle

struct VolleyballTeam: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var groupIndex: Int? // 0 = Gruppe A, 1 = Gruppe B, ...
    var assignedCourt: Int? // Optional per Buzzer ausgelostes Stammfeld (1...6)
    var matchesPlayed: Int = 0
    var matchesWon: Int = 0
    var matchesLost: Int = 0
    var setsWon: Int = 0
    var setsLost: Int = 0
    var pointsWon: Int = 0
    var pointsLost: Int = 0
    var refereeCount: Int = 0

    init(id: UUID = UUID(), name: String, groupIndex: Int? = nil, assignedCourt: Int? = nil) {
        self.id = id
        self.name = name
        self.groupIndex = groupIndex
        self.assignedCourt = assignedCourt
    }

    var setDifference: Int { setsWon - setsLost }
    var pointDifference: Int { pointsWon - pointsLost }

    var rankScore: Int {
        (matchesWon * 10_000) + (setDifference * 200) + pointDifference
    }
}

enum TournamentFormatMode: String, CaseIterable, Identifiable, Codable {
    case classicRoundRobin = "Klassisch (Jeder gegen jeden)"
    case rallyeCompact = "Rallye-System (Kompakt / Schweizer)"

    var id: String { rawValue }
}

enum TournamentStage: String, Codable, CaseIterable {
    case round1 = "Runde 1"
    case round2 = "Runde 2 (Kreuz/Setzung)"
    case placement = "Platzierungs- & Finalrunde"
}

struct VolleyballMatch: Identifiable, Hashable, Codable {
    let id: UUID
    let roundNumber: Int
    let stage: TournamentStage
    let groupIndex: Int? // nil = ohne Gruppe / Platzierungsspiel
    let courtNumber: Int // 1...6 Spielfeld
    let timeSlot: Int    // Paralleler Zeitslot (0, 1, 2, ...)
    let label: String    // z. B. "Gruppe A", "Platz 1–4", "Finale"
    let teamAIndex: Int
    let teamBIndex: Int
    var refereeTeamIndex: Int?
    var setsA: Int = 0
    var setsB: Int = 0
    var isFinished: Bool = false
    var setResults: [[Int]] = [] // [[11, 8], [9, 11], [11, 7]]

    init(
        id: UUID = UUID(),
        roundNumber: Int,
        stage: TournamentStage,
        groupIndex: Int?,
        courtNumber: Int = 1,
        timeSlot: Int = 0,
        label: String,
        teamAIndex: Int,
        teamBIndex: Int,
        refereeTeamIndex: Int? = nil
    ) {
        self.id = id
        self.roundNumber = roundNumber
        self.stage = stage
        self.groupIndex = groupIndex
        self.courtNumber = courtNumber
        self.timeSlot = timeSlot
        self.label = label
        self.teamAIndex = teamAIndex
        self.teamBIndex = teamBIndex
        self.refereeTeamIndex = refereeTeamIndex
    }
}

// MARK: - Buzzer-Modi, Töne & Ausgaben

enum BuzzerCategory: String, CaseIterable, Identifiable, Codable {
    case sideAndBall = "Seite & Ball"
    case sideOnly = "Nur Seite"
    case ballOnly = "Ball / Aufschlag"
    case tournamentTeams = "Turnier-Teams (Gruppe & Feld)"
    case trainingTeams = "Trainings-Teams (4–21)"

    var id: String { rawValue }
}

enum BuzzerSoundOption: String, CaseIterable, Identifiable, Codable {
    case classicBuzzer = "Buzzer (Klassisch)"
    case sportWhistle = "Sport-Signal"
    case doubleGong = "Doppel-Gong"
    case fanfare = "Triumph / Fanfare"
    case silent = "Stumm (Nur Vibration/Optik)"

    var id: String { rawValue }

    func play() {
        switch self {
        case .classicBuzzer:
            AudioServicesPlaySystemSound(1005)
        case .sportWhistle:
            AudioServicesPlaySystemSound(1013)
        case .doubleGong:
            AudioServicesPlaySystemSound(1022)
        case .fanfare:
            AudioServicesPlaySystemSound(1025)
        case .silent:
            break
        }
    }
}

struct BuzzerDrawEntry: Identifiable, Codable {
    let id: UUID
    let drawNumber: Int
    let playerName: String?
    let teamNumber: Int

    init(id: UUID = UUID(), drawNumber: Int, playerName: String?, teamNumber: Int) {
        self.id = id
        self.drawNumber = drawNumber
        self.playerName = playerName
        self.teamNumber = teamNumber
    }
}

struct TournamentTeamDrawEntry: Identifiable, Codable {
    let id: UUID
    let drawNumber: Int
    let teamIndex: Int
    let teamName: String
    let groupIndex: Int?
    let courtNumber: Int

    init(id: UUID = UUID(), drawNumber: Int, teamIndex: Int, teamName: String, groupIndex: Int?, courtNumber: Int) {
        self.id = id
        self.drawNumber = drawNumber
        self.teamIndex = teamIndex
        self.teamName = teamName
        self.groupIndex = groupIndex
        self.courtNumber = courtNumber
    }
}

// MARK: - Persistenter Snapshot für App-Wechsel & Neustarts

private struct VolleyballPersistenceSnapshot: Codable {
    var teamCount: Int
    var groupCount: Int
    var courtCount: Int
    var formatMode: TournamentFormatMode
    var rallyeRoundsCount: Int
    var randomizeInitialGroups: Bool
    var enableCrossSeedRound2: Bool
    var teamNames: [String]
    var maxSets: Int
    var targetPointsStandard: Int
    var isTimeMode: Bool
    var matchDurationMinutes: Int
    var enableHalftimeSwitch: Bool
    var gameStarted: Bool
    var currentStage: TournamentStage
    var teams: [VolleyballTeam]
    var matches: [VolleyballMatch]
    var currentMatchIndex: Int
    var currentSetPointsA: Int
    var currentSetPointsB: Int
    var currentSetSetsA: Int
    var currentSetSetsB: Int
    var setHistory: [[Int]]
    var remainingSeconds: Int
    var halftimeTriggeredForCurrentMatch: Bool
    var isHalftimePaused: Bool
    var buzzerCategory: BuzzerCategory
    var buzzerSound: BuzzerSoundOption
    var trainingPersonCount: Int
    var trainingTeamCount: Int
    var assignOptionalNamesInTraining: Bool
    var trainingPlayerNames: [String]
    var remainingTrainingPool: [Int]
    var trainingDraws: [BuzzerDrawEntry]
    var tournamentTeamDraws: [TournamentTeamDrawEntry]
}

// MARK: - Persistenter Turnier- & Buzzer-Store

@MainActor
final class VolleyballTournamentStore: ObservableObject {
    private let storageKey = "VolleyballTournamentStore.snapshot.v3"
    private var isRestoring = false

    // Konfiguration (3 bis 36 Teams, 0 bis 6 Gruppen, 1 bis 6 Spielfelder)
    @Published var teamCount: Int = 6 {
        didSet {
            let clamped = min(max(teamCount, 3), 36)
            if teamCount != clamped {
                teamCount = clamped
                return
            }
            ensureTeamNameSlots()
            if groupCount > maxAllowedGroups {
                groupCount = maxAllowedGroups
            }
            if courtCount > maxAllowedCourts {
                courtCount = maxAllowedCourts
            }
            if !isRestoring {
                resetTournamentTeamDraw()
            }
            saveState()
        }
    }

    @Published var groupCount: Int = 2 {
        didSet {
            let clamped = min(max(groupCount, 0), maxAllowedGroups)
            if groupCount != clamped {
                groupCount = clamped
                return
            }
            if !isRestoring {
                resetTournamentTeamDraw()
            }
            saveState()
        }
    }

    @Published var courtCount: Int = 1 {
        didSet {
            let clamped = min(max(courtCount, 1), maxAllowedCourts)
            if courtCount != clamped {
                courtCount = clamped
                return
            }
            if !isRestoring {
                resetTournamentTeamDraw()
            }
            saveState()
        }
    }

    @Published var formatMode: TournamentFormatMode = .classicRoundRobin { didSet { saveState() } }
    @Published var rallyeRoundsCount: Int = 4 {
        didSet {
            let clamped = min(max(rallyeRoundsCount, 2), 12)
            if rallyeRoundsCount != clamped {
                rallyeRoundsCount = clamped
                return
            }
            saveState()
        }
    }

    @Published var randomizeInitialGroups: Bool = true { didSet { saveState() } }
    @Published var enableCrossSeedRound2: Bool = true { didSet { saveState() } }
    @Published var teamNames: [String] = (1...36).map { "Team \($0)" } { didSet { saveState() } }

    // Satz-, Punkte- & Timer-Konfiguration
    @Published var maxSets: Int = 3 { didSet { saveState() } }
    @Published var targetPointsStandard: Int = 11 { didSet { saveState() } }
    @Published var overrideScoreLock: Bool = false
    @Published var isTimeMode: Bool = false { didSet { saveState() } }
    @Published var matchDurationMinutes: Int = 8 {
        didSet {
            if !timerActive {
                remainingSeconds = matchDurationMinutes * 60
                halftimeTriggeredForCurrentMatch = false
                isHalftimePaused = false
            }
            saveState()
        }
    }
    @Published var enableHalftimeSwitch: Bool = true { didSet { saveState() } }

    // Laufender Turnier-Status
    @Published var gameStarted: Bool = false { didSet { saveState() } }
    @Published var currentStage: TournamentStage = .round1 { didSet { saveState() } }
    @Published var teams: [VolleyballTeam] = [] { didSet { saveState() } }
    @Published var matches: [VolleyballMatch] = [] { didSet { saveState() } }
    @Published var currentMatchIndex: Int = 0 { didSet { saveState() } }

    // Laufendes Match
    @Published var currentSetPointsA: Int = 0 { didSet { saveState() } }
    @Published var currentSetPointsB: Int = 0 { didSet { saveState() } }
    @Published var currentSetSetsA: Int = 0 { didSet { saveState() } }
    @Published var currentSetSetsB: Int = 0 { didSet { saveState() } }
    @Published var setHistory: [[Int]] = [] { didSet { saveState() } }

    // Timer & Halbzeit-Wechsel
    @Published var remainingSeconds: Int = 480 { didSet { saveState() } }
    @Published var timerActive: Bool = false
    @Published var halftimeTriggeredForCurrentMatch: Bool = false { didSet { saveState() } }
    @Published var isHalftimePaused: Bool = false { didSet { saveState() } }
    private var timerCancellable: AnyCancellable?

    // Buzzer-Zustand & Tonwahl (bewusst leer vor Auslösung!)
    @Published var buzzerCategory: BuzzerCategory = .sideAndBall {
        didSet {
            if !isRestoring {
                clearBuzzerDisplay()
            }
            saveState()
        }
    }
    @Published var buzzerSound: BuzzerSoundOption = .classicBuzzer { didSet { saveState() } }
    @Published var lastBuzzerHeadline: String = ""
    @Published var lastBuzzerSubline: String = ""
    @Published var buzzerPulseCount: Int = 0

    // Turnier-Teams-Verlosung (Gruppe + Spielfeld aus Seite 1)
    @Published var remainingTournamentTeamIndices: [Int] = []
    @Published var tournamentTeamDraws: [TournamentTeamDrawEntry] = [] { didSet { saveState() } }

    // Trainings-Verlosung (4 bis 21 Personen auf 2 bis 3 Teams)
    @Published var trainingPersonCount: Int = 12 {
        didSet {
            let clamped = min(max(trainingPersonCount, 4), 21)
            if trainingPersonCount != clamped {
                trainingPersonCount = clamped
                return
            }
            if trainingTeamCount == 3 && trainingPersonCount < 6 {
                trainingTeamCount = 2
            }
            if !isRestoring {
                resetTrainingDraw()
            }
        }
    }

    @Published var trainingTeamCount: Int = 2 {
        didSet {
            let clamped = (trainingPersonCount < 6) ? 2 : min(max(trainingTeamCount, 2), 3)
            if trainingTeamCount != clamped {
                trainingTeamCount = clamped
                return
            }
            if !isRestoring {
                resetTrainingDraw()
            }
        }
    }

    @Published var assignOptionalNamesInTraining: Bool = false { didSet { saveState() } }
    @Published var trainingPlayerNames: [String] = (1...21).map { "Spieler \($0)" } { didSet { saveState() } }
    @Published var remainingTrainingPool: [Int] = [] { didSet { saveState() } }
    @Published var trainingDraws: [BuzzerDrawEntry] = [] { didSet { saveState() } }

    init() {
        ensureTeamNameSlots()
        if !loadState() {
            resetTrainingDraw()
            resetTournamentTeamDraw()
            clearBuzzerDisplay()
        } else {
            // Beim Öffnen der App Buzzer-Anzeige leer halten, damit keine Verwechslungen entstehen
            clearBuzzerDisplay()
            rebuildRemainingTournamentPool()
        }
    }

    var maxAllowedGroups: Int {
        min(6, max(0, teamCount / 2))
    }

    var maxAllowedCourts: Int {
        min(6, max(1, teamCount / 2))
    }

    /// Entscheidungssatz: Bei Sätzen <= 15 volle Punktzahl (z. B. 11 -> 11), bei 25 Punkten Tiebreak 15
    var effectiveDecidingSetPoints: Int {
        if targetPointsStandard <= 15 {
            return targetPointsStandard
        }
        return max(15, Int(Double(targetPointsStandard) * 0.6))
    }

    var targetPointsToWinSet: Int {
        let isDecidingSet = (maxSets > 1) && (currentSetSetsA == (maxSets / 2)) && (currentSetSetsB == (maxSets / 2))
        return isDecidingSet ? effectiveDecidingSetPoints : targetPointsStandard
    }

    var isSetValidToFinish: Bool {
        if isTimeMode { return true }
        let target = targetPointsToWinSet
        let diff = abs(currentSetPointsA - currentSetPointsB)
        let maxP = max(currentSetPointsA, currentSetPointsB)
        return maxP >= target && diff >= 2
    }

    /// Sperrt weiteres Hochzählen, sobald Zielpunktzahl + 2 Punkte Vorsprung erreicht sind
    var isSetScoreLocked: Bool {
        if isTimeMode || overrideScoreLock { return false }
        return isSetValidToFinish
    }

    var isCurrentStageFinished: Bool {
        let stageMatches = matches.filter { $0.stage == currentStage }
        return !stageMatches.isEmpty && stageMatches.allSatisfy { $0.isFinished }
    }

    var canAdvanceToRound2: Bool {
        formatMode == .classicRoundRobin && currentStage == .round1 && isCurrentStageFinished && groupCount >= 2 && enableCrossSeedRound2
    }

    var canAdvanceToPlacementRound: Bool {
        isCurrentStageFinished && (
            formatMode == .rallyeCompact ||
            (currentStage == .round1 && (!enableCrossSeedRound2 || groupCount < 2)) ||
            currentStage == .round2
        )
    }

    func groupName(for index: Int) -> String {
        let letters = ["A", "B", "C", "D", "E", "F"]
        if index >= 0 && index < letters.count {
            return "Gruppe \(letters[index])"
        }
        return "Gruppe \(index + 1)"
    }

    func activeTeamName(at index: Int) -> String {
        guard index >= 0 && index < teamNames.count else { return "Team \(index + 1)" }
        let trimmed = teamNames[index].trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Team \(index + 1)" : trimmed
    }

    private func ensureTeamNameSlots() {
        while teamNames.count < 36 {
            teamNames.append("Team \(teamNames.count + 1)")
        }
    }

    // MARK: - Deterministische Tabellen-Sortierung (inkl. Alphanumerik bei Gleichstand)

    func sortedStandingsTeams() -> [VolleyballTeam] {
        teams.sorted { lhs, rhs in
            compareTeams(lhs, rhs)
        }
    }

    func sortedTeamIndices(from indices: [Int]) -> [Int] {
        indices.sorted { lhsIdx, rhsIdx in
            compareTeams(teams[lhsIdx], teams[rhsIdx])
        }
    }

    private func compareTeams(_ lhs: VolleyballTeam, _ rhs: VolleyballTeam) -> Bool {
        if lhs.matchesWon != rhs.matchesWon {
            return lhs.matchesWon > rhs.matchesWon
        }
        if lhs.setDifference != rhs.setDifference {
            return lhs.setDifference > rhs.setDifference
        }
        if lhs.pointDifference != rhs.pointDifference {
            return lhs.pointDifference > rhs.pointDifference
        }
        if lhs.pointsWon != rhs.pointsWon {
            return lhs.pointsWon > rhs.pointsWon
        }
        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }

    // MARK: - Persistenz (UserDefaults)

    func saveState() {
        guard !isRestoring else { return }
        let snapshot = VolleyballPersistenceSnapshot(
            teamCount: teamCount,
            groupCount: groupCount,
            courtCount: courtCount,
            formatMode: formatMode,
            rallyeRoundsCount: rallyeRoundsCount,
            randomizeInitialGroups: randomizeInitialGroups,
            enableCrossSeedRound2: enableCrossSeedRound2,
            teamNames: teamNames,
            maxSets: maxSets,
            targetPointsStandard: targetPointsStandard,
            isTimeMode: isTimeMode,
            matchDurationMinutes: matchDurationMinutes,
            enableHalftimeSwitch: enableHalftimeSwitch,
            gameStarted: gameStarted,
            currentStage: currentStage,
            teams: teams,
            matches: matches,
            currentMatchIndex: currentMatchIndex,
            currentSetPointsA: currentSetPointsA,
            currentSetPointsB: currentSetPointsB,
            currentSetSetsA: currentSetSetsA,
            currentSetSetsB: currentSetSetsB,
            setHistory: setHistory,
            remainingSeconds: remainingSeconds,
            halftimeTriggeredForCurrentMatch: halftimeTriggeredForCurrentMatch,
            isHalftimePaused: isHalftimePaused,
            buzzerCategory: buzzerCategory,
            buzzerSound: buzzerSound,
            trainingPersonCount: trainingPersonCount,
            trainingTeamCount: trainingTeamCount,
            assignOptionalNamesInTraining: assignOptionalNamesInTraining,
            trainingPlayerNames: trainingPlayerNames,
            remainingTrainingPool: remainingTrainingPool,
            trainingDraws: trainingDraws,
            tournamentTeamDraws: tournamentTeamDraws
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    @discardableResult
    private func loadState() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let snapshot = try? JSONDecoder().decode(VolleyballPersistenceSnapshot.self, from: data) else {
            return false
        }
        isRestoring = true
        defer { isRestoring = false }

        teamCount = snapshot.teamCount
        groupCount = snapshot.groupCount
        courtCount = snapshot.courtCount
        formatMode = snapshot.formatMode
        rallyeRoundsCount = snapshot.rallyeRoundsCount
        randomizeInitialGroups = snapshot.randomizeInitialGroups
        enableCrossSeedRound2 = snapshot.enableCrossSeedRound2
        teamNames = snapshot.teamNames
        ensureTeamNameSlots()
        maxSets = snapshot.maxSets
        targetPointsStandard = snapshot.targetPointsStandard
        isTimeMode = snapshot.isTimeMode
        matchDurationMinutes = snapshot.matchDurationMinutes
        enableHalftimeSwitch = snapshot.enableHalftimeSwitch
        gameStarted = snapshot.gameStarted
        currentStage = snapshot.currentStage
        teams = snapshot.teams
        matches = snapshot.matches
        currentMatchIndex = snapshot.currentMatchIndex
        currentSetPointsA = snapshot.currentSetPointsA
        currentSetPointsB = snapshot.currentSetPointsB
        currentSetSetsA = snapshot.currentSetSetsA
        currentSetSetsB = snapshot.currentSetSetsB
        setHistory = snapshot.setHistory
        remainingSeconds = snapshot.remainingSeconds
        halftimeTriggeredForCurrentMatch = snapshot.halftimeTriggeredForCurrentMatch
        isHalftimePaused = snapshot.isHalftimePaused
        buzzerCategory = snapshot.buzzerCategory
        buzzerSound = snapshot.buzzerSound
        trainingPersonCount = snapshot.trainingPersonCount
        trainingTeamCount = snapshot.trainingTeamCount
        assignOptionalNamesInTraining = snapshot.assignOptionalNamesInTraining
        trainingPlayerNames = snapshot.trainingPlayerNames
        remainingTrainingPool = snapshot.remainingTrainingPool
        trainingDraws = snapshot.trainingDraws
        tournamentTeamDraws = snapshot.tournamentTeamDraws
        return true
    }

    // MARK: - Buzzer-Logik (inkl. Sound, leere Startfelder & Turnier-Team-Verlosung)

    func clearBuzzerDisplay() {
        lastBuzzerHeadline = ""
        lastBuzzerSubline = ""
    }

    func triggerBuzzer() {
        buzzerPulseCount += 1
        buzzerSound.play()

        switch buzzerCategory {
        case .sideAndBall:
            let sides = ["Seite: LINKS", "Seite: RECHTS"]
            let balls = ["MIT BALL (Aufschlag)", "OHNE BALL (Annahme)"]
            lastBuzzerHeadline = sides.randomElement() ?? "Seite: LINKS"
            lastBuzzerSubline = balls.randomElement() ?? "MIT BALL (Aufschlag)"

        case .sideOnly:
            lastBuzzerHeadline = Bool.random() ? "FELDSEITE: LINKS" : "FELDSEITE: RECHTS"
            lastBuzzerSubline = "Seitenwahl ausgelost"

        case .ballOnly:
            lastBuzzerHeadline = Bool.random() ? "BALL / AUFSCHLAG" : "KEIN BALL / ANNAHME"
            lastBuzzerSubline = "Ballwahl ausgelost"

        case .tournamentTeams:
            drawNextTournamentTeam()

        case .trainingTeams:
            drawNextTrainingPerson()
        }
    }

    func resetTournamentTeamDraw() {
        tournamentTeamDraws.removeAll()
        remainingTournamentTeamIndices = Array(0..<teamCount).shuffled()
        clearBuzzerDisplay()
        saveState()
    }

    private func rebuildRemainingTournamentPool() {
        let drawnIndices = Set(tournamentTeamDraws.map { $0.teamIndex })
        remainingTournamentTeamIndices = (0..<teamCount).filter { !drawnIndices.contains($0) }.shuffled()
    }

    private func drawNextTournamentTeam() {
        if remainingTournamentTeamIndices.isEmpty && tournamentTeamDraws.count < teamCount {
            rebuildRemainingTournamentPool()
        }
        guard !remainingTournamentTeamIndices.isEmpty else {
            lastBuzzerHeadline = "Alle \(teamCount) Teams verlost!"
            lastBuzzerSubline = "Tippe auf 'Verlosung zurücksetzen' für eine neue Auslosung"
            return
        }

        let teamIdx = remainingTournamentTeamIndices.removeFirst()
        let drawNo = tournamentTeamDraws.count + 1
        let tName = activeTeamName(at: teamIdx)

        // Gleichmäßige Verteilung auf Gruppen & Spielfelder
        let assignedGroup: Int? = groupCount > 0 ? ((drawNo - 1) % groupCount) : nil
        let assignedCourt: Int = ((drawNo - 1) % max(1, courtCount)) + 1

        let entry = TournamentTeamDrawEntry(
            drawNumber: drawNo,
            teamIndex: teamIdx,
            teamName: tName,
            groupIndex: assignedGroup,
            courtNumber: assignedCourt
        )
        tournamentTeamDraws.append(entry)

        let groupText = assignedGroup.map { groupName(for: $0) } ?? "Offene Runde"
        lastBuzzerHeadline = "\(tName)"
        lastBuzzerSubline = "\(groupText) • Feld \(assignedCourt)  (Los \(drawNo)/\(teamCount))"
    }

    func resetTrainingDraw() {
        var pool: [Int] = []
        let baseSize = trainingPersonCount / trainingTeamCount
        let remainder = trainingPersonCount % trainingTeamCount

        for teamIdx in 1...trainingTeamCount {
            let countForThisTeam = baseSize + (teamIdx <= remainder ? 1 : 0)
            pool.append(contentsOf: Array(repeating: teamIdx, count: countForThisTeam))
        }
        remainingTrainingPool = pool.shuffled()
        trainingDraws.removeAll()
        clearBuzzerDisplay()
        saveState()
    }

    private func drawNextTrainingPerson() {
        if remainingTrainingPool.isEmpty {
            lastBuzzerHeadline = "Alle \(trainingPersonCount) Personen verlost!"
            lastBuzzerSubline = "Tippe auf 'Verlosung zurücksetzen' für eine neue Runde"
            return
        }

        let assignedTeam = remainingTrainingPool.removeFirst()
        let drawNo = trainingDraws.count + 1
        let optionalName: String? = assignOptionalNamesInTraining
            ? (drawNo - 1 < trainingPlayerNames.count ? trainingPlayerNames[drawNo - 1] : "Spieler \(drawNo)")
            : nil

        trainingDraws.append(
            BuzzerDrawEntry(drawNumber: drawNo, playerName: optionalName, teamNumber: assignedTeam)
        )

        if let name = optionalName {
            lastBuzzerHeadline = "\(name) → TEAM \(assignedTeam)"
        } else {
            lastBuzzerHeadline = "DU BIST: TEAM \(assignedTeam)"
        }
        lastBuzzerSubline = "Los \(drawNo) von \(trainingPersonCount) • Noch \(remainingTrainingPool.count) frei"
    }

    // MARK: - Turnier Start & Gruppenverteilung

    func startTournament() {
        stopTimer()
        let activeNames = (0..<teamCount).map { activeTeamName(at: $0) }
        var createdTeams = activeNames.map { VolleyballTeam(name: $0) }
        currentStage = .round1

        // Falls über den Buzzer bereits eine vollständige Team-Auslosung vorliegt, diese übernehmen!
        let hasCompleteBuzzerDraw = (tournamentTeamDraws.count == teamCount)

        if formatMode == .rallyeCompact {
            // Kompakter Rallye-Modus: Teams spielen eine definierte Anzahl Runden nach Tabellenstand
            if hasCompleteBuzzerDraw {
                for draw in tournamentTeamDraws {
                    createdTeams[draw.teamIndex].groupIndex = draw.groupIndex
                    createdTeams[draw.teamIndex].assignedCourt = draw.courtNumber
                }
            } else if groupCount > 0 {
                var order = Array(0..<teamCount)
                if randomizeInitialGroups { order.shuffle() }
                for (pos, tIdx) in order.enumerated() {
                    createdTeams[tIdx].groupIndex = pos % groupCount
                }
            }
            teams = createdTeams
            matches = generateNextRallyeRoundMatches(roundNumber: 1)
        } else if groupCount == 0 {
            for i in createdTeams.indices {
                createdTeams[i].groupIndex = nil
                if hasCompleteBuzzerDraw, let draw = tournamentTeamDraws.first(where: { $0.teamIndex == i }) {
                    createdTeams[i].assignedCourt = draw.courtNumber
                }
            }
            teams = createdTeams
            matches = generateFairScheduleForBuckets(
                buckets: [(groupIndex: nil, label: "Offene Runde", teamIndices: Array(0..<teamCount))],
                roundNumber: 1,
                stage: .round1
            )
        } else {
            var groupBuckets: [[Int]] = Array(repeating: [], count: groupCount)
            if hasCompleteBuzzerDraw {
                for draw in tournamentTeamDraws {
                    let g = min(max(draw.groupIndex ?? 0, 0), groupCount - 1)
                    groupBuckets[g].append(draw.teamIndex)
                    createdTeams[draw.teamIndex].groupIndex = g
                    createdTeams[draw.teamIndex].assignedCourt = draw.courtNumber
                }
            } else {
                var order = Array(0..<teamCount)
                if randomizeInitialGroups {
                    order.shuffle()
                }
                for (pos, teamIdx) in order.enumerated() {
                    let g = pos % groupCount
                    groupBuckets[g].append(teamIdx)
                    createdTeams[teamIdx].groupIndex = g
                }
            }

            teams = createdTeams
            let namedBuckets = groupBuckets.enumerated().map { (gIdx, indices) in
                (groupIndex: Optional(gIdx), label: groupName(for: gIdx), teamIndices: indices)
            }
            matches = generateFairScheduleForBuckets(
                buckets: namedBuckets,
                roundNumber: 1,
                stage: .round1
            )
        }

        currentMatchIndex = 0
        remainingSeconds = matchDurationMinutes * 60
        halftimeTriggeredForCurrentMatch = false
        isHalftimePaused = false
        overrideScoreLock = false
        resetMatchState()
        gameStarted = true
        saveState()
    }

    // MARK: - Rallye-System (Kompakt / Schweizer System für große Felder)

    var canGenerateNextRallyeRound: Bool {
        guard formatMode == .rallyeCompact, gameStarted, currentStage == .round1, isCurrentStageFinished else {
            return false
        }
        let maxRound = matches.map { $0.roundNumber }.max() ?? 1
        return maxRound < rallyeRoundsCount
    }

    func startNextRallyeRound() {
        guard canGenerateNextRallyeRound else { return }
        stopTimer()
        let nextRound = (matches.map { $0.roundNumber }.max() ?? 1) + 1
        let newMatches = generateNextRallyeRoundMatches(roundNumber: nextRound)
        guard !newMatches.isEmpty else { return }

        let startIndex = matches.count
        matches.append(contentsOf: newMatches)
        switchToMatch(index: startIndex)
        saveState()
    }

    private func generateNextRallyeRoundMatches(roundNumber: Int) -> [VolleyballMatch] {
        var existingPairs: Set<String> = []
        for m in matches {
            let key = "\(min(m.teamAIndex, m.teamBIndex))-\(max(m.teamAIndex, m.teamBIndex))"
            existingPairs.insert(key)
        }

        var ordered = sortedTeamIndices(from: Array(teams.indices))
        if roundNumber == 1 && randomizeInitialGroups {
            ordered.shuffle()
        }

        var unpaired = ordered
        var pairs: [(groupIndex: Int?, label: String, a: Int, b: Int)] = []

        while unpaired.count >= 2 {
            let teamA = unpaired.removeFirst()
            // Suche den nächstplatzierten Gegner, gegen den noch nicht gespielt wurde
            let oppPos = unpaired.firstIndex { candidate in
                let key = "\(min(teamA, candidate))-\(max(teamA, candidate))"
                return !existingPairs.contains(key)
            } ?? 0
            let teamB = unpaired.remove(at: oppPos)
            let grpIdx = (teams[teamA].groupIndex == teams[teamB].groupIndex) ? teams[teamA].groupIndex : nil
            let label = "Rallye R\(roundNumber)"
            pairs.append((groupIndex: grpIdx, label: label, a: teamA, b: teamB))
        }

        // Auf Spielfelder & Slots verteilen
        var scheduled: [VolleyballMatch] = []
        let effectiveCourts = max(1, min(courtCount, teams.count / 2))
        var slot = (matches.map { $0.timeSlot }.max() ?? -1) + 1
        var refCount: [Int: Int] = Dictionary(uniqueKeysWithValues: teams.indices.map { ($0, teams[$0].refereeCount) })

        var idx = 0
        while idx < pairs.count {
            let slice = Array(pairs[idx..<min(idx + effectiveCourts, pairs.count)])
            var busyInSlot: Set<Int> = []
            for p in slice {
                busyInSlot.insert(p.a)
                busyInSlot.insert(p.b)
            }

            for (offset, p) in slice.enumerated() {
                let court = offset + 1
                let refCandidate = teams.indices
                    .filter { !busyInSlot.contains($0) }
                    .min { (refCount[$0] ?? 0) < (refCount[$1] ?? 0) }
                if let r = refCandidate {
                    busyInSlot.insert(r)
                    refCount[r, default: 0] += 1
                    teams[r].refereeCount += 1
                }
                scheduled.append(
                    VolleyballMatch(
                        roundNumber: roundNumber,
                        stage: .round1,
                        groupIndex: p.groupIndex,
                        courtNumber: court,
                        timeSlot: slot,
                        label: p.label,
                        teamAIndex: p.a,
                        teamBIndex: p.b,
                        refereeTeamIndex: refCandidate
                    )
                )
            }
            idx += effectiveCourts
            slot += 1
        }

        return scheduled
    }

    // MARK: - Runde 2: Über-Kreuz- / Schlangen-Setzung (Snake Draft)

    func startRound2CrossSeed() {
        guard canAdvanceToRound2 else { return }
        stopTimer()

        var rankedByGroup: [[Int]] = []
        for g in 0..<groupCount {
            let groupTeams = sortedTeamIndices(from: teams.indices.filter { teams[$0].groupIndex == g })
            rankedByGroup.append(groupTeams)
        }

        var newBuckets: [[Int]] = Array(repeating: [], count: groupCount)
        let maxRankDepth = rankedByGroup.map { $0.count }.max() ?? 0
        var snakeCursor = 0

        for rankPos in 0..<maxRankDepth {
            var tierTeams: [Int] = []
            for g in 0..<groupCount {
                if rankPos < rankedByGroup[g].count {
                    tierTeams.append(rankedByGroup[g][rankPos])
                }
            }
            tierTeams = sortedTeamIndices(from: tierTeams)

            for teamIdx in tierTeams {
                let cycle = snakeCursor / groupCount
                let offset = snakeCursor % groupCount
                let targetGroup = (cycle % 2 == 0) ? offset : (groupCount - 1 - offset)
                newBuckets[targetGroup].append(teamIdx)
                teams[teamIdx].groupIndex = targetGroup
                snakeCursor += 1
            }
        }

        currentStage = .round2
        let namedBuckets = newBuckets.enumerated().map { (gIdx, indices) in
            (groupIndex: Optional(gIdx), label: "R2 • \(groupName(for: gIdx))", teamIndices: indices)
        }
        let round2Matches = generateFairScheduleForBuckets(
            buckets: namedBuckets,
            roundNumber: 2,
            stage: .round2
        )

        let startIndex = matches.count
        matches.append(contentsOf: round2Matches)
        if startIndex < matches.count {
            switchToMatch(index: startIndex)
        }
        saveState()
    }

    // MARK: - Final- & Platzierungsrunde (1. gegen 1., 2. gegen 2., ...)

    func startPlacementAndFinalRound() {
        guard canAdvanceToPlacementRound else { return }
        stopTimer()

        var placementMatches: [VolleyballMatch] = []
        let nextRoundNum = (matches.map { $0.roundNumber }.max() ?? 1) + 1

        if formatMode == .classicRoundRobin && groupCount >= 2 {
            var rankedByGroup: [[Int]] = []
            for g in 0..<groupCount {
                let groupTeams = sortedTeamIndices(from: teams.indices.filter { teams[$0].groupIndex == g })
                rankedByGroup.append(groupTeams)
            }

            let maxRankDepth = rankedByGroup.map { $0.count }.max() ?? 0
            var buckets: [(groupIndex: Int?, label: String, teamIndices: [Int])] = []

            for rankPos in 0..<maxRankDepth {
                var tierTeams: [Int] = []
                for g in 0..<groupCount {
                    if rankPos < rankedByGroup[g].count {
                        tierTeams.append(rankedByGroup[g][rankPos])
                    }
                }
                if tierTeams.count >= 2 {
                    let title: String
                    if rankPos == 0 {
                        title = tierTeams.count == 2 ? "Finale (Platz 1–2)" : "Meisterrunde (1. Plätze)"
                    } else {
                        let startRank = rankPos * groupCount + 1
                        let endRank = startRank + tierTeams.count - 1
                        title = "Platzierung \(startRank)–\(endRank) (\(rankPos + 1). Plätze)"
                    }
                    buckets.append((groupIndex: nil, label: title, teamIndices: tierTeams))
                }
            }

            placementMatches = generateFairScheduleForBuckets(
                buckets: buckets,
                roundNumber: nextRoundNum,
                stage: .placement
            )
        } else {
            let sortedAll = sortedTeamIndices(from: Array(teams.indices))
            var buckets: [(groupIndex: Int?, label: String, teamIndices: [Int])] = []
            var idx = 0
            while idx + 1 < sortedAll.count {
                let pair = [sortedAll[idx], sortedAll[idx + 1]]
                let title = (idx == 0) ? "Finale (Platz 1–2)" : "Spiel um Platz \(idx + 1)–\(idx + 2)"
                buckets.append((groupIndex: nil, label: title, teamIndices: pair))
                idx += 2
            }
            placementMatches = generateFairScheduleForBuckets(
                buckets: buckets,
                roundNumber: nextRoundNum,
                stage: .placement
            )
        }

        guard !placementMatches.isEmpty else { return }
        currentStage = .placement
        let startIndex = matches.count
        matches.append(contentsOf: placementMatches)
        switchToMatch(index: startIndex)
        saveState()
    }

    // MARK: - Spielplan-Generator: Gruppen-Durchmischung, Spielfelder & Schiedsgericht

    private func generateFairScheduleForBuckets(
        buckets: [(groupIndex: Int?, label: String, teamIndices: [Int])],
        roundNumber: Int,
        stage: TournamentStage
    ) -> [VolleyballMatch] {
        struct PendingPair {
            let groupIndex: Int?
            let label: String
            let a: Int
            let b: Int
        }

        var pending: [PendingPair] = []
        for bucket in buckets {
            let ids = bucket.teamIndices
            guard ids.count >= 2 else { continue }
            for i in 0..<ids.count {
                for j in (i + 1)..<ids.count {
                    pending.append(PendingPair(groupIndex: bucket.groupIndex, label: bucket.label, a: ids[i], b: ids[j]))
                }
            }
        }

        var scheduled: [VolleyballMatch] = []
        var lastPlayedSlot: [Int: Int] = [:]
        var playCount: [Int: Int] = [:]
        var lastGroupInSlot: Set<Int> = []
        var lastGroupOnCourt: [Int: Int] = [:]
        var refCount: [Int: Int] = Dictionary(uniqueKeysWithValues: teams.indices.map { ($0, teams[$0].refereeCount) })

        let effectiveCourts = max(1, min(courtCount, teams.count / 2))
        var timeSlot = 0

        while !pending.isEmpty {
            var busyTeamsInThisSlot: Set<Int> = []
            var groupsUsedInThisSlot: Set<Int> = []
            var slotMatches: [(pair: PendingPair, court: Int)] = []

            for court in 1...effectiveCourts {
                let candidateIndices = pending.indices.filter { idx in
                    let p = pending[idx]
                    return !busyTeamsInThisSlot.contains(p.a) && !busyTeamsInThisSlot.contains(p.b)
                }
                guard let firstCand = candidateIndices.first else { break }

                var bestIdx = firstCand
                var bestScore = Int.min

                for idx in candidateIndices {
                    let pair = pending[idx]
                    let lastA = lastPlayedSlot[pair.a] ?? -10
                    let lastB = lastPlayedSlot[pair.b] ?? -10
                    let restA = timeSlot - lastA
                    let restB = timeSlot - lastB

                    // Keine Doppelbelastung direkt nacheinander
                    let backToBackPenalty = ((restA == 1) ? -12_000 : 0) + ((restB == 1) ? -12_000 : 0)

                    // Gruppen-Durchmischung: Dieselbe Gruppe nicht direkt nacheinander & nicht geballt im selben Slot
                    var groupMixScore = 0
                    if let g = pair.groupIndex {
                        if lastGroupOnCourt[court] == g {
                            groupMixScore -= 2_500
                        }
                        if lastGroupInSlot.contains(g) {
                            groupMixScore -= 900
                        }
                        if groupsUsedInThisSlot.contains(g) {
                            groupMixScore -= 600
                        }
                    }

                    // Bonus, wenn ein Team seinem per Buzzer zugelosten Stammfeld zugeteilt wird
                    let courtPreferenceBonus =
                        ((teams[pair.a].assignedCourt == court) ? 180 : 0) +
                        ((teams[pair.b].assignedCourt == court) ? 180 : 0)

                    let minRestBonus = min(restA, restB) * 140 + (restA + restB) * 25
                    let balanceBonus = -((playCount[pair.a] ?? 0) + (playCount[pair.b] ?? 0)) * 60

                    let score = backToBackPenalty + groupMixScore + courtPreferenceBonus + minRestBonus + balanceBonus
                    if score > bestScore {
                        bestScore = score
                        bestIdx = idx
                    }
                }

                let chosen = pending.remove(at: bestIdx)
                busyTeamsInThisSlot.insert(chosen.a)
                busyTeamsInThisSlot.insert(chosen.b)
                if let g = chosen.groupIndex {
                    groupsUsedInThisSlot.insert(g)
                    lastGroupOnCourt[court] = g
                }
                slotMatches.append((pair: chosen, court: court))
            }

            lastGroupInSlot = groupsUsedInThisSlot

            for item in slotMatches {
                let chosen = item.pair
                let candidateRefs = teams.indices.filter { !busyTeamsInThisSlot.contains($0) }
                let chosenRef = candidateRefs.min { lhs, rhs in
                    let lhsRefs = refCount[lhs] ?? 0
                    let rhsRefs = refCount[rhs] ?? 0
                    if lhsRefs != rhsRefs { return lhsRefs < rhsRefs }

                    let lhsJustPlayed = (lastPlayedSlot[lhs] == timeSlot - 1) ? 1 : 0
                    let rhsJustPlayed = (lastPlayedSlot[rhs] == timeSlot - 1) ? 1 : 0
                    if lhsJustPlayed != rhsJustPlayed { return lhsJustPlayed < rhsJustPlayed }

                    let lhsSameGroup = (teams[lhs].groupIndex == chosen.groupIndex) ? 0 : 1
                    let rhsSameGroup = (teams[rhs].groupIndex == chosen.groupIndex) ? 0 : 1
                    return lhsSameGroup < rhsSameGroup
                }

                if let refIdx = chosenRef {
                    busyTeamsInThisSlot.insert(refIdx)
                    refCount[refIdx, default: 0] += 1
                    teams[refIdx].refereeCount += 1
                }

                lastPlayedSlot[chosen.a] = timeSlot
                lastPlayedSlot[chosen.b] = timeSlot
                playCount[chosen.a, default: 0] += 1
                playCount[chosen.b, default: 0] += 1

                scheduled.append(
                    VolleyballMatch(
                        roundNumber: roundNumber,
                        stage: stage,
                        groupIndex: chosen.groupIndex,
                        courtNumber: item.court,
                        timeSlot: timeSlot,
                        label: chosen.label,
                        teamAIndex: chosen.a,
                        teamBIndex: chosen.b,
                        refereeTeamIndex: chosenRef
                    )
                )
            }

            timeSlot += 1
        }

        return scheduled
    }

    // MARK: - Spielsteuerung, nachträgliche Korrektur & Timer

    func switchToMatch(index: Int) {
        guard matches.indices.contains(index) else { return }
        stopTimer()
        currentMatchIndex = index
        let match = matches[index]
        currentSetPointsA = 0
        currentSetPointsB = 0
        currentSetSetsA = match.setsA
        currentSetSetsB = match.setsB
        setHistory = match.setResults
        overrideScoreLock = false

        if isTimeMode {
            remainingSeconds = matchDurationMinutes * 60
            halftimeTriggeredForCurrentMatch = false
            isHalftimePaused = false
        }
        saveState()
    }

    func finishCurrentSet() {
        guard matches.indices.contains(currentMatchIndex) else { return }
        guard isSetValidToFinish else { return }

        setHistory.append([currentSetPointsA, currentSetPointsB])

        var match = matches[currentMatchIndex]
        if currentSetPointsA > currentSetPointsB {
            currentSetSetsA += 1
        } else if currentSetPointsB > currentSetPointsA {
            currentSetSetsB += 1
        }

        match.setsA = currentSetSetsA
        match.setsB = currentSetSetsB
        match.setResults = setHistory

        let setsNeededToWin = isTimeMode ? 1 : (maxSets / 2) + 1
        if isTimeMode || currentSetSetsA == setsNeededToWin || currentSetSetsB == setsNeededToWin {
            stopTimer()
            match.isFinished = true
            matches[currentMatchIndex] = match
            recalculateAllStandings()

            if let nextIdx = matches.firstIndex(where: { !$0.isFinished }) {
                switchToMatch(index: nextIdx)
            }
        } else {
            matches[currentMatchIndex] = match
            recalculateAllStandings()
            currentSetPointsA = 0
            currentSetPointsB = 0
            overrideScoreLock = false
        }
        saveState()
    }

    /// Nachträgliche Korrektur eines beliebigen Spiels (inkl. Neuberechnung der kompletten Tabelle!)
    func updateMatchResult(matchIndex: Int, newSetResults: [[Int]], markFinished: Bool) {
        guard matches.indices.contains(matchIndex) else { return }
        var match = matches[matchIndex]

        let validSets = newSetResults.filter { $0.count == 2 }
        var setsA = 0
        var setsB = 0
        for s in validSets {
            if s[0] > s[1] { setsA += 1 }
            else if s[1] > s[0] { setsB += 1 }
        }

        match.setResults = validSets
        match.setsA = setsA
        match.setsB = setsB
        match.isFinished = markFinished
        matches[matchIndex] = match

        recalculateAllStandings()

        if matchIndex == currentMatchIndex {
            currentSetSetsA = setsA
            currentSetSetsB = setsB
            setHistory = validSets
            currentSetPointsA = 0
            currentSetPointsB = 0
            overrideScoreLock = false
        }
        saveState()
    }

    /// Berechnet sämtliche Team-Statistiken aus allen gespeicherten Satzergebnissen sauber neu
    func recalculateAllStandings() {
        for idx in teams.indices {
            teams[idx].matchesPlayed = 0
            teams[idx].matchesWon = 0
            teams[idx].matchesLost = 0
            teams[idx].setsWon = 0
            teams[idx].setsLost = 0
            teams[idx].pointsWon = 0
            teams[idx].pointsLost = 0
        }

        for match in matches {
            let idxA = match.teamAIndex
            let idxB = match.teamBIndex
            guard teams.indices.contains(idxA), teams.indices.contains(idxB) else { continue }

            var mSetsA = 0
            var mSetsB = 0

            for s in match.setResults where s.count == 2 {
                teams[idxA].pointsWon += s[0]
                teams[idxA].pointsLost += s[1]
                teams[idxB].pointsWon += s[1]
                teams[idxB].pointsLost += s[0]

                if s[0] > s[1] {
                    mSetsA += 1
                    teams[idxA].setsWon += 1
                    teams[idxB].setsLost += 1
                } else if s[1] > s[0] {
                    mSetsB += 1
                    teams[idxB].setsWon += 1
                    teams[idxA].setsLost += 1
                }
            }

            if match.isFinished {
                teams[idxA].matchesPlayed += 1
                teams[idxB].matchesPlayed += 1
                if mSetsA > mSetsB {
                    teams[idxA].matchesWon += 1
                    teams[idxB].matchesLost += 1
                } else if mSetsB > mSetsA {
                    teams[idxB].matchesWon += 1
                    teams[idxA].matchesLost += 1
                }
            }
        }
    }

    func endTournament() {
        stopTimer()
        gameStarted = false
        currentStage = .round1
        teams.removeAll()
        matches.removeAll()
        currentMatchIndex = 0
        resetMatchState()
        remainingSeconds = matchDurationMinutes * 60
        halftimeTriggeredForCurrentMatch = false
        isHalftimePaused = false
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    func resetMatchState() {
        currentSetPointsA = 0
        currentSetPointsB = 0
        currentSetSetsA = 0
        currentSetSetsB = 0
        setHistory.removeAll()
        overrideScoreLock = false
    }

    // MARK: - Zeitspiel-Timer inkl. Halbzeit-Wechsel & Buzzer-Ton

    func startTimer() {
        guard !timerActive else { return }
        if remainingSeconds <= 0 {
            remainingSeconds = matchDurationMinutes * 60
            halftimeTriggeredForCurrentMatch = false
        }
        isHalftimePaused = false
        timerActive = true

        let totalSeconds = matchDurationMinutes * 60
        let halfSeconds = totalSeconds / 2

        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1

                    // Halbzeit erreicht (z. B. 04:00 bei 08:00 Gesamtzeit): Buzzerton + automatische Wechsel-Pause
                    if self.enableHalftimeSwitch &&
                        !self.halftimeTriggeredForCurrentMatch &&
                        halfSeconds > 0 &&
                        self.remainingSeconds == halfSeconds {
                        self.halftimeTriggeredForCurrentMatch = true
                        self.isHalftimePaused = true
                        self.buzzerSound.play()
                        self.stopTimer()
                    }
                } else {
                    // Spielzeit abgelaufen: Abschluss-Buzzerton
                    self.buzzerSound.play()
                    self.stopTimer()
                }
            }
    }

    func stopTimer() {
        timerActive = false
        timerCancellable?.cancel()
        timerCancellable = nil
        saveState()
    }

    func timeFormatted(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func refereeName(for match: VolleyballMatch) -> String {
        if let refIdx = match.refereeTeamIndex, teams.indices.contains(refIdx) {
            return teams[refIdx].name
        }
        return "Extern"
    }

    func generateExportText() -> String {
        var report = "=== VOLLEYBALL TURNIER-ERGEBNISSE (\(courtCount) Spielfeld\(courtCount == 1 ? "" : "er")) ===\n\n"
        report += "--- AKTUELLE TABELLE ---\n"
        let sortedTeams = sortedStandingsTeams()
        for (index, team) in sortedTeams.enumerated() {
            let grp = team.groupIndex.map { " [\(groupName(for: $0))]" } ?? ""
            report += "\(index + 1). \(team.name)\(grp) | Sp: \(team.matchesPlayed) | S: \(team.matchesWon):\(team.matchesLost) | Sätze: \(team.setsWon):\(team.setsLost) | Pkt: \(team.pointsWon):\(team.pointsLost)\n"
        }

        report += "\n--- GESAMTSPIELPLAN & ERGEBNISSE ---\n"
        for (idx, match) in matches.enumerated() {
            let tA = teams[match.teamAIndex].name
            let tB = teams[match.teamBIndex].name
            let status = match.isFinished ? "Endstand \(match.setsA):\(match.setsB)" : "Offen"
            let courtTag = courtCount > 1 ? " • Feld \(match.courtNumber) (Slot \(match.timeSlot + 1))" : ""
            report += "Spiel \(idx + 1) (\(match.label)\(courtTag)): \(tA) vs \(tB) – \(status) (Schiri: \(refereeName(for: match)))\n"
            for (sIdx, sRes) in match.setResults.enumerated() where sRes.count == 2 {
                report += "   Satz \(sIdx + 1): \(sRes[0]) : \(sRes[1])\n"
            }
        }
        return report
    }
}
