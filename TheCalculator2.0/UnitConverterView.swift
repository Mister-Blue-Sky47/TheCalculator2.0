// xcode: set sdk=iOS

import SwiftUI

struct UnitConverterView: View {
    @State private var inputValue: String = "1"
    @State private var selectedCategory: UnitCategory = .storage
    @State private var sourceUnit: String = "Gibibyte (GiB)"
    @State private var targetUnit: String = "Gigabyte (GB)"
    @FocusState private var isInputFocused: Bool
    
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
                    isInputFocused = false
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
                    .focused($isInputFocused)
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
                
                Button(action: {
                    let temp = sourceUnit
                    sourceUnit = targetUnit
                    targetUnit = temp
                }) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.orange)
                        .padding(.top, 14)
                }
                
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
                        .minimumScaleFactor(0.45)
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
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Fertig") {
                    isInputFocused = false
                }
                .fontWeight(.bold)
            }
        }
    }
    
    // MARK: - Helper Logik
    private func resetUnitsForCategory() {
        let units = availableUnits()
        if selectedCategory == .storage {
            sourceUnit = "Gibibyte (GiB)"
            targetUnit = "Gigabyte (GB)"
        } else if let first = units.first, let second = units.dropFirst().first {
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
            return ["Bit/s (bps)", "Kbit/s (Kbps)", "Mbit/s (Mbps)", "Gbit/s (Gbps)", "Tbit/s (Tbps)", "Megabyte/s (MB/s)", "Gigabyte/s (GB/s)"]
        case .storage:
            return [
                "Bit (bit)",
                "Byte (B)",
                "Kilobyte (KB)",
                "Megabyte (MB)",
                "Gigabyte (GB)",
                "Terabyte (TB)",
                "Petabyte (PB)",
                "Exabyte (EB)",
                "Kibibyte (KiB)",
                "Mebibyte (MiB)",
                "Gibibyte (GiB)",
                "Tebibyte (TiB)",
                "Pebibyte (PiB)",
                "Exbibyte (EiB)"
            ]
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
    
    private func convertStorage(val: Double, from: String, to: String) -> String {
        let toBytes: [String: Double] = [
            "Bit (bit)": 0.125,
            "Byte (B)": 1.0,
            "Kilobyte (KB)": 1e3,
            "Megabyte (MB)": 1e6,
            "Gigabyte (GB)": 1e9,
            "Terabyte (TB)": 1e12,
            "Petabyte (PB)": 1e15,
            "Exabyte (EB)": 1e18,
            "Kibibyte (KiB)": pow(1024, 1),
            "Mebibyte (MiB)": pow(1024, 2),
            "Gibibyte (GiB)": pow(1024, 3),
            "Tebibyte (TiB)": pow(1024, 4),
            "Pebibyte (PiB)": pow(1024, 5),
            "Exbibyte (EiB)": pow(1024, 6)
        ]
        
        guard let factorFrom = toBytes[from], let factorTo = toBytes[to] else { return formatOutput(val) }
        let result = (val * factorFrom) / factorTo
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
