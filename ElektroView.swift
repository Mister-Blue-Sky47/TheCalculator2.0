import SwiftUI

struct ElektroView: View {
    @State private var subTab = 0 // 0: Ohm, 1: Spannungsfall, 2: USV
    
    // Ohm'sches Gesetz State
    @State private var inputU: String = ""
    @State private var inputI: String = ""
    @State private var inputR: String = ""
    @State private var inputP: String = ""
    @State private var ohmResult: ElektroCalculator.OhmsLawResult? = nil
    
    // Spannungsfall State
    @State private var inputVoltage: String = "230"
    @State private var inputCurrent: String = "16"
    @State private var inputLength: String = "25"
    @State private var inputCrossSection: String = "1.5"
    @State private var dropResult: (dropVolts: Double, dropPercent: Double)? = nil
    
    // USV State
    @State private var inputLoadW: String = "450"
    @State private var inputBatV: String = "24"
    @State private var inputBatAh: String = "18"
    @State private var usvMinutes: Double? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // Unter-Tab Auswahl
                Picker("Elektro Auswahl", selection: $subTab) {
                    Text("Ohm / P").tag(0)
                    Text("Spannungsfall").tag(1)
                    Text("USV Puffer").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                switch subTab {
                case 0:
                    ohmsLawCard
                case 1:
                    voltageDropCard
                default:
                    usvCard
                }
            }
            .padding(.vertical, 8)
        }
        .dismissKeyboardOnTap() // <-- EXACT HIER an das Ende von ScrollView anfügen!
    }
    
    // MARK: - 1. Ohm'sches Gesetz UI
    private var ohmsLawCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ohm'sches Gesetz & Leistung")
                .font(.headline)
            Text("Trage genau 2 Werte ein, um die restlichen 2 zu berechnen.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                inputField(title: "U (Volt)", text: $inputU)
                inputField(title: "I (Ampere)", text: $inputI)
            }
            HStack {
                inputField(title: "R (Ohm)", text: $inputR)
                inputField(title: "P (Watt)", text: $inputP)
            }
            
            HStack {
                Button("Berechnen") {
                    let u = Double(inputU.replacingOccurrences(of: ",", with: "."))
                    let i = Double(inputI.replacingOccurrences(of: ",", with: "."))
                    let r = Double(inputR.replacingOccurrences(of: ",", with: "."))
                    let p = Double(inputP.replacingOccurrences(of: ",", with: "."))
                    
                    if let res = ElektroCalculator.calculateOhmsLaw(u: u, i: i, r: r, p: p) {
                        ohmResult = res
                        inputU = String(format: "%.2f", res.u)
                        inputI = String(format: "%.2f", res.i)
                        inputR = String(format: "%.2f", res.r)
                        inputP = String(format: "%.2f", res.p)
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Zurücksetzen") {
                    inputU = ""; inputI = ""; inputR = ""; inputP = ""
                    ohmResult = nil
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.1), lineWidth: 1))
        .padding(.horizontal)
    }
    
    // MARK: - 2. Spannungsfall UI
    private var voltageDropCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spannungsfall (Kupferleitung)")
                .font(.headline)
            
            HStack {
                inputField(title: "Netzspannung (V)", text: $inputVoltage)
                inputField(title: "Strom (A)", text: $inputCurrent)
            }
            HStack {
                inputField(title: "Leitung (m)", text: $inputLength)
                inputField(title: "Querschnitt (mm²)", text: $inputCrossSection)
            }
            
            Button("Spannungsfall berechnen") {
                let v = Double(inputVoltage) ?? 230
                let i = Double(inputCurrent) ?? 0
                let l = Double(inputLength) ?? 0
                let q = Double(inputCrossSection) ?? 1.5
                
                let res = ElektroCalculator.calculateVoltageDrop(voltage: v, current: i, lengthMeters: l, crossSectionMm2: q)
                dropResult = res
            }
            .buttonStyle(.borderedProminent)
            
            if let res = dropResult {
                            Divider()
                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(format: "Spannungsabfall: %.2f V", res.dropVolts))
                                    .fontWeight(.semibold)
                                Text(String(format: "Relativ: %.2f %% (Norm Max: 3,0 %%)", res.dropPercent))
                                    .foregroundColor(res.dropPercent > 3.0 ? .red : .green)
                                    .font(.subheadline)
                            }
                        }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.1), lineWidth: 1))
        .padding(.horizontal)
    }
    
    // MARK: - 3. USV UI
    private var usvCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("USV Batterielaufzeit")
                .font(.headline)
            
            HStack {
                inputField(title: "Last (Watt)", text: $inputLoadW)
                inputField(title: "Akku (Volt)", text: $inputBatV)
            }
            inputField(title: "Kapazität (Ah)", text: $inputBatAh)
            
            Button("Laufzeit ermitteln") {
                let w = Double(inputLoadW) ?? 0
                let v = Double(inputBatV) ?? 12
                let ah = Double(inputBatAh) ?? 0
                
                usvMinutes = ElektroCalculator.calculateUSVRuntime(loadWatts: w, batteryVolts: v, batteryAh: ah)
            }
            .buttonStyle(.borderedProminent)
            
            if let mins = usvMinutes {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "Geschätzte Autonomiezeit: %.0f Min. (%.1f Std.)", mins, mins / 60.0))
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.1), lineWidth: 1))
        .padding(.horizontal)
    }
    
    private func inputField(title: String, text: Binding<String>) -> some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.caption).foregroundColor(.secondary)
                TextField("", text: text)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .onSubmit {
                        hideKeyboard()
                    }
            }
        }
    }
