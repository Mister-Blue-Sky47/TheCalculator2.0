//
//  SokobanView.swift
//  TheCalculator2.0
//
//  Created by Steffen Beier on 17.11.26.
//

import SwiftUI

struct SokobanView: View {
    @State private var levelGrid: [[Int]] = []
    @State private var playerPos: (row: Int, col: Int) = (0, 0)
    @State private var moveCount: Int = 0
    @State private var levelCompleted: Bool = false
    @State private var currentLevel: Int = 1
    
    // 3 korrigierte & knackige Level (0: Boden, 1: Wand, 2: Ziel, 3: Kiste, 4: Spieler)
    private let levels: [[[Int]]] = [
        // Level 1: Klassischer Einstieg
        [
            [1,1,1,1,1,1,1,1],
            [1,0,0,0,0,0,0,1],
            [1,0,4,3,2,0,0,1], // 1 Kiste (3), 1 Ziel (2)
            [1,0,0,1,1,0,0,1],
            [1,0,0,0,0,0,0,1],
            [1,1,1,1,1,1,1,1]
        ],
        // Level 2: Etwas enger mit zwei Kisten
        [
            [1,1,1,1,1,1,1],
            [1,1,0,0,0,1,1],
            [1,0,0,3,2,0,1],
            [1,0,3,4,2,0,1],
            [1,1,0,0,0,1,1],
            [1,1,1,1,1,1,1]
        ],
        // Level 3: Der kleine Denksportler (T-Form)
        [
            [1,1,1,1,1,1,1],
            [1,2,0,1,0,2,1],
            [1,0,3,4,3,0,1],
            [1,1,0,0,0,1,1],
            [1,1,1,1,1,1,1]
        ]
    ]

    var body: some View {
        VStack(spacing: 16) {
            // Header Info
            HStack {
                Text("Level: \(currentLevel) / \(levels.count)")
                    .font(.headline)
                Spacer()
                Text("Züge: \(moveCount)")
                    .font(.system(.body, design: .monospaced))
                    .bold()
                Spacer()
                Button(action: resetLevel) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3)
                }
            }
            .padding(.horizontal)
            
            // Spielfeld Grid
            VStack(spacing: 2) {
                ForEach(0..<levelGrid.count, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<levelGrid[row].count, id: \.self) { col in
                            tileView(for: levelGrid[row][col])
                        }
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            
            // Steuerung (D-Pad)
            VStack(spacing: 8) {
                Button(action: { move(dRow: -1, dCol: 0) }) {
                    Image(systemName: "chevron.up.circle.fill")
                        .font(.system(size: 40))
                }
                HStack(spacing: 40) {
                    Button(action: { move(dRow: 0, dCol: -1) }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 40))
                    }
                    Button(action: { move(dRow: 0, dCol: 1) }) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.system(size: 40))
                    }
                }
                Button(action: { move(dRow: 1, dCol: 0) }) {
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.system(size: 40))
                }
            }
            .foregroundColor(.blue)
            .padding(.top, 10)
            
            if levelCompleted {
                Text("🎉 Level geschafft!")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding(.top, 4)
                
                Button("Nächstes Level") {
                    nextLevel()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            loadLevel(0)
        }
    }
    
    @ViewBuilder
    private func tileView(for type: Int) -> some View {
        ZStack {
            Rectangle()
                .fill(type == 1 ? Color.gray.opacity(0.6) : Color(UIColor.systemBackground))
                .frame(width: 36, height: 36)
                .cornerRadius(4)
            
            switch type {
            case 1: // Wand
                Image(systemName: "square.fill")
                    .foregroundColor(.gray)
            case 2: // Zielpunkt
                Circle()
                    .fill(Color.orange.opacity(0.4))
                    .frame(width: 12, height: 12)
            case 3: // Kiste
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.brown)
                    .frame(width: 28, height: 28)
            case 4: // Spieler
                Image(systemName: "person.fill")
                    .foregroundColor(.blue)
            case 5: // Kiste auf Ziel
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.green)
                    .frame(width: 28, height: 28)
            case 6: // Spieler auf Ziel
                Image(systemName: "person.fill")
                    .foregroundColor(.green)
            default:
                EmptyView()
            }
        }
    }
    
    private func loadLevel(_ index: Int) {
        guard index < levels.count else { return }
        currentLevel = index + 1
        levelGrid = levels[index]
        moveCount = 0
        levelCompleted = false
        
        // Finde Spielerposition
        for r in 0..<levelGrid.count {
            for c in 0..<levelGrid[r].count {
                if levelGrid[r][c] == 4 || levelGrid[r][c] == 6 {
                    playerPos = (r, c)
                }
            }
        }
    }
    
    private func resetLevel() {
        loadLevel(currentLevel - 1)
    }
    
    private func nextLevel() {
        if currentLevel < levels.count {
            loadLevel(currentLevel)
        } else {
            loadLevel(0)
        }
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
            if row.contains(3) { return } // Noch freie Kisten vorhanden
        }
        levelCompleted = true
    }
}
