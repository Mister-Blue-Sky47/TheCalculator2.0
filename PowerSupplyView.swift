import SwiftUI

struct PowerSupplyView: View {
    @State private var selectedCPU: PCComponent = PowerSupplyCalculator.presetComponents[1]
    @State private var selectedGPU: PCComponent = PowerSupplyCalculator.presetComponents[6]
    @State private var selectedMotherboard: PCComponent = PowerSupplyCalculator.presetComponents[10]
    @State private var selectedStorage: PCComponent = PowerSupplyCalculator.presetComponents[12]
    @State private var selectedPeripherals: PCComponent = PowerSupplyCalculator.presetComponents[14]
    
    var body: some View {
        let currentSelection = [selectedCPU, selectedGPU, selectedMotherboard, selectedStorage, selectedPeripherals]
        let result = PowerSupplyCalculator.calculateTotalWattage(selectedComponents: currentSelection)
        
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    // Ergebnis-Banner oben
                    VStack(spacing: 6) {
                        Text("NETZTEIL-EMPFEHLUNG")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        Text("\(result.recommendedPSU) Watt")
                            .font(.system(size: 34, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                        
                        Text("Ermittelter Verbrauch unter Last: ~\(Int(result.sumWatt)) W (inkl. 30% Puffer)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    // Auswahlsektionen
                    Group {
                        componentPickerSection(title: "Prozessor (CPU)", selection: $selectedCPU, category: .cpu)
                        componentPickerSection(title: "Grafikkarte (GPU)", selection: $selectedGPU, category: .gpu)
                        componentPickerSection(title: "Mainboard & RAM", selection: $selectedMotherboard, category: .motherboard)
                        componentPickerSection(title: "Speichermedien", selection: $selectedStorage, category: .storage)
                        componentPickerSection(title: "Kühlung & Lüfter", selection: $selectedPeripherals, category: .peripherals)
                    }
                }
                .padding(8)
            }
        }
    }
    
    @ViewBuilder
    private func componentPickerSection(title: String, selection: Binding<PCComponent>, category: ComponentCategory) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.blue)
            
            Menu {
                Picker(title, selection: selection) {
                    ForEach(PowerSupplyCalculator.presetComponents.filter { $0.category == category }) { comp in
                        Text("\(comp.name) (\(Int(comp.typicalWattage))W)").tag(comp)
                    }
                }
            } label: {
                HStack {
                    Text("\(selection.wrappedValue.name) (\(Int(selection.wrappedValue.typicalWattage))W)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(8)
            }
        }
    }
}
