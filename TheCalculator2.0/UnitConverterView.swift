import SwiftUI

struct UnitConverterView: View {
    @State private var selectedCategory: UnitCalculator.UnitCategory = .length
    @State private var inputValue: String = "1"
    @State private var fromUnit: String = "Zoll / Inch (in)"
    @State private var toUnit: String = "Zentimeter (cm)"
    
    let lengthUnits = ["Zoll / Inch (in)", "Zentimeter (cm)", "Millimeter (mm)", "Meter (m)", "Fuß / Feet (ft)", "Kilometer (km)", "Meilen (mi)", "Lichtjahre (ly)", "Astron. Einheiten (AU)"]
    let tempUnits = ["Celsius (°C)", "Fahrenheit (°F)", "Kelvin (K)"]
    let currencyUnits = ["EUR (€)", "USD ($)", "GBP (£)", "CHF (Fr.)", "JPY (¥)"]
    
    var availableUnits: [String] {
        switch selectedCategory {
        case .length: return lengthUnits
        case .temperature: return tempUnits
        case .currency, .weight: return currencyUnits
        }
    }
    
    var convertedResult: Double {
        guard let val = Double(inputValue.replacingOccurrences(of: ",", with: ".")) else { return 0.0 }
        switch selectedCategory {
        case .length:
            return UnitCalculator.convertLength(value: val, from: fromUnit, to: toUnit)
        case .temperature:
            return UnitCalculator.convertTemperature(value: val, from: fromUnit, to: toUnit)
        case .currency:
            return UnitCalculator.convertCurrency(value: val, from: fromUnit, to: toUnit)
        default:
            return val
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                
                Text("Einheiten- & Währungsrechner")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Kategorie (In zwei Zeilen, um Überlappung zu verhindern!)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Kategorie wählen:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Kategorie", selection: $selectedCategory) {
                        ForEach(UnitCalculator.UnitCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(10)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .onChange(of: selectedCategory) { _ in
                    if let first = availableUnits.first, let second = availableUnits.dropFirst().first {
                        fromUnit = first
                        toUnit = second
                    }
                }
                
                // Eingabe
                VStack(alignment: .leading, spacing: 8) {
                    Text("Eingabewert:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("1.0", text: $inputValue)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                        .monospaced()
                }
                .padding(10)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                
                // Einheiten-Auswahl
                VStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Von (Start-Einheit):")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Von", selection: $fromUnit) {
                            ForEach(availableUnits, id: \.self) { u in
                                Text(u).tag(u)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nach (Ziel-Einheit):")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Nach", selection: $toUnit) {
                            ForEach(availableUnits, id: \.self) { u in
                                Text(u).tag(u)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(10)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                
                // Ergebnis
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ergebnis:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.4f", convertedResult).replacingOccurrences(of: ".", with: ","))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                    
                    Text("\(inputValue) \(fromUnit) = \(String(format: "%.4f", convertedResult)) \(toUnit)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .dismissKeyboardOnTap()
    }
}
