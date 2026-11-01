import Foundation

struct UnitCalculator {
    
    // MARK: - Einheiten-Kategorien
    enum UnitCategory: String, CaseIterable, Identifiable {
        case length = "Länge / Abstand"
        case temperature = "Temperatur"
        case weight = "Gewicht / Masse"
        case currency = "Währung (Festkurse)"
        
        var id: String { self.rawValue }
    }
    
    // MARK: - Länge (Basis: Meter)
    static func convertLength(value: Double, from: String, to: String) -> Double {
        let toMeters: [String: Double] = [
            "Meter (m)": 1.0,
            "Zoll / Inch (in)": 0.0254,
            "Fuß / Feet (ft)": 0.3048,
            "Yard (yd)": 0.9144,
            "Meilen (mi)": 1609.344,
            "Kilometer (km)": 1000.0,
            "Zentimeter (cm)": 0.01,
            "Millimeter (mm)": 0.001,
            "Lichtjahre (ly)": 9_460_730_472_580_800.0,
            "Astron. Einheiten (AU)": 149_597_870_700.0
        ]
        
        guard let factorFrom = toMeters[from], let factorTo = toMeters[to] else { return value }
        let meters = value * factorFrom
        return meters / factorTo
    }
    
    // MARK: - Temperatur
    static func convertTemperature(value: Double, from: String, to: String) -> Double {
        if from == to { return value }
        
        // Zuerst in Celsius umwandeln
        var celsius: Double = value
        switch from {
        case "Fahrenheit (°F)": celsius = (value - 32.0) * (5.0 / 9.0)
        case "Kelvin (K)": celsius = value - 273.15
        default: break // Celsius
        }
        
        // Von Celsius in Zielformat
        switch to {
        case "Fahrenheit (°F)": return (celsius * 9.0 / 5.0) + 32.0
        case "Kelvin (K)": return celsius + 273.15
        default: return celsius
        }
    }
    
    // MARK: - Währung (Beispielhafte Standardkurse zum EUR)
    static func convertCurrency(value: Double, from: String, to: String) -> Double {
        let toEUR: [String: Double] = [
            "EUR (€)": 1.0,
            "USD ($)": 0.92,
            "GBP (£)": 1.17,
            "CHF (Fr.)": 1.05,
            "JPY (¥)": 0.0062
        ]
        
        guard let factorFrom = toEUR[from], let factorTo = toEUR[to] else { return value }
        let eur = value * factorFrom
        return eur / factorTo
    }
}
