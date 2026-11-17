import Foundation

struct UnitCalculator {
    
    // MARK: - Einheiten-Kategorien
    enum UnitCategory: String, CaseIterable, Identifiable {
        case length = "Länge / Abstand"
        case temperature = "Temperatur"
        case weight = "Gewicht / Masse"
        case dataRate = "Datenrate"
        case storage = "IT-Speicher"
        case currency = "Währungen"
        
        var id: String { self.rawValue }
    }
    
    // MARK: - Aktuelle Wechselkurse (wird dynamisch aktualisiert, mit Fallback)
    static var liveRatesToEUR: [String: Double] = [
        "EUR": 1.0,
        "USD": 1.08,
        "GBP": 0.85,
        "CHF": 0.95,
        "CNY": 7.85, // Chinesischer Yuan neu hinzugefügt
        "JPY": 162.5, // Japanischer Yen neu hinzugefügt
        "PLN": 4.32,
        "CZK": 25.20,
        "DKK": 7.46
    ]
    
    // Asynchroner Fetch für tagesaktuelle Kurse (z.B. über EZB Referenzraten)
    static func updateLiveRates(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://open.er-api.com/v6/latest/EUR") else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let rates = json["rates"] as? [String: Double] {
                    DispatchQueue.main.async {
                        // Aktualisiere das Dictionary mit Live-Daten
                        for (key, value) in rates {
                            liveRatesToEUR[key] = value
                        }
                        completion(true)
                    }
                } else {
                    DispatchQueue.main.async { completion(false) }
                }
            } catch {
                DispatchQueue.main.async { completion(false) }
            }
        }.resume()
    }
    
    // MARK: - Erweiterte Längenkonvertierung (mit Tiefe: Yard, Meilen, Seemeilen, Lichtjahre etc.)
    static func convertLength(val: Double, from: String, to: String) -> String {
        let toMeters: [String: Double] = [
            "Millimeter (mm)": 0.001,
            "Zentimeter (cm)": 0.01,
            "Dezimeter (dm)": 0.1,
            "Meter (m)": 1.0,
            "Kilometer (km)": 1000.0,
            "Zoll / Inch (in)": 0.0254,
            "Fuß / Feet (ft)": 0.3048,
            "Yard (yd)": 0.9144,
            "Meilen (mi)": 1609.344,
            "Seemeile (nmi)": 1852.0
        ]
        
        guard let factorFrom = toMeters[from], let factorTo = toMeters[to] else { return formatOutput(val) }
        let meters = val * factorFrom
        let result = meters / factorTo
        return formatOutput(result)
    }
    
    static func convertMass(val: Double, from: String, to: String) -> String {
        let toGrams: [String: Double] = [
            "Milligramm (mg)": 0.001,
            "Gramm (g)": 1.0,
            "Kilogramm (kg)": 1000.0,
            "Tonne (t)": 1_000_000.0,
            "Unze (oz)": 28.3495,
            "Pfund (lb)": 453.592
        ]
        guard let fFrom = toGrams[from], let fTo = toGrams[to] else { return formatOutput(val) }
        let grams = val * fFrom
        return formatOutput(grams / fTo)
    }
    
    static func convertTemperature(val: Double, from: String, to: String) -> String {
        var celsius: Double = val
        if from.contains("°F") { celsius = (val - 32.0) * (5.0 / 9.0) }
        else if from.contains("K") { celsius = val - 273.15 }
        
        var result: Double = celsius
        if to.contains("°F") { result = (celsius * 9.0 / 5.0) + 32.0 }
        else if to.contains("K") { result = celsius + 273.15 }
        
        return String(format: "%.2f", result).replacingOccurrences(of: ".", with: ",")
    }
    
    static func convertDataRate(val: Double, from: String, to: String) -> String {
        let toBps: [String: Double] = [
            "Bit/s (bps)": 1.0,
            "Kbit/s (Kbps)": 1e3,
            "Mbit/s (Mbps)": 1e6,
            "Gbit/s (Gbps)": 1e9,
            "Tbit/s (Tbps)": 1e12,
            "Megabyte/s (MB/s)": 8e6,
            "Gigabyte/s (GB/s)": 8e9
        ]
        guard let factorFrom = toBps[from], let factorTo = toBps[to] else { return formatOutput(val) }
        let result = (val * factorFrom) / factorTo
        return formatOutput(result)
    }
    
    static func convertStorage(val: Double, from: String, to: String) -> String {
        let toBytes: [String: Double] = [
            "Bit (bit)": 0.125,
            "Byte (B)": 1.0,
            "Kilobyte (KB)": 1e3,
            "Megabyte (MB)": 1e6,
            "Gigabyte (GB)": 1e9,
            "Terabyte (TB)": 1e12,
            "Petabyte (PB)": 1e15,
            "Kibibyte (KiB)": 1024.0,
            "Mebibyte (MiB)": pow(1024, 2),
            "Gibibyte (GiB)": pow(1024, 3),
            "Tebibyte (TiB)": pow(1024, 4)
        ]
        guard let factorFrom = toBytes[from], let factorTo = toBytes[to] else { return formatOutput(val) }
        let result = (val * factorFrom) / factorTo
        return formatOutput(result)
    }
    
    // MARK: - Währungskonvertierung mit tagesaktuellen Kursen
    static func convertCurrency(val: Double, from: String, to: String) -> String {
        let fromCode = String(from.prefix(3))
        let toCode = String(to.prefix(3))
        
        guard let rateFrom = liveRatesToEUR[fromCode], let rateTo = liveRatesToEUR[toCode] else { return "0,00" }
        let eurVal = val / rateFrom
        let result = eurVal * rateTo
        
        return String(format: "%.2f", result).replacingOccurrences(of: ".", with: ",")
    }
    
    static func formatOutput(_ val: Double) -> String {
        if val == 0 { return "0" }
        let absVal = abs(val)
        if absVal >= 1e15 || (absVal > 0 && absVal < 0.0001) {
            return String(format: "%.4e", val).replacingOccurrences(of: ".", with: ",")
        } else if val.truncatingRemainder(dividingBy: 1) == 0 && absVal < 1e15 {
            return String(format: "%.0f", val)
        } else {
            let formatted = String(format: "%.6f", val)
            let trimmed = formatted.replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression)
                                   .replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
            return trimmed.replacingOccurrences(of: ".", with: ",")
        }
    }
}
