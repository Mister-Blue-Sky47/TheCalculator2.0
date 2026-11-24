//
//  SokobanView.swift
//  TheCalculator2.0
//
//  Created by Steffen Beier on 17.11.26.
//

import SwiftUI

// MARK: - Spielerprofil & Spielstand-Modelle

private struct SokobanPlayerSave: Codable, Identifiable {
    var id: String { name }
    var name: String
    var currentLevel: Int
    var unlockedLevel: Int
    var bestMovesByLevel: [Int: Int]
    var savedGrid: [[Int]]?
    var savedMoveCount: Int
    var savedLevelNumber: Int?
}

private struct SokobanPersistenceBlob: Codable {
    var activePlayerName: String
    var players: [SokobanPlayerSave]
}

// MARK: - Sokoban View

struct SokobanView: View {
    private static let totalLevelCount = 300
    private static let storageKey = "SokobanView.profiles.v1"

    @State private var playerNameInput: String = ""
    @State private var activePlayerName: String = "Spieler 1"
    @State private var players: [SokobanPlayerSave] = []
    @State private var showPlayerSheet: Bool = false

    @State private var levelGrid: [[Int]] = []
    @State private var playerPos: (row: Int, col: Int) = (0, 0)
    @State private var moveCount: Int = 0
    @State private var levelCompleted: Bool = false
    @State private var currentLevel: Int = 1
    @State private var unlockedLevel: Int = 1
    @State private var bestMovesByLevel: [Int: Int] = [:]

    // 3 handgebaute Einstiegslevel (0: Boden, 1: Wand, 2: Ziel, 3: Kiste, 4: Spieler)
    private let handcraftedLevels: [[[Int]]] = [
        // Level 1: Klassischer Einstieg
        [
            [1,1,1,1,1,1,1,1],
            [1,0,0,0,0,0,0,1],
            [1,0,4,3,2,0,0,1],
            [1,0,0,1,1,0,0,1],
            [1,0,0,0,0,0,0,1],
            [1,1,1,1,1,1,1,1]
        ],
        // Level 2: Zwei Kisten mit sauberem Manövrierraum
        [
            [1,1,1,1,1,1,1],
            [1,1,0,0,0,1,1],
            [1,0,0,3,2,0,1],
            [1,0,3,4,2,0,1],
            [1,1,0,0,0,1,1],
            [1,1,1,1,1,1,1]
        ],
        // Level 3: Korrigiert & flüssig lösbar (genug Freiraum um die Ziele)
        [
            [1,1,1,1,1,1,1,1],
            [1,0,2,0,0,2,0,1],
            [1,0,0,3,4,3,0,1],
            [1,0,0,0,0,0,0,1],
            [1,1,1,0,1,1,1,1],
            [1,1,1,1,1,1,1,1]
        ]
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                playerHeaderBar
                levelStatusBar
                boardCard
                dPadControls

                if levelCompleted {
                    completionBanner
                }
            }
            .padding()
        }
        .navigationTitle("Sokoban")
        .sheet(isPresented: $showPlayerSheet) {
            playerLoginSheet
        }
        .onAppear {
            loadProfilesAndResume()
        }
    }

    // MARK: - Spieler-Login-Leiste

    private var playerHeaderBar: some View {
        HStack(spacing: 10) {
            Label(activePlayerName, systemImage: "person.crop.circle.fill")
                .font(.subheadline.bold())
                .lineLimit(1)

            Text("Max: Level \(unlockedLevel)")
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.teal.opacity(0.18))
                .foregroundColor(.teal)
                .cornerRadius(6)

            Spacer()

            Button {
                playerNameInput = ""
                showPlayerSheet = true
            } label: {
                Label("Login / Wechsel", systemImage: "key.fill")
                    .font(.caption.bold())
            }
            .buttonStyle(.bordered)
            .tint(.orange)
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }

    // MARK: - Level- & Zuganzeige

    private var levelStatusBar: some View {
        HStack {
            Stepper("Level: \(currentLevel) / \(Self.totalLevelCount)", value: Binding(
                get: { currentLevel },
                set: { newVal in
                    let maxAllowed = max(unlockedLevel, currentLevel)
                    let clamped = min(max(newVal, 1), min(maxAllowed, Self.totalLevelCount))
                    startFreshLevel(clamped)
                }
            ), in: 1...Self.totalLevelCount)
            .font(.headline)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Züge: \(moveCount)")
                    .font(.system(.body, design: .monospaced))
                    .bold()
                if let best = bestMovesByLevel[currentLevel] {
                    Text("Rekord: \(best)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Button(action: resetLevel) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title3)
            }
            .padding(.leading, 4)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Spielfeld

    private var boardCard: some View {
        let cols = max(1, levelGrid.first?.count ?? 7)
        let tileSize: CGFloat = cols > 9 ? 28 : 36

        return VStack(spacing: 2) {
            ForEach(0..<levelGrid.count, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<levelGrid[row].count, id: \.self) { col in
                        tileView(for: levelGrid[row][col], size: tileSize)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func tileView(for type: Int, size: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(type == 1 ? Color.gray.opacity(0.6) : Color(UIColor.systemBackground))
                .frame(width: size, height: size)
                .cornerRadius(4)

            switch type {
            case 1:
                Image(systemName: "square.fill")
                    .font(.system(size: size * 0.45))
                    .foregroundColor(.gray)
            case 2:
                Circle()
                    .fill(Color.orange.opacity(0.45))
                    .frame(width: size * 0.34, height: size * 0.34)
            case 3:
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.brown)
                    .frame(width: size * 0.78, height: size * 0.78)
            case 4:
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.48))
                    .foregroundColor(.blue)
            case 5:
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.green)
                    .frame(width: size * 0.78, height: size * 0.78)
            case 6:
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.48))
                    .foregroundColor(.green)
            default:
                EmptyView()
            }
        }
    }

    // MARK: - Steuerkreuz

    private var dPadControls: some View {
        VStack(spacing: 8) {
            Button(action: { move(dRow: -1, dCol: 0) }) {
                Image(systemName: "chevron.up.circle.fill")
                    .font(.system(size: 42))
            }
            HStack(spacing: 44) {
                Button(action: { move(dRow: 0, dCol: -1) }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 42))
                }
                Button(action: { move(dRow: 0, dCol: 1) }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 42))
                }
            }
            Button(action: { move(dRow: 1, dCol: 0) }) {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.system(size: 42))
            }
        }
        .foregroundColor(.blue)
        .padding(.top, 4)
    }

    private var completionBanner: some View {
        VStack(spacing: 8) {
            Text("🎉 Level \(currentLevel) geschafft in \(moveCount) Zügen!")
                .font(.headline)
                .foregroundColor(.green)

            Button("Nächstes Level") {
                nextLevel()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.12))
        .cornerRadius(12)
    }

    // MARK: - Login- & Profil-Sheet

    private var playerLoginSheet: some View {
        NavigationStack {
            List {
                Section(header: Text("Neuer Spieler / Login")) {
                    HStack {
                        TextField("Spielername eingeben", text: $playerNameInput)
                            .textFieldStyle(.roundedBorder)

                        Button("Login") {
                            let clean = playerNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !clean.isEmpty else { return }
                            loginAsPlayer(name: clean)
                            showPlayerSheet = false
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(playerNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Section(header: Text("Gespeicherte Spielerprofile")) {
                    ForEach(players) { profile in
                        Button {
                            loginAsPlayer(name: profile.name)
                            showPlayerSheet = false
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Aktuell: Level \(profile.currentLevel) • Freigeschaltet bis: Level \(profile.unlockedLevel)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if profile.name == activePlayerName {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Spieler-Login")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Schließen") { showPlayerSheet = false }
                }
            }
        }
    }

    // MARK: - Level-Erzeugung (3 handgebaute + bis zu 300 deterministische Level)

    private func gridForLevel(_ levelNumber: Int) -> [[Int]] {
        if levelNumber >= 1 && levelNumber <= handcraftedLevels.count {
            return handcraftedLevels[levelNumber - 1]
        }
        return generateProceduralLevel(levelNumber: levelNumber)
    }

    /// Deterministischer Level-Generator: Gleiche Levelnummer = gleiches Layout, ohne Kisten direkt in Ecken
    private func generateProceduralLevel(levelNumber: Int) -> [[Int]] {
        let rows = min(9, 6 + (levelNumber / 25))
        let cols = min(10, 7 + (levelNumber / 20))
        let boxCount = min(5, 2 + (levelNumber / 18))

        // Einfacher deterministischer LCG-Zufallszahlengenerator pro Levelnummer
        var rngState: UInt64 = UInt64(levelNumber) &* 6364136223846793005 &+ 1442695040888963407
        func nextRand(_ upper: Int) -> Int {
            rngState = rngState &* 6364136223846793005 &+ 1442695040888963407
            return Int((rngState >> 33) % UInt64(max(1, upper)))
        }

        var grid = Array(repeating: Array(repeating: 0, count: cols), count: rows)
        for r in 0..<rows {
            for c in 0..<cols {
                if r == 0 || r == rows - 1 || c == 0 || c == cols - 1 {
                    grid[r][c] = 1
                }
            }
        }

        // Innenwände setzen (aber Mittelkorridor und Ziel-/Kistenzonen offen halten)
        let wallAttempts = min(6, 1 + levelNumber / 10)
        for _ in 0..<wallAttempts {
            let wr = 2 + nextRand(max(1, rows - 4))
            let wc = 2 + nextRand(max(1, cols - 4))
            if !(wr == rows / 2 || wc == cols / 2) {
                grid[wr][wc] = 1
            }
        }

        var freeCells: [(Int, Int)] = []
        for r in 2...(rows - 3) {
            for c in 2...(cols - 3) {
                if grid[r][c] == 0 {
                    freeCells.append((r, c))
                }
            }
        }

        // Ziele platzieren
        var placedGoals = 0
        while placedGoals < boxCount && !freeCells.isEmpty {
            let pos = freeCells.remove(at: nextRand(freeCells.count))
            grid[pos.0][pos.1] = 2
            placedGoals += 1
        }

        // Kisten nicht direkt in Eck- oder Wand-Sackgassen setzen
        var placedBoxes = 0
        var guardCounter = 0
        while placedBoxes < boxCount && !freeCells.isEmpty && guardCounter < 100 {
            guardCounter += 1
            let pos = freeCells.remove(at: nextRand(freeCells.count))
            let r = pos.0, c = pos.1
            let wallUp = grid[r - 1][c] == 1
            let wallDown = grid[r + 1][c] == 1
            let wallLeft = grid[r][c - 1] == 1
            let wallRight = grid[r][c + 1] == 1
            let isCornerDeadEnd = (wallUp && wallLeft) || (wallUp && wallRight) || (wallDown && wallLeft) || (wallDown && wallRight)
            if !isCornerDeadEnd && grid[r][c] == 0 {
                grid[r][c] = 3
                placedBoxes += 1
            }
        }

        // Spieler auf ein freies Feld setzen
        if let pCell = freeCells.first(where: { grid[$0.0][$0.1] == 0 }) {
            grid[pCell.0][pCell.1] = 4
        } else {
            grid[rows / 2][cols / 2] = 4
        }

        return grid
    }

    // MARK: - Spiel- & Speicherlogik

    private func startFreshLevel(_ levelNumber: Int) {
        currentLevel = min(max(levelNumber, 1), Self.totalLevelCount)
        levelGrid = gridForLevel(currentLevel)
        moveCount = 0
        levelCompleted = false
        locatePlayer()
        persistCurrentPlayerState(clearSavedGrid: true)
    }

    private func locatePlayer() {
        for r in 0..<levelGrid.count {
            for c in 0..<levelGrid[r].count {
                if levelGrid[r][c] == 4 || levelGrid[r][c] == 6 {
                    playerPos = (r, c)
                    return
                }
            }
        }
    }

    private func resetLevel() {
        startFreshLevel(currentLevel)
    }

    private func nextLevel() {
        let next = min(currentLevel + 1, Self.totalLevelCount)
        if next > unlockedLevel {
            unlockedLevel = next
        }
        startFreshLevel(next)
    }

    private func move(dRow: Int, dCol: Int) {
        guard !levelCompleted else { return }

        let newR = playerPos.row + dRow
        let newC = playerPos.col + dCol

        guard newR >= 0 && newR < levelGrid.count && newC >= 0 && newC < levelGrid[0].count else { return }

        let targetVal = levelGrid[newR][newC]
        if targetVal == 1 { return }

        if targetVal == 0 || targetVal == 2 {
            updatePlayerPosition(newR: newR, newC: newC)
            moveCount += 1
            persistCurrentPlayerState(clearSavedGrid: false)
        } else if targetVal == 3 || targetVal == 5 {
            let nextBoxR = newR + dRow
            let nextBoxC = newC + dCol

            guard nextBoxR >= 0 && nextBoxR < levelGrid.count && nextBoxC >= 0 && nextBoxC < levelGrid[0].count else { return }
            let behindBoxVal = levelGrid[nextBoxR][nextBoxC]

            if behindBoxVal == 0 || behindBoxVal == 2 {
                levelGrid[nextBoxR][nextBoxC] = (behindBoxVal == 2) ? 5 : 3
                levelGrid[newR][newC] = (targetVal == 5) ? 6 : 4

                let oldR = playerPos.row
                let oldC = playerPos.col
                let oldVal = levelGrid[oldR][oldC]
                levelGrid[oldR][oldC] = (oldVal == 6) ? 2 : 0

                playerPos = (newR, newC)
                moveCount += 1
                checkWinCondition()
                persistCurrentPlayerState(clearSavedGrid: levelCompleted)
            }
        }
    }

    private func updatePlayerPosition(newR: Int, newC: Int) {
        let oldR = playerPos.row
        let oldC = playerPos.col

        let oldVal = levelGrid[oldR][oldC]
        levelGrid[oldR][oldC] = (oldVal == 6) ? 2 : 0

        let newVal = levelGrid[newR][newC]
        levelGrid[newR][newC] = (newVal == 2) ? 6 : 4

        playerPos = (newR, newC)
        checkWinCondition()
    }

    private func checkWinCondition() {
        for row in levelGrid {
            if row.contains(3) { return }
        }
        levelCompleted = true
        if let prevBest = bestMovesByLevel[currentLevel] {
            bestMovesByLevel[currentLevel] = min(prevBest, moveCount)
        } else {
            bestMovesByLevel[currentLevel] = moveCount
        }
        if currentLevel >= unlockedLevel && currentLevel < Self.totalLevelCount {
            unlockedLevel = currentLevel + 1
        }
    }

    // MARK: - Persistenz pro Spieler

    private func loadProfilesAndResume() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let blob = try? JSONDecoder().decode(SokobanPersistenceBlob.self, from: data),
           !blob.players.isEmpty {
            players = blob.players
            let active = blob.players.first(where: { $0.name == blob.activePlayerName }) ?? blob.players[0]
            applyProfile(active)
        } else {
            let defaultProfile = SokobanPlayerSave(
                name: "Spieler 1",
                currentLevel: 1,
                unlockedLevel: 1,
                bestMovesByLevel: [:],
                savedGrid: nil,
                savedMoveCount: 0,
                savedLevelNumber: nil
            )
            players = [defaultProfile]
            applyProfile(defaultProfile)
            saveAllProfiles()
        }
    }

    private func loginAsPlayer(name: String) {
        persistCurrentPlayerState(clearSavedGrid: false)
        if let existing = players.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            applyProfile(existing)
        } else {
            let created = SokobanPlayerSave(
                name: name,
                currentLevel: 1,
                unlockedLevel: 1,
                bestMovesByLevel: [:],
                savedGrid: nil,
                savedMoveCount: 0,
                savedLevelNumber: nil
            )
            players.append(created)
            applyProfile(created)
        }
        saveAllProfiles()
    }

    private func applyProfile(_ profile: SokobanPlayerSave) {
        activePlayerName = profile.name
        unlockedLevel = profile.unlockedLevel
        bestMovesByLevel = profile.bestMovesByLevel

        if let grid = profile.savedGrid, !grid.isEmpty, let lvl = profile.savedLevelNumber {
            currentLevel = lvl
            levelGrid = grid
            moveCount = profile.savedMoveCount
            levelCompleted = false
            locatePlayer()
            checkWinCondition()
        } else {
            currentLevel = profile.currentLevel
            levelGrid = gridForLevel(currentLevel)
            moveCount = 0
            levelCompleted = false
            locatePlayer()
        }
    }

    private func persistCurrentPlayerState(clearSavedGrid: Bool) {
        let updated = SokobanPlayerSave(
            name: activePlayerName,
            currentLevel: currentLevel,
            unlockedLevel: unlockedLevel,
            bestMovesByLevel: bestMovesByLevel,
            savedGrid: clearSavedGrid ? nil : levelGrid,
            savedMoveCount: clearSavedGrid ? 0 : moveCount,
            savedLevelNumber: clearSavedGrid ? nil : currentLevel
        )
        if let idx = players.firstIndex(where: { $0.name == activePlayerName }) {
            players[idx] = updated
        } else {
            players.append(updated)
        }
        saveAllProfiles()
    }

    private func saveAllProfiles() {
        let blob = SokobanPersistenceBlob(activePlayerName: activePlayerName, players: players)
        if let data = try? JSONEncoder().encode(blob) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
