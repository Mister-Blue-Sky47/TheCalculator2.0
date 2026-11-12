import SwiftUI

// MARK: - Resistor Color Code Models
enum ResistorColor: String, CaseIterable, Identifiable {
    case black = "Schwarz"
    case brown = "Braun"
    case red = "Rot"
    case orange = "Orange"
    case yellow = "Gelb"
    case green = "Grün"
    case blue = "Blau"
    case violet = "Violett"
    case gray = "Grau"
    case white = "Weiß"
    case gold = "Gold"
    case silver = "Silber"

    var id: String { self.rawValue }

    var displayColor: Color {
        switch self {
        case .black: return .black
        case .brown: return Color(red: 0.55, green: 0.27, blue: 0.07)
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .violet: return .purple
        case .gray: return .gray
        case .white: return .white
        case .gold: return Color(red: 0.85, green: 0.65, blue: 0.13)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.75)
        }
    }

    var digitValue: Int? {
        switch self {
        case .black: return 0
        case .brown: return 1
        case .red: return 2
        case .orange: return 3
        case .yellow: return 4
        case .green: return 5
        case .blue: return 6
        case .violet: return 7
        case .gray: return 8
        case .white: return 9
        default: return nil
        }
    }

    var multiplier: Double {
        switch self {
        case .black: return 1
        case .brown: return 10
        case .red: return 100
        case .orange: return 1_000
        case .yellow: return 10_000
        case .green: return 100_000
        case .blue: return 1_000_000
        case .violet: return 10_000_000
        case .gray: return 100_000_000
        case .white: return 1_000_000_000
        case .gold: return 0.1
        case .silver: return 0.01
        }
    }

    var toleranceString: String {
        switch self {
        case .brown: return "±1%"
        case .red: return "±2%"
        case .green: return "±0.5%"
        case .blue: return "±0.25%"
        case .violet: return "±0.1%"
        case .gray: return "±0.05%"
        case .gold: return "±5%"
        case .silver: return "±10%"
        default: return "-"
        }
    }
}

struct ResistorCalculator {
    static func calculate4Band(ring1: ResistorColor, ring2: ResistorColor, multiplier: ResistorColor, tolerance: ResistorColor) -> (value: Double, formatted: String, tol: String) {
        let v1 = ring1.digitValue ?? 0
        let v2 = ring2.digitValue ?? 0
        let base = Double(v1 * 10 + v2)
        let total = base * multiplier.multiplier
        return (total, formatOhm(total), tolerance.toleranceString)
    }

    static func parallel(r1: Double, r2: Double) -> Double {
        guard (r1 + r2) > 0 else { return 0 }
        return (r1 * r2) / (r1 + r2)
    }

    static func series(r1: Double, r2: Double) -> Double {
        return r1 + r2
    }

    static func formatOhm(_ val: Double) -> String {
        if val >= 1_000_000 {
            return String(format: "%.2f MΩ", val / 1_000_000)
        } else if val >= 1_000 {
            return String(format: "%.2f kΩ", val / 1_000)
        } else {
            return String(format: "%.1f Ω", val)
        }
    }
}

struct ElektroCalculator {
    struct OhmsLawResult {
        let u: Double
        let i: Double
        let r: Double
        let p: Double
    }
    
    static func calculateOhmsLaw(u: Double?, i: Double?, r: Double?, p: Double?) -> OhmsLawResult? {
        if let u = u, let i = i {
            return OhmsLawResult(u: u, i: i, r: u / i, p: u * i)
        } else if let u = u, let r = r, r != 0 {
            return OhmsLawResult(u: u, i: u / r, r: r, p: (u * u) / r)
        } else if let i = i, let r = r {
            return OhmsLawResult(u: i * r, i: i, r: r, p: i * i * r)
        } else if let p = p, let u = u, u != 0 {
            return OhmsLawResult(u: u, i: p / u, r: (u * u) / p, p: p)
        } else if let p = p, let i = i, i != 0 {
            return OhmsLawResult(u: p / i, i: i, r: p / (i * i), p: p)
        }
        return nil
    }
    
    static func calculateVoltageDrop(voltage: Double, current: Double, lengthMeter: Double, crossSection: Double) -> (dropVolts: Double, dropPercent: Double) {
        let kappa: Double = 56.0 // Kupfer
        let dropV = (2.0 * lengthMeter * current) / (kappa * crossSection)
        let dropPct = (dropV / voltage) * 100.0
        return (dropV, dropPct)
    }
    
    static func calculateUSVRuntime(loadWatt: Double, batteryVolts: Double, batteryAh: Double) -> Double {
        guard loadWatt > 0 else { return 0 }
        let totalWh = batteryVolts * batteryAh * 0.85 // 85% Wirkungsgrad
        return (totalWh / loadWatt) * 60.0
    }
}
