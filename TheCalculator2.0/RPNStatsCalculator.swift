//
//  RPNStatsCalculator.swift
//  TheCalculator2.0
//
//  Created by Steffen Beier on 20.11.26.
//

import Foundation

struct RPNStatsCalculator {

    struct StatsSummary {
        let count: Int
        let sum: Double
        let mean: Double
        let populationStdDev: Double
        let sampleStdDev: Double
        let min: Double
        let max: Double
    }

    // MARK: - RPN Stack-Operationen (Index 0 = Stack-Top / X-Register)

    static func push(_ value: Double, onto stack: [Double]) -> [Double] {
        guard value.isFinite else { return stack }
        var next = stack
        next.insert(value, at: 0)
        return next
    }

    static func drop(from stack: [Double]) -> [Double] {
        guard !stack.isEmpty else { return [] }
        return Array(stack.dropFirst())
    }

    static func clearStack() -> [Double] {
        []
    }

    /// Entspricht A>B / Swap der obersten beiden Stack-Elemente (X <-> Y)
    static func swapTopTwo(in stack: [Double]) -> [Double] {
        guard stack.count >= 2 else { return stack }
        var next = stack
        next.swapAt(0, 1)
        return next
    }

    /// Rotiert den gesamten Stack nach oben (Element 0 wandert ans Ende)
    static func rollUp(in stack: [Double]) -> [Double] {
        guard stack.count >= 2 else { return stack }
        var next = Array(stack.dropFirst())
        next.append(stack[0])
        return next
    }

    /// Binäre RPN-Operation auf die obersten beiden Werte (Y op X -> neues X)
    static func applyBinary(_ op: String, on stack: [Double]) -> (stack: [Double], error: String?) {
        guard stack.count >= 2 else {
            return (stack, "Mindestens 2 Werte nötig")
        }
        let x = stack[0]
        let y = stack[1]
        let rest = Array(stack.dropFirst(2))

        let result: Double
        switch op {
        case "+":
            result = y + x
        case "-":
            result = y - x
        case "×", "*":
            result = y * x
        case "÷", "/":
            guard x != 0 else {
                return (stack, "Division durch 0")
            }
            result = y / x
        case "^":
            result = Foundation.pow(y, x)
        default:
            return (stack, "Unbekannter Operator")
        }

        guard result.isFinite else {
            return (stack, "Ungültiger Wert")
        }

        return ([result] + rest, nil)
    }

    /// Unäre RPN-Operation auf den obersten Wert (X)
    static func applyUnary(_ op: String, on stack: [Double]) -> (stack: [Double], error: String?) {
        guard let x = stack.first else {
            return (stack, "Stack ist leer")
        }
        let rest = Array(stack.dropFirst())
        let result: Double

        switch op {
        case "x²":
            result = x * x
        case "√x":
            guard x >= 0 else { return (stack, "Ungültiger Wert") }
            result = Foundation.sqrt(x)
        case "1/x":
            guard x != 0 else { return (stack, "Division durch 0") }
            result = 1.0 / x
        case "+/-":
            result = -x
        default:
            return (stack, "Unbekannte Funktion")
        }

        guard result.isFinite else {
            return (stack, "Ungültiger Wert")
        }

        return ([result] + rest, nil)
    }

    // MARK: - Statistik-Auswertung

    static func summarize(samples: [Double]) -> StatsSummary? {
        let valid = samples.filter { $0.isFinite }
        guard !valid.isEmpty else { return nil }

        let count = valid.count
        let sum = valid.reduce(0, +)
        let mean = sum / Double(count)
        let minVal = valid.min() ?? 0
        let maxVal = valid.max() ?? 0

        let variance = valid.reduce(0.0) { acc, val in
            let diff = val - mean
            return acc + (diff * diff)
        } / Double(count)
        let stdDev = Foundation.sqrt(max(0, variance))

        let sampleVariance: Double = count > 1
            ? valid.reduce(0.0) { acc, val in
                let diff = val - mean
                return acc + (diff * diff)
            } / Double(count - 1)
            : 0.0
        let sampleStdDev = Foundation.sqrt(max(0, sampleVariance))

        return StatsSummary(
            count: count,
            sum: sum,
            mean: mean,
            populationStdDev: stdDev,
            sampleStdDev: sampleStdDev,
            min: minVal,
            max: maxVal
        )
    }
}
