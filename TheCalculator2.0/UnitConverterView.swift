//
//  UnitConverterView.swift
//  TheCalculator2.0
//
//  Created by Steffen Beier on 16.11.26.
//

import SwiftUI

struct UnitConverterView: View {
    @State private var inputValue: String = "1"
    @State private var selectedCategory: UnitCalculator.UnitCategory = .length
    @State private var sourceUnit: String = "Meter (m)"
    @State private var targetUnit: String = "Kilometer (km)"
    @FocusState private var isInputFocused: Bool
    
    @State private var isUpdatingRates: Bool = false
    @State private var updateMessage: String? = nil
    
    var convertedValue: String {
        guard let val = Double(inputValue.replacingOccurrences(of: ",", with: ".")) else { return "0" }
        
        switch selectedCategory {
        case .length:
            return UnitCalculator.convertLength(val: val, from: sourceUnit, to: targetUnit)
        case .weight:
            return UnitCalculator.convertMass(val: val, from: sourceUnit, to: targetUnit)
        case .temperature:
            return UnitCalculator.convertTemperature(val: val, from: sourceUnit, to: targetUnit)
        case .dataRate:
            return UnitCalculator.convertDataRate(val: val, from: sourceUnit, to: targetUnit)
        case .storage:
            return UnitCalculator.convertStorage(val: val, from: sourceUnit, to: targetUnit)
        case .currency:
            return UnitCalculator.convertCurrency(val: val, from: sourceUnit, to: targetUnit)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // 1. Kategorie-Auswahl
                VStack(alignment: .leading, spacing: 6) {
                    Text("Kategorie auswählen:")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    Picker("Kategorie", selection: $selectedCategory) {
                        ForEach(UnitCalculator.UnitCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: selectedCategory) { _ in
                        isInputFocused = false
                        resetUnitsForCategory()
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // Extra-Button für Währungskurse aktualisieren
                if selectedCategory == .currency {
                    HStack {
                        Button(action: fetchLiveExchangeRates) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                Text(isUpdatingRates ? "Lade Kurse..." : "Tagesaktuelle Kurse laden")
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .disabled(isUpdatingRates)
                        
                        if let msg = updateMessage {
                            Text(msg)
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        Spacer()
                    }
                }
                
                // 2. Wert-Eingabe
                VStack(alignment: .leading, spacing: 6) {
                    Text("Wert eingeben:")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    TextField("Wert", text: $inputValue)
                        .keyboardType(.decimalPad)
                        .focused($isInputFocused)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .textFieldStyle(.roundedBorder)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // 3. Von / Nach Einheiten (Vertikal gestapelt gegen Überlagerungen)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Einheiten")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    // Von-Einheit
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                    }
                    
                    // Tauschen-Button mittig platziert
                    HStack {
                        Spacer()
                        Button(action: {
                            let temp = sourceUnit
                            sourceUnit = targetUnit
                            targetUnit = temp
                        }) {
                            Label("Einheiten tauschen", systemImage: "arrow.up.arrow.down.circle.fill")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                        Spacer()
                    }
                    
                    // Nach-Einheit
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // 4. Ergebnis-Box
                VStack(alignment: .leading, spacing: 6) {
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
                            .lineLimit(1)
                    }
                    .padding(12)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal)
            .padding(.top, 4)
        }
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
        if let first = units.first, let second = units.dropFirst().first {
            sourceUnit = first
            targetUnit = second
        }
    }
    
    private func availableUnits() -> [String] {
        switch selectedCategory {
        case .length:
            return [
                "Millimeter (mm)",
                "Zentimeter (cm)",
                "Dezimeter (dm)",
                "Meter (m)",
                "Kilometer (km)",
                "Zoll / Inch (in)",
                "Fuß / Feet (ft)",
                "Yard (yd)",
                "Meilen (mi)",
                "Seemeile (nmi)"
            ]
        case .weight:
            return ["Milligramm (mg)", "Gramm (g)", "Kilogramm (kg)", "Tonne (t)", "Unze (oz)", "Pfund (lb)"]
        case .temperature:
            return ["Grad Celsius (°C)", "Grad Fahrenheit (°F)", "Kelvin (K)"]
        case .dataRate:
            return ["Bit/s (bps)", "Kbit/s (Kbps)", "Mbit/s (Mbps)", "Gbit/s (Gbps)", "Tbit/s (Tbps)", "Megabyte/s (MB/s)", "Gigabyte/s (GB/s)"]
        case .storage:
            return ["Bit (bit)", "Byte (B)", "Kilobyte (KB)", "Megabyte (MB)", "Gigabyte (GB)", "Terabyte (TB)", "Petabyte (PB)", "Kibibyte (KiB)", "Mebibyte (MiB)", "Gibibyte (GiB)", "Tebibyte (TiB)"]
        case .currency:
            return [
                "EUR (€)",
                "USD ($)",
                "GBP (£)",
                "CHF (Fr.)",
                "CNY (¥ - China)",
                "JPY (¥ - Japan)",
                "PLN (zł)",
                "CZK (Kč)",
                "DKK (kr.)"
            ]
        }
    }
    
    private func fetchLiveExchangeRates() {
        isUpdatingRates = true
        updateMessage = nil
        UnitCalculator.updateLiveRates { success in
            isUpdatingRates = false
            if success {
                updateMessage = "Aktualisiert!"
                inputValue = String(inputValue)
            } else {
                updateMessage = "Fehler (Offline)"
            }
        }
    }
}
