import SwiftUI

enum UnitCategory: String, CaseIterable, Identifiable {
    case currency = "Währungen"
    case weight = "Gewicht / Masse"
    case length = "Länge / Distanz"
    case data = "Speichergrößen (IT)"
    case dataRate = "Datenraten (Netzwerk)"
    case temperature = "Temperatur"
    
    var id: String { self.rawValue }
}

struct UnitConverterView: View {
    @State private var selectedCategory: UnitCategory = .currency
    @State private var inputValue: String = "1"
    
    @State private var fromUnit: String = "EUR (€)"
    @State private var toUnit: String = "PLN (zł)"
    
    // Richtwerte für Währungskurse (Basis: EUR = 1.0)
    let currencyRates: [String: Double] = [
        "EUR (€)": 1.0,
        "CHF (CHF)": 0.94,
        "PLN (zł)": 4.35,      // Polen (Zloty)
        "CZK (Kč)": 25.20,     // Tschechien (Krone)
        "DKK (kr)": 7.46,      // Dänemark (Krone)
        "USD ($)": 1.08,
        "GBP (£)": 0.85
    ]
    
    // Einheiten-Mapping je Kategorie
    var unitsForSelectedCategory: [String] {
        switch selectedCategory {
        case .currency:
            return Array(currencyRates.keys).sorted()
        case .weight:
            return ["Gramm (g)", "Kilogramm (kg)", "Tonne (t)", "Unze (oz)", "Pfund (lb)"]
        case .length:
            return ["Millimeter (mm)", "Zentimeter (cm)", "Meter (m)", "Kilometer (km)", "Zoll / Inch (in)", "Fuß (ft)", "Meile (mi)"]
        case .data:
            return [
                "Byte (B)",
                "Kilobyte (KB - 1000 B)", "Kibibyte (KiB - 1024 B)",
                "Megabyte (MB - 1000 KB)", "Mebibyte (MiB - 1024 KiB)",
                "Gigabyte (GB - 1000 MB)", "Gibibyte (GiB - 1024 MiB)",
                "Terabyte (TB - 1000 GB)", "Tebibyte (TiB - 1024 GiB)",
                "Petabyte (PB - 1000 TB)", "Pebibyte (PiB - 1024 TiB)"
            ]
        case .dataRate:
            return ["Bit/s (bps)", "Kbit/s (Kbps)", "Mbit/s (Mbps)", "Gbit/s (Gbps)"]
        case .temperature:
            return ["Grad Celsius (°C)", "Grad Fahrenheit (°F)", "Kelvin (K)"]
        }
    }
    
    var convertedResult: String {
        guard let value = Double(inputValue.replacingOccurrences(of: ",", with: ".")) else {
            return "Ungültige Eingabe"
        }
        
        switch selectedCategory {
        case .currency:
            guard let fromRate = currencyRates[fromUnit], let toRate = currencyRates[toUnit] else { return "0" }
            let inEUR = value / fromRate
            let result = inEUR * toRate
            return String(format: "%.2f", result).replacingOccurrences(of: ".", with: ",")
            
        case .weight:
            let inGram = convertWeightToGram(value: value, unit: fromUnit)
            let result = convertGramToTarget(gram: inGram, unit: toUnit)
            return String(format: "%.4f", result).replacingOccurrences(of: ".", with: ",")
            
        case .length:
            let inMeter = convertLengthToMeter(value: value, unit: fromUnit)
            let result = convertMeterToTarget(meter: inMeter, unit: toUnit)
            return String(format: "%.4f", result).replacingOccurrences(of: ".", with: ",")
            
        case .data:
            let inBytes = convertDataToBytes(value: value, unit: fromUnit)
            let result = convertBytesToTarget(bytes: inBytes, unit: toUnit)
            return String(format: "%.4f", result).replacingOccurrences(of: ".", with: ",")
            
        case .dataRate:
            let inBps = convertDataRateToBps(value: value, unit: fromUnit)
            let result = convertBpsToTarget(bps: inBps, unit: toUnit)
            return String(format: "%.2f", result).replacingOccurrences(of: ".", with: ",")
            
        case .temperature:
            let result = convertTemperature(val: value, from: fromUnit, to: toUnit)
            return String(format: "%.2f", result).replacingOccurrences(of: ".", with: ",")
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // KATEGORIE SELEKTOR
                VStack(alignment: .leading, spacing: 6) {
                    Text("Kategorie auswählen:")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    Picker("Kategorie", selection: $selectedCategory) {
                        ForEach(UnitCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    .onChange(of: selectedCategory) { _ in
                        if let first = unitsForSelectedCategory.first,
                           let second = unitsForSelectedCategory.dropFirst().first {
                            fromUnit = first
                            toUnit = second
                        }
                    }
                }
                
                // EINGABEWERT
                VStack(alignment: .leading, spacing: 6) {
                    Text("Wert eingeben:")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    TextField("1.0", text: $inputValue)
                        .keyboardType(.decimalPad)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                }
                
                // VON UND ZU AUSWAHL
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Von:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Von", selection: $fromUnit) {
                            ForEach(unitsForSelectedCategory, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .padding(6)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(8)
                    }
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(.orange)
                        .font(.title3)
                        .padding(.top, 16)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nach:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Nach", selection: $toUnit) {
                            ForEach(unitsForSelectedCategory, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .padding(6)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(8)
                    }
                }
                
                // ERGEBNIS-BOX
                VStack(spacing: 6) {
                    Text("Ergebnis:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(convertedResult) \(toUnit)")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .onAppear {
            if let first = unitsForSelectedCategory.first,
               let second = unitsForSelectedCategory.dropFirst().first {
                fromUnit = first
                toUnit = second
            }
        }
    }
    
    // MARK: - Hilfsfunktionen Umrechnung
    private func convertWeightToGram(value: Double, unit: String) -> Double {
        switch unit {
        case "Gramm (g)": return value
        case "Kilogramm (kg)": return value * 1000.0
        case "Tonne (t)": return value * 1_000_000.0
        case "Unze (oz)": return value * 28.3495
        case "Pfund (lb)": return value * 453.592
        default: return value
        }
    }
    
    private func convertGramToTarget(gram: Double, unit: String) -> Double {
        switch unit {
        case "Gramm (g)": return gram
        case "Kilogramm (kg)": return gram / 1000.0
        case "Tonne (t)": return gram / 1_000_000.0
        case "Unze (oz)": return gram / 28.3495
        case "Pfund (lb)": return gram / 453.592
        default: return gram
        }
    }
    
    private func convertLengthToMeter(value: Double, unit: String) -> Double {
        switch unit {
        case "Millimeter (mm)": return value / 1000.0
        case "Zentimeter (cm)": return value / 100.0
        case "Meter (m)": return value
        case "Kilometer (km)": return value * 1000.0
        case "Zoll / Inch (in)": return value * 0.0254
        case "Fuß (ft)": return value * 0.3048
        case "Meile (mi)": return value * 1609.34
        default: return value
        }
    }
    
    private func convertMeterToTarget(meter: Double, unit: String) -> Double {
        switch unit {
        case "Millimeter (mm)": return meter * 1000.0
        case "Zentimeter (cm)": return meter * 100.0
        case "Meter (m)": return meter
        case "Kilometer (km)": return meter / 1000.0
        case "Zoll / Inch (in)": return meter / 0.0254
        case "Fuß (ft)": return meter / 0.3048
        case "Meile (mi)": return meter / 1609.34
        default: return meter
        }
    }
    
    private func convertDataToBytes(value: Double, unit: String) -> Double {
        if unit.contains("Byte (B)") { return value }
        if unit.contains("KiB") { return value * 1024.0 }
        if unit.contains("KB") { return value * 1000.0 }
        if unit.contains("MiB") { return value * pow(1024.0, 2) }
        if unit.contains("MB") { return value * pow(1000.0, 2) }
        if unit.contains("GiB") { return value * pow(1024.0, 3) }
        if unit.contains("GB") { return value * pow(1000.0, 3) }
        if unit.contains("TiB") { return value * pow(1024.0, 4) }
        if unit.contains("TB") { return value * pow(1000.0, 4) }
        if unit.contains("PiB") { return value * pow(1024.0, 5) }
        if unit.contains("PB") { return value * pow(1000.0, 5) }
        return value
    }
    
    private func convertBytesToTarget(bytes: Double, unit: String) -> Double {
        if unit.contains("Byte (B)") { return bytes }
        if unit.contains("KiB") { return bytes / 1024.0 }
        if unit.contains("KB") { return bytes / 1000.0 }
        if unit.contains("MiB") { return bytes / pow(1024.0, 2) }
        if unit.contains("MB") { return bytes / pow(1000.0, 2) }
        if unit.contains("GiB") { return bytes / pow(1024.0, 3) }
        if unit.contains("GB") { return bytes / pow(1000.0, 3) }
        if unit.contains("TiB") { return bytes / pow(1024.0, 4) }
        if unit.contains("TB") { return bytes / pow(1000.0, 4) }
        if unit.contains("PiB") { return bytes / pow(1024.0, 5) }
        if unit.contains("PB") { return bytes / pow(1000.0, 5) }
        return bytes
    }
    
    private func convertDataRateToBps(value: Double, unit: String) -> Double {
        switch unit {
        case "Bit/s (bps)": return value
        case "Kbit/s (Kbps)": return value * 1000.0
        case "Mbit/s (Mbps)": return value * 1_000_000.0
        case "Gbit/s (Gbps)": return value * 1_000_000_000.0
        default: return value
        }
    }
    
    private func convertBpsToTarget(bps: Double, unit: String) -> Double {
        switch unit {
        case "Bit/s (bps)": return bps
        case "Kbit/s (Kbps)": return bps / 1000.0
        case "Mbit/s (Mbps)": return bps / 1_000_000.0
        case "Gbit/s (Gbps)": return bps / 1_000_000_000.0
        default: return bps
        }
    }
    
    private func convertTemperature(val: Double, from: String, to: String) -> Double {
        if from == to { return val }
        var celsius: Double = 0.0
        
        switch from {
        case "Grad Celsius (°C)": celsius = val
        case "Grad Fahrenheit (°F)": celsius = (val - 32.0) * (5.0 / 9.0)
        case "Kelvin (K)": celsius = val - 273.15
        default: break
        }
        
        switch to {
        case "Grad Celsius (°C)": return celsius
        case "Grad Fahrenheit (°F)": return (celsius * 9.0 / 5.0) + 32.0
        case "Kelvin (K)": return celsius + 273.15
        default: return celsius
        }
    }
}
