import Foundation

struct ElektroCalculator {
    
    // MARK: - 1. Ohm'sches Gesetz & Leistung (U, I, R, P)
    struct OhmsLawResult {
        let u: Double // Spannung in Volt
        let i: Double // Strom in Ampere
        let r: Double // Widerstand in Ohm
        let p: Double // Leistung in Watt
    }
    
    /// Berechnet die fehlenden zwei Werte aus zwei bekannten Größen
    static func calculateOhmsLaw(u: Double?, i: Double?, r: Double?, p: Double?) -> OhmsLawResult? {
        var voltage = u
        var current = i
        var resistance = r
        var power = p
        
        // Iterative Auflösung der Formeln U = I*R, P = U*I
        for _ in 0..<3 {
            if let v = voltage, let c = current {
                if resistance == nil { resistance = v / c }
                if power == nil { power = v * c }
            }
            if let v = voltage, let res = resistance {
                if current == nil { current = v / res }
                if power == nil { power = (v * v) / res }
            }
            if let v = voltage, let pow = power {
                if current == nil { current = pow / v }
                if resistance == nil { resistance = (v * v) / pow }
            }
            if let c = current, let res = resistance {
                if voltage == nil { voltage = c * res }
                if power == nil { power = c * c * res }
            }
            if let c = current, let pow = power {
                if voltage == nil { voltage = pow / c }
                if resistance == nil { resistance = pow / (c * c) }
            }
            if let res = resistance, let pow = power {
                if voltage == nil { voltage = sqrt(pow * res) }
                if current == nil { current = sqrt(pow / res) }
            }
        }
        
        guard let finalU = voltage, let finalI = current, let finalR = resistance, let finalP = power else {
            return nil
        }
        
        return OhmsLawResult(u: finalU, i: finalI, r: finalR, p: finalP)
    }
    
    // MARK: - 2. Spannungsfall (Kupferleitung, 1-phasig / DC)
    /// Delta U in Volt und Prozent
    /// - Kappa für Kupfer = 56 m / (Ohm * mm²)
    static func calculateVoltageDrop(voltage: Double, current: Double, lengthMeters: Double, crossSectionMm2: Double) -> (dropVolts: Double, dropPercent: Double) {
        guard crossSectionMm2 > 0, voltage > 0 else { return (0, 0) }
        let kappaKupfer = 56.0
        
        // Formel: deltaU = (2 * L * I) / (kappa * A)
        let dropVolts = (2.0 * lengthMeters * current) / (kappaKupfer * crossSectionMm2)
        let dropPercent = (dropVolts / voltage) * 100.0
        
        return (dropVolts, dropPercent)
    }
    
    // MARK: - 3. USV Akku-Laufzeit
    /// Laufzeit in Minuten
    static func calculateUSVRuntime(loadWatts: Double, batteryVolts: Double, batteryAh: Double, efficiency: Double = 0.85) -> Double {
        guard loadWatts > 0 else { return 0 }
        let totalEnergyWh = batteryVolts * batteryAh
        let usableEnergyWh = totalEnergyWh * efficiency
        let runtimeHours = usableEnergyWh / loadWatts
        return runtimeHours * 60.0 // in Minuten
    }
}
