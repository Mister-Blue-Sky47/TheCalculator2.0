//
//  PowerSupplyView.swift
//  TheCalculator2.0
//
//  Created by Steffen Beier on 16.11.26.
//

import SwiftUI

struct PowerSupplyView: View {
    @State private var selectedCPU: PCComponent = PowerSupplyCalculator.presetComponents[1]
    @State private var selectedGPU: PCComponent = PowerSupplyCalculator.presetComponents[6]
    @State private var selectedMotherboard: PCComponent = PowerSupplyCalculator.presetComponents[10]
    @State private var selectedStorage: PCComponent = PowerSupplyCalculator.presetComponents[12]
    @State private var selectedPeripherals: PCComponent = PowerSupplyCalculator.presetComponents[14]
    
    @State private var customWattInputs: [ComponentCategory: String] = [:]
    @State private var isCustomMode: [ComponentCategory: Bool] = [:]

    var body: some View {
        let currentSelection = [selectedCPU, selectedGPU, selectedMotherboard, selectedStorage, selectedPeripherals]
        let result = PowerSupplyCalculator.calculateTotalWattage(selectedComponents: currentSelection)
        
        ScrollView {
            VStack(spacing: 16) {
                // Prominentes Empfehlungs-Banner
                VStack(spacing: 10) {
                    Text("EMPFOHLENES NETZTEIL")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Text("\(result.recommendedPSU) Watt")
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Komponenten-Basisverbrauch:")
                            Spacer()
                            Text("\(Int(result.sumWatt)) W")
                                .bold()
                        }
                        HStack {
                            Text("Inkl. Lastspitzen & Puffer (+30%):")
                            Spacer()
                            Text("\(Int(result.sumWatt * 1.3)) W")
                                .bold()
                        }
                        Text("💡 Hinweis: Diese Leistungsklasse bietet optimale Effizienz im Last-Sweet-Spot und fängt Lastspitzen (Transients) sicher ab.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .font(.system(size: 12))
                }
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                
                // Auswahlsektionen
                Group {
                    componentSection(title: "Prozessor (CPU)", selection: $selectedCPU, category: .cpu)
                    componentSection(title: "Grafikkarte (GPU)", selection: $selectedGPU, category: .gpu)
                    componentSection(title: "Mainboard & RAM", selection: $selectedMotherboard, category: .motherboard)
                    componentSection(title: "Speichermedien", selection: $selectedStorage, category: .storage)
                    componentSection(title: "Kühlung & Lüfter", selection: $selectedPeripherals, category: .peripherals)
                }
            }
            .padding()
        }
        .navigationTitle("Netzteil-Rechner")
        .preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    private func componentSection(title: String, selection: Binding<PCComponent>, category: ComponentCategory) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.blue)
            
            if isCustomMode[category] == true {
                HStack {
                    TextField("Watt", text: Binding(
                        get: { customWattInputs[category] ?? "\(Int(selection.wrappedValue.typicalWattage))" },
                        set: { newValue in
                            customWattInputs[category] = newValue
                            if let val = Double(newValue) {
                                selection.wrappedValue = PCComponent(name: "Eigener Wert (\(title))", category: category, typicalWattage: val, isCustom: true)
                            }
                        }
                    ))
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    
                    Text("W")
                        .foregroundColor(.secondary)
                    
                    Button("Presets") {
                        isCustomMode[category] = false
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
                .padding(10)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
            } else {
                Menu {
                    Picker(title, selection: selection) {
                        ForEach(PowerSupplyCalculator.presetComponents.filter { $0.category == category }) { comp in
                            // Korrigierte String-Interpolation ohne Syntaxfehler
                            Text("\(comp.name) (\(Int(comp.typicalWattage)) W)").tag(comp)
                        }
                    }
                    
                    Button("Eigener Wert (Watt eingeben)...") {
                        isCustomMode[category] = true
                    }
                } label: {
                    HStack {
                        Text("\(selection.wrappedValue.name) (\(Int(selection.wrappedValue.typicalWattage)) W)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
                }
            }
        }
    }
}
