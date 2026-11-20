//
//  RPNStatsView.swift
//  TheCalculator2.0
//
//  Created by Steffen Beier on 20.11.26.
//

import SwiftUI

struct RPNStatsView: View {
    let formatNumber: (Double) -> String

    @State private var inputText: String = "0"
    @State private var stack: [Double] = []
    @State private var samples: [Double] = []
    @State private var statusMessage: String? = nil

    private var stats: RPNStatsCalculator.StatsSummary? {
        RPNStatsCalculator.summarize(samples: samples)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // RPN-Eingabe & Stack-Anzeige
                VStack(alignment: .trailing, spacing: 6) {
                    HStack {
                        Text("RPN STACK (\(stack.count))")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                        Spacer()
                        if let msg = statusMessage {
                            Text(msg)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.red)
                        }
                    }

                    ForEach(Array(stack.prefix(4).enumerated().reversed()), id: \.offset) { index, value in
                        HStack {
                            Text("[\(index == 0 ? "X" : "S\(index)")]")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatNumber(value))
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        }
                    }

                    Divider()

                    Text(inputText)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                }
                .padding(10)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)

                // Stack-Steuerung (ENTER, CLR, DROP, SWAP/A>B, ROLL)
                HStack(spacing: 6) {
                    actionButton("ENTER", color: .blue) {
                        enterCurrentInput()
                    }
                    actionButton("CLR", color: .red) {
                        clearCurrentInput()
                    }
                    actionButton("DROP", color: .gray) {
                        statusMessage = nil
                        stack = RPNStatsCalculator.drop(from: stack)
                    }
                    actionButton("A>B", color: .orange) {
                        statusMessage = nil
                        stack = RPNStatsCalculator.swapTopTwo(in: stack)
                    }
                    actionButton("ROLL", color: .purple) {
                        statusMessage = nil
                        stack = RPNStatsCalculator.rollUp(in: stack)
                    }
                }

                // Ziffernblock + Operatoren
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(["7", "8", "9", "+", "4", "5", "6", "-", "1", "2", "3", "×", "0", ",", "←", "÷"], id: \.self) { key in
                        gridButton(key) {
                            handleKey(key)
                        }
                    }
                }

                // Unäre Funktionen & Statistik-Übernahme
                HStack(spacing: 8) {
                    actionButton("x²", color: .indigo) { applyUnary("x²") }
                    actionButton("√x", color: .indigo) { applyUnary("√x") }
                    actionButton("+/-", color: .indigo) { applyUnary("+/-") }
                    actionButton("+STAT (x~m)", color: .green) {
                        addCurrentOrTopToStats()
                    }
                }

                // Statistik-Auswertung
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("STATISTIK (\(samples.count) Werte)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                        Spacer()
                        if !samples.isEmpty {
                            Button("Leeren") {
                                samples.removeAll()
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }

                    if let s = stats {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                            statTile("Mittelwert (x̄)", formatNumber(s.mean))
                            statTile("Summe (Σx)", formatNumber(s.sum))
                            statTile("Std.-Abw. (σ)", formatNumber(s.populationStdDev))
                            statTile("Min / Max", "\(formatNumber(s.min)) / \(formatNumber(s.max))")
                        }
                    } else {
                        Text("Noch keine Messwerte erfasst. Nutze „+STAT (x~m)“, um den aktuellen Wert zu übernehmen.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(10)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            }
            .padding()
        }
    }

    private func clearCurrentInput() {
        statusMessage = nil
        inputText = "0"
    }

    private func statTile(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(8)
    }

    private func actionButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(color.opacity(0.2))
                .foregroundColor(color)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private func gridButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(UIColor.tertiarySystemBackground))
                .foregroundColor(.primary)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private func parsedInput() -> Double? {
        let normalized = inputText
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    private func enterCurrentInput() {
        guard let val = parsedInput() else {
            statusMessage = "Ungültige Zahl"
            return
        }
        statusMessage = nil
        stack = RPNStatsCalculator.push(val, onto: stack)
        inputText = "0"
    }

    private func handleKey(_ key: String) {
        statusMessage = nil
        switch key {
        case "←":
            if inputText.count > 1 {
                inputText.removeLast()
            } else {
                inputText = "0"
            }
        case ",":
            if !inputText.contains(",") {
                inputText += ","
            }
        case "+", "-", "×", "÷":
            if let current = parsedInput(), !(inputText == "0" && stack.count >= 2) {
                stack = RPNStatsCalculator.push(current, onto: stack)
                inputText = "0"
            }
            let eval = RPNStatsCalculator.applyBinary(key, on: stack)
            if let err = eval.error {
                statusMessage = err
            } else {
                stack = eval.stack
                if let top = stack.first {
                    inputText = formatNumber(top)
                }
            }
        default:
            if inputText == "0" {
                inputText = key
            } else {
                inputText += key
            }
        }
    }

    private func applyUnary(_ op: String) {
        statusMessage = nil
        if let current = parsedInput(), stack.isEmpty || inputText != "0" {
            stack = RPNStatsCalculator.push(current, onto: stack)
            inputText = "0"
        }
        let eval = RPNStatsCalculator.applyUnary(op, on: stack)
        if let err = eval.error {
            statusMessage = err
        } else {
            stack = eval.stack
            if let top = stack.first {
                inputText = formatNumber(top)
            }
        }
    }

    private func addCurrentOrTopToStats() {
        statusMessage = nil
        if let current = parsedInput(), inputText != "0" {
            samples.append(current)
            inputText = "0"
        } else if let top = stack.first {
            samples.append(top)
        } else if let zeroVal = parsedInput() {
            samples.append(zeroVal)
        }
    }
}
