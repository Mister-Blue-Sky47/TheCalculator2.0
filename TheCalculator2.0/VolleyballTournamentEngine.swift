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
    var matchesPlayed: Int = 0
    var matchesWon: Int = 0
    var matchesLost: Int = 0
    var setsWon: Int = 0
    var setsLost: Int = 0
    var pointsWon: Int = 0
    var pointsLost: Int = 0
    var refereeCount: Int = 0

    init(id: UUID = UUID(), name: String, groupIndex: Int? = nil) {
        self.id = id
        self.name = name
        self.groupIndex = groupIndex
    }

    var setDifference: Int { setsWon - setsLost }
    var pointDifference: Int { pointsWon - pointsLost }

    var rankScore: Int {
        (matchesWon * 10_000) + (setDifference * 200) + pointDifference
    }
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
    var setResults: [[Int]] = [] // [[25, 21], [22, 25], [15, 12]]

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

// MARK: - Persistenter Snapshot für App-Wechsel & Neustarts

private struct VolleyballPersistenceSnapshot: Codable {
    var teamCount: Int
    var groupCount: Int
    var courtCount: Int
    var randomizeInitialGroups: Bool
    var enableCrossSeedRound2: Bool
    var teamNames: [String]
    var maxSets: Int
    var targetPointsStandard: Int
    var isTimeMode: Bool
    var matchDurationMinutes: Int
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
    var buzzerCategory: BuzzerCategory
    var buzzerSound: BuzzerSoundOption
    var lastBuzzerHeadline: String
    var lastBuzzerSubline: String
    var trainingPersonCount: Int
    var trainingTeamCount: Int
    var assignOptionalNamesInTraining: Bool
    var trainingPlayerNames: [String]
    var remainingTrainingPool: [Int]
    var trainingDraws: [BuzzerDrawEntry]
}

// MARK: - Persistenter Turnier- & Buzzer-Store

@MainActor
final class VolleyballTournamentStore: ObservableObject {
    private let storageKey = "VolleyballTournamentStore.snapshot.v2"
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
            saveState()
        }
    }

    @Published var randomizeInitialGroups: Bool = true { didSet { saveState() } }
    @Published var enableCrossSeedRound2: Bool = true { didSet { saveState() } }
    @Published var teamNames: [String] = (1...36).map { "Team \($0)" } { didSet { saveState() } }

    // Satz-, Punkte- & Timer-Konfiguration
    @Published var maxSets: Int = 3 { didSet { saveState() } }
    @Published var targetPointsStandard: Int = 25 { didSet { saveState() } }
    @Published var isTimeMode: Bool = false { didSet { saveState() } }
    @Published var matchDurationMinutes: Int = 12 {
        didSet {
            if !timerActive {
                remainingSeconds = matchDurationMinutes * 60
            }
            saveState()
        }
    }

    // Laufender Turnier-Status (bleibt bei Modulwechsel & App-Wechsel erhalten!)
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

    // Timer
    @Published var remainingSeconds: Int = 720 { didSet { saveState() } }
    @Published var timerActive: Bool = false
    private var timerCancellable: AnyCancellable?

    // Buzzer-Zustand & Tonwahl (ebenfalls persistent)
    @Published var buzzerCategory: BuzzerCategory = .sideAndBall { didSet { saveState() } }
    @Published var buzzerSound: BuzzerSoundOption = .classicBuzzer { didSet { saveState() } }
    @Published var lastBuzzerHeadline: String = "Bereit zum Buzzern" { didSet { saveState() } }
    @Published var lastBuzzerSubline: String = "Wähle oben Kategorie & Ton und drücke den Buzzer" { didSet { saveState() } }
    @Published var buzzerPulseCount: Int = 0

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
        }
    }

    var maxAllowedGroups: Int {
        min(6, max(0, teamCount / 2))
    }

    var maxAllowedCourts: Int {
        // Pro Spielfeld werden mindestens 2 spielende Teams benötigt (maximal 6 Felder)
        min(6, max(1, teamCount / 2))
    }

    var effectiveDecidingSetPoints: Int {
        max(10, Int(Double(targetPointsStandard) * 0.6))
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

    var isCurrentStageFinished: Bool {
        let stageMatches = matches.filter { $0.stage == currentStage }
        return !stageMatches.isEmpty && stageMatches.allSatisfy { $0.isFinished }
    }

    var canAdvanceToRound2: Bool {
        currentStage == .round1 && isCurrentStageFinished && groupCount >= 2 && enableCrossSeedRound2
    }

    var canAdvanceToPlacementRound: Bool {
        isCurrentStageFinished && (
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

    private func ensureTeamNameSlots() {
        while teamNames.count < 36 {
            teamNames.append("Team \(teamNames.count + 1)")
        }
    }

    // MARK: - Persistenz (UserDefaults)

    func saveState() {
        guard !isRestoring else { return }
        let snapshot = VolleyballPersistenceSnapshot(
            teamCount: teamCount,
            groupCount: groupCount,
            courtCount: courtCount,
            randomizeInitialGroups: randomizeInitialGroups,
            enableCrossSeedRound2: enableCrossSeedRound2,
            teamNames: teamNames,
            maxSets: maxSets,
            targetPointsStandard: targetPointsStandard,
            isTimeMode: isTimeMode,
            matchDurationMinutes: matchDurationMinutes,
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
            buzzerCategory: buzzerCategory,
            buzzerSound: buzzerSound,
            lastBuzzerHeadline: lastBuzzerHeadline,
            lastBuzzerSubline: lastBuzzerSubline,
            trainingPersonCount: trainingPersonCount,
            trainingTeamCount: trainingTeamCount,
            assignOptionalNamesInTraining: assignOptionalNamesInTraining,
            trainingPlayerNames: trainingPlayerNames,
            remainingTrainingPool: remainingTrainingPool,
            trainingDraws: trainingDraws
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
        randomizeInitialGroups = snapshot.randomizeInitialGroups
        enableCrossSeedRound2 = snapshot.enableCrossSeedRound2
        teamNames = snapshot.teamNames
        ensureTeamNameSlots()
        maxSets = snapshot.maxSets
        targetPointsStandard = snapshot.targetPointsStandard
        isTimeMode = snapshot.isTimeMode
        matchDurationMinutes = snapshot.matchDurationMinutes
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
        buzzerCategory = snapshot.buzzerCategory
        buzzerSound = snapshot.buzzerSound
        lastBuzzerHeadline = snapshot.lastBuzzerHeadline
        lastBuzzerSubline = snapshot.lastBuzzerSubline
        trainingPersonCount = snapshot.trainingPersonCount
        trainingTeamCount = snapshot.trainingTeamCount
        assignOptionalNamesInTraining = snapshot.assignOptionalNamesInTraining
        trainingPlayerNames = snapshot.trainingPlayerNames
        remainingTrainingPool = snapshot.remainingTrainingPool
        trainingDraws = snapshot.trainingDraws
        return true
    }

    // MARK: - Buzzer-Logik (inkl. Sound)

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

        case .trainingTeams:
            drawNextTrainingPerson()
        }
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

        if buzzerCategory == .trainingTeams {
            lastBuzzerHeadline = "Bereit (\(trainingPersonCount) Pers. → \(trainingTeamCount) Teams)"
            lastBuzzerSubline = "Jeder drückt 1× den Buzzer und merkt sich seine Team-Nr."
        }
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
        let activeNames = (0..<teamCount).map { idx -> String in
            let raw = teamNames[idx].trimmingCharacters(in: .whitespacesAndNewlines)
            return raw.isEmpty ? "Team \(idx + 1)" : raw
        }

        var createdTeams = activeNames.map { VolleyballTeam(name: $0) }
        currentStage = .round1

        if groupCount == 0 {
            for i in createdTeams.indices {
                createdTeams[i].groupIndex = nil
            }
            teams = createdTeams
            matches = generateFairScheduleForBuckets(
                buckets: [(groupIndex: nil, label: "Offene Runde", teamIndices: Array(0..<teamCount))],
                roundNumber: 1,
                stage: .round1
            )
        } else {
            var order = Array(0..<teamCount)
            if randomizeInitialGroups {
                order.shuffle()
            }

            var groupBuckets: [[Int]] = Array(repeating: [], count: groupCount)
            for (pos, teamIdx) in order.enumerated() {
                let g = pos % groupCount
                groupBuckets[g].append(teamIdx)
                createdTeams[teamIdx].groupIndex = g
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
        resetMatchState()
        gameStarted = true
        saveState()
    }

    // MARK: - Runde 2: Über-Kreuz- / Schlangen-Setzung (Snake Draft)

    func startRound2CrossSeed() {
        guard canAdvanceToRound2 else { return }
        stopTimer()

        var rankedByGroup: [[Int]] = []
        for g in 0..<groupCount {
            let groupTeams = teams.indices
                .filter { teams[$0].groupIndex == g }
                .sorted { teams[$0].rankScore > teams[$1].rankScore }
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
            tierTeams.sort { teams[$0].rankScore > teams[$1].rankScore }

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

        if groupCount >= 2 {
            var rankedByGroup: [[Int]] = []
            for g in 0..<groupCount {
                let groupTeams = teams.indices
                    .filter { teams[$0].groupIndex == g }
                    .sorted { teams[$0].rankScore > teams[$1].rankScore }
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
            let sortedAll = teams.indices.sorted { teams[$0].rankScore > teams[$1].rankScore }
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

    // MARK: - Spielplan-Generator: Mehrere Spielfelder, faire Pausen & Schiedsgericht

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
        var refCount: [Int: Int] = Dictionary(uniqueKeysWithValues: teams.indices.map { ($0, teams[$0].refereeCount) })

        let effectiveCourts = max(1, min(courtCount, teams.count / 2))
        var timeSlot = 0

        while !pending.isEmpty {
            var busyTeamsInThisSlot: Set<Int> = []
            var slotMatches: [(pair: PendingPair, court: Int)] = []

            // Bis zu `effectiveCourts` parallele Spiele in diesem Zeitslot belegen
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

                    let backToBackPenalty = ((restA == 1) ? -10_000 : 0) + ((restB == 1) ? -10_000 : 0)
                    let minRestBonus = min(restA, restB) * 120 + (restA + restB) * 20
                    let balanceBonus = -((playCount[pair.a] ?? 0) + (playCount[pair.b] ?? 0)) * 50

                    let score = backToBackPenalty + minRestBonus + balanceBonus
                    if score > bestScore {
                        bestScore = score
                        bestIdx = idx
                    }
                }

                let chosen = pending.remove(at: bestIdx)
                busyTeamsInThisSlot.insert(chosen.a)
                busyTeamsInThisSlot.insert(chosen.b)
                slotMatches.append((pair: chosen, court: court))
            }

            // Schiedsgerichte für alle parallelen Spiele dieses Zeitslots vergeben (keiner pfeift 2 Felder gleichzeitig)
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

    // MARK: - Spielsteuerung, Sätze & Timer

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

        if isTimeMode {
            remainingSeconds = matchDurationMinutes * 60
        }
        saveState()
    }

    func finishCurrentSet() {
        guard matches.indices.contains(currentMatchIndex) else { return }
        setHistory.append([currentSetPointsA, currentSetPointsB])

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

            if let nextIdx = matches.firstIndex(where: { !$0.isFinished }) {
                switchToMatch(index: nextIdx)
            }
        } else {
            matches[currentMatchIndex] = match
            currentSetPointsA = 0
            currentSetPointsB = 0
        }
        saveState()
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
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    func resetMatchState() {
        currentSetPointsA = 0
        currentSetPointsB = 0
        currentSetSetsA = 0
        currentSetSetsB = 0
        setHistory.removeAll()
    }

    func startTimer() {
        guard !timerActive else { return }
        timerActive = true
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                } else {
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
        let sortedTeams = teams.sorted { $0.rankScore > $1.rankScore }
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
