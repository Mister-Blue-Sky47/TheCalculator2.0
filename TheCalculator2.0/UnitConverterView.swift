// xcode: set sdk=iOS

import SwiftUI

struct UnitConverterView: View {
    @State private var inputValue: String = "1"
    @State private var selectedCategory: UnitCategory = .mass
    @State private var sourceUnit: String = "Gramm (g)"
    @State private var targetUnit: String = "Kilogramm (kg)"
    
    enum UnitCategory: String, CaseIterable, Identifiable {
        case length = "Länge"
        case mass = "Gewicht / Masse"
        case temperature = "Temperatur"
        case dataRate = "Datenrate"
        case storage = "IT-Speicher"
        case currency = "Währungen"
        
        var id: String { self.rawValue }
    }
    
    var convertedValue: String {
        guard let val = Double(inputValue.replacingOccurrences(of: ",", with: ".")) else { return "0" }
        
        switch selectedCategory {
        case .length:
            return convertLength(val: val, from: sourceUnit, to: targetUnit)
        case .mass:
            return convertMass(val: val, from: sourceUnit, to: targetUnit)
        case .temperature:
            return convertTemperature(val: val, from: sourceUnit, to: targetUnit)
        case .dataRate:
            return convertDataRate(val: val, from: sourceUnit, to: targetUnit)
        case .storage:
            return convertStorage(val: val, from: sourceUnit, to: targetUnit)
        case .currency:
            return convertCurrency(val: val, from: sourceUnit, to: targetUnit)
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // 1. Kategorie-Auswahl
            VStack(alignment: .leading, spacing: 4) {
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
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(8)
                .onChange(of: selectedCategory) { _ in
                    resetUnitsForCategory()
                }
            }
            .padding(.horizontal, 12)
            
            // 2. Wert-Eingabe
            VStack(alignment: .leading, spacing: 4) {
                Text("Wert eingeben:")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                TextField("Wert", text: $inputValue)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .padding(8)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 12)
            
            // 3. Von / Nach Umrechnungs-Picker (Nebeneinander ohne Überlappung)
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Von:")
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.secondary)
                    
                    Picker("Von", selection: $sourceUnit) {
                        ForEach(availableUnits(), id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(8)
                }
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.orange)
                    .padding(.top, 14)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nach:")
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.secondary)
                    
                    Picker("Nach", selection: $targetUnit) {
                        ForEach(availableUnits(), id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 12)
            
            // 4. Ergebnis-Box (Sauber getrennt)
            VStack(alignment: .leading, spacing: 4) {
                Text("Ergebnis:")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(convertedValue)
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(targetUnit)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.primary)
                }
                .padding(10)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            }
            .padding(.horizontal, 12)
            
            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }
    
    // MARK: - Helper Logik
    private func resetUnitsForCategory() {
        let units = availableUnits()
        if let first = units.first, let second = units.dropFirst().first {
            sourceUnit = first
            targetUnit = second
        }
    }
    
    private func availableUnits() -> [String] {
        switch selectedCategory {
        case .length:
            return ["Millimeter (mm)", "Zentimeter (cm)", "Meter (m)", "Kilometer (km)", "Zoll (in)", "Fuß (ft)", "Meilen (mi)"]
        case .mass:
            return ["Gramm (g)", "Kilogramm (kg)", "Tonne (t)", "Unze (oz)", "Pfund (lb)"]
        case .temperature:
            return ["Grad Celsius (°C)", "Grad Fahrenheit (°F)", "Kelvin (K)"]
        case .dataRate:
            return ["Bit/s (bps)", "Kbit/s (Kbps)", "Mbit/s (Mbps)", "Gbit/s (Gbps)"]
        case .storage:
            return ["Byte (B)", "Kilobyte (KB)", "Megabyte (MB)", "Gigabyte (GB)", "Kibibyte (KiB)", "Mebibyte (MiB)", "Gibibyte (GiB)"]
        case .currency:
            return ["EUR (€)", "USD ($)", "GBP (£)", "CHF (Fr.)", "PLN (zł)", "CZK (Kč)", "DKK (kr.)"]
        }
    }
    
    private func convertLength(val: Double, from: String, to: String) -> String {
        var meters: Double = val
        if from.contains("(mm)") { meters = val / 1000.0 }
        else if from.contains("(cm)") { meters = val / 100.0 }
        else if from.contains("(km)") { meters = val * 1000.0 }
        else if from.contains("(in)") { meters = val * 0.0254 }
        else if from.contains("(ft)") { meters = val * 0.3048 }
        else if from.contains("(mi)") { meters = val * 1609.344 }
        
        var result: Double = meters
        if to.contains("(mm)") { result = meters * 1000.0 }
        else if to.contains("(cm)") { result = meters * 100.0 }
        else if to.contains("(km)") { result = meters / 1000.0 }
        else if to.contains("(in)") { result = meters / 0.0254 }
        else if to.contains("(ft)") { result = meters / 0.3048 }
        else if to.contains("(mi)") { result = meters / 1609.344 }
        
        return formatOutput(result)
    }
    
    private func convertMass(val: Double, from: String, to: String) -> String {
        var grams: Double = val
        if from.contains("(kg)") { grams = val * 1000.0 }
        else if from.contains("(t)") { grams = val * 1_000_000.0 }
        else if from.contains("(oz)") { grams = val * 28.3495 }
        else if from.contains("(lb)") { grams = val * 453.592 }
        
        var result: Double = grams
        if to.contains("(kg)") { result = grams / 1000.0 }
        else if to.contains("(t)") { result = grams / 1_000_000.0 }
        else if to.contains("(oz)") { result = grams / 28.3495 }
        else if to.contains("(lb)") { result = grams / 453.592 }
        
        return formatOutput(result)
    }
    
    private func convertTemperature(val: Double, from: String, to: String) -> String {
        var celsius: Double = val
        if from.contains("°F") { celsius = (val - 32.0) * (5.0 / 9.0) }
        else if from.contains("K") { celsius = val - 273.15 }
        
        var result: Double = celsius
        if to.contains("°F") { result = (celsius * 9.0 / 5.0) + 32.0 }
        else if to.contains("K") { result = celsius + 273.15 }
        
        return String(format: "%.2f", result).replacingOccurrences(of: ".", with: ",")
    }
    
    private func convertDataRate(val: Double, from: String, to: String) -> String {
        var bps: Double = val
        if from.contains("Kbps") { bps = val * 1000.0 }
        else if from.contains("Mbps") { bps = val * 1_000_000.0 }
        else if from.contains("Gbps") { bps = val * 1_000_000_000.0 }
        
        var result: Double = bps
        if to.contains("Kbps") { result = bps / 1000.0 }
        else if to.contains("Mbps") { result = bps / 1_000_000.0 }
        else if to.contains("Gbps") { result = bps / 1_000_000_000.0 }
        
        return formatOutput(result)
    }
    
    private func convertStorage(val: Double, from: String, to: String) -> String {
        var bytes: Double = val
        if from.contains("(KB)") { bytes = val * 1000.0 }
        else if from.contains("(MB)") { bytes = val * 1_000_000.0 }
        else if from.contains("(GB)") { bytes = val * 1_000_000_000.0 }
        else if from.contains("(KiB)") { bytes = val * 1024.0 }
        else if from.contains("(MiB)") { bytes = val * 1_048_576.0 }
        else if from.contains("(GiB)") { bytes = val * 1_073_741_824.0 }
        
        var result: Double = bytes
        if to.contains("(KB)") { result = bytes / 1000.0 }
        else if to.contains("(MB)") { result = bytes / 1_000_000.0 }
        else if to.contains("(GB)") { result = bytes / 1_000_000_000.0 }
        else if to.contains("(KiB)") { result = bytes / 1024.0 }
        else if to.contains("(MiB)") { result = bytes / 1_048_576.0 }
        else if to.contains("(GiB)") { result = bytes / 1_073_741_824.0 }
        
        return formatOutput(result)
    }
    
    private func convertCurrency(val: Double, from: String, to: String) -> String {
        let ratesToEUR: [String: Double] = [
            "EUR": 1.0,
            "USD": 1.08,
            "GBP": 0.85,
            "CHF": 0.95,
            "PLN": 4.32,
            "CZK": 25.20,
            "DKK": 7.46
        ]
        
        let fromCode = String(from.prefix(3))
        let toCode = String(to.prefix(3))
        
        guard let rateFrom = ratesToEUR[fromCode], let rateTo = ratesToEUR[toCode] else { return "0,00" }
        let eurVal = val / rateFrom
        let result = eurVal * rateTo
        
        return String(format: "%.2f", result).replacingOccurrences(of: ".", with: ",")
    }
    
    private func formatOutput(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", val)
        } else {
            return String(format: "%.4f", val).replacingOccurrences(of: ".", with: ",")
        }
    }
}
