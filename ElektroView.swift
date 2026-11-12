import SwiftUI

struct ElektroView: View {
    @State private var subTab = 0 // 0: Ohm, 1: Spannungsfall, 2: USV, 3: Widerstand / Farbcode
    @FocusState private var isInputFocused: Bool
    
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
    
    // Widerstand / Farbcode State
    @State private var ring1: ResistorColor = .brown
    @State private var ring2: ResistorColor = .black
    @State private var multiplier: ResistorColor = .red
    @State private var tolerance: ResistorColor = .gold
    @State private var r1Text: String = "100"
    @State private var r2Text: String = "220"

    var body: some View {
            ScrollView {
                VStack(spacing: 12) {
                    
                    // Unter-Tab Auswahl (Erweitert um Widerstand/Farbcode)
                    Picker("Elektro Auswahl", selection: $subTab) {
                        Text("Ohm / P").tag(0)
                        Text("Spannungsfall").tag(1)
                        Text("USV Puffer").tag(2)
                        Text("Widerstand").tag(3)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                    .onChange(of: subTab) { _ in
                        isInputFocused = false
                    }
                    switch subTab {
                    case 0:
                        ohmView
                    case 1:
                        voltageDropView
                    case 2:
                        usvView
                    case 3:
                        resistorColorView
                    default:
                        EmptyView()
                    }
                }
                .focused($isInputFocused)
                .padding(.bottom, 12)
            }
            .scrollDismissesKeyboard(.interactively)
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
    
    // MARK: - 1. Ohm'sches Gesetz View
    private var ohmView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ohm'sches Gesetz & Leistung (2 Werte eingeben)").font(.caption).fontWeight(.bold).foregroundColor(.blue)
            
            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 6) {
                GridRow {
                    Text("U (Volt):").font(.caption2)
                    TextField("Spannung U", text: $inputU).textFieldStyle(.roundedBorder).keyboardType(.decimalPad)
                }
                GridRow {
                    Text("I (Ampere):").font(.caption2)
                    TextField("Strom I", text: $inputI).textFieldStyle(.roundedBorder).keyboardType(.decimalPad)
                }
                GridRow {
                    Text("R (Ohm):").font(.caption2)
                    TextField("Widerstand R", text: $inputR).textFieldStyle(.roundedBorder).keyboardType(.decimalPad)
                }
                GridRow {
                    Text("P (Watt):").font(.caption2)
                    TextField("Leistung P", text: $inputP).textFieldStyle(.roundedBorder).keyboardType(.decimalPad)
                }
            }
            
            HStack(spacing: 8) {
                Button("Berechnen") {
                    let u = Double(inputU.replacingOccurrences(of: ",", with: "."))
                    let i = Double(inputI.replacingOccurrences(of: ",", with: "."))
                    let r = Double(inputR.replacingOccurrences(of: ",", with: "."))
                    let p = Double(inputP.replacingOccurrences(of: ",", with: "."))
                    ohmResult = ElektroCalculator.calculateOhmsLaw(u: u, i: i, r: r, p: p)
                }
                .buttonStyle(.borderedProminent)
                
                Button("Reset") {
                    inputU = ""; inputI = ""; inputR = ""; inputP = ""; ohmResult = nil
                }
                .buttonStyle(.bordered)
            }
            
            if let res = ohmResult {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ergebnis:").font(.caption).bold()
                    Text("Spannung U: \(String(format: "%.2f", res.u)) V").font(.system(size: 13, design: .monospaced))
                    Text("Strom I: \(String(format: "%.2f", res.i)) A").font(.system(size: 13, design: .monospaced))
                    Text("Widerstand R: \(String(format: "%.2f", res.r)) Ω").font(.system(size: 13, design: .monospaced))
                    Text("Leistung P: \(String(format: "%.2f", res.p)) W").font(.system(size: 13, design: .monospaced))
                }
            }
        }
        .padding(10)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal, 8)
    }
    
    // MARK: - 2. Spannungsfall View
    private var voltageDropView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Spannungsfall Leitungsberechnung (Kupfer γ=56)").font(.caption).fontWeight(.bold).foregroundColor(.blue)
            
            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 6) {
                GridRow {
                    Text("U (Volt):").font(.caption2)
                    TextField("Nennspannung", text: $inputVoltage).textFieldStyle(.roundedBorder).keyboardType(.decimalPad)
                }
                GridRow {
                    Text("I (Ampere):").font(.caption2)
                    TextField("Belastung", text: $inputCurrent).textFieldStyle(.roundedBorder).keyboardType(.decimalPad)
                }
                GridRow {
                    Text("L (Meter):").font(.caption2)
                    TextField("Leitungslänge", text: $inputLength).textFieldStyle(.roundedBorder).keyboardType(.decimalPad)
                }
                GridRow {
                    Text("A (mm²):").font(.caption2)
                    TextField("Querschnitt", text: $inputCrossSection).textFieldStyle(.roundedBorder).keyboardType(.decimalPad)
                }
            }
            
            Button("Spannungsfall berechnen") {
                if let u = Double(inputVoltage.replacingOccurrences(of: ",", with: ".")),
                   let i = Double(inputCurrent.replacingOccurrences(of: ",", with: ".")),
                   let l = Double(inputLength.replacingOccurrences(of: ",", with: ".")),
                   let a = Double(inputCrossSection.replacingOccurrences(of: ",", with: ".")) {
                    dropResult = ElektroCalculator.calculateVoltageDrop(voltage: u, current: i, lengthMeter: l, crossSection: a)
                }
            }
            .buttonStyle(.borderedProminent)
            
            if let res = dropResult {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spannungsfall ΔU: \(String(format: "%.2f", res.dropVolts)) V").font(.system(size: 13, weight: .bold, design: .monospaced))
                    Text("Prozentual: \(String(format: "%.2f", res.dropPercent)) %").font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(res.dropPercent > 3.0 ? .red : .green)
                }
            }
        }
        .padding(10)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal, 8)
    }
    
    // MARK: - 3. USV Puffer View
    private var usvView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("USV Akku Pufferzeit-Berechnung (Wirkungsgrad ~85%)").font(.caption).fontWeight(.bold).foregroundColor(.blue)
            
            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 6) {
                GridRow {
                    Text("Last (Watt):").font(.caption2)
                    TextField("Last W", text: $inputLoadW).textFieldStyle(.roundedBorder).keyboardType(.decimalPad)
                }
                GridRow {
                    Text("Akku (Volt):").font(.caption2)
                    TextField("Akkuspannung", text: $inputBatV).textFieldStyle(.roundedBorder).keyboardType(.decimalPad)
                }
                GridRow {
                    Text("Kapazität (Ah):").font(.caption2)
                    TextField("Kapazität Ah", text: $inputBatAh).textFieldStyle(.roundedBorder).keyboardType(.decimalPad)
                }
            }
            
            Button("Pufferzeit Berechnen") {
                if let w = Double(inputLoadW.replacingOccurrences(of: ",", with: ".")),
                   let v = Double(inputBatV.replacingOccurrences(of: ",", with: ".")),
                   let ah = Double(inputBatAh.replacingOccurrences(of: ",", with: ".")) {
                    usvMinutes = ElektroCalculator.calculateUSVRuntime(loadWatt: w, batteryVolts: v, batteryAh: ah)
                }
            }
            .buttonStyle(.borderedProminent)
            
            if let mins = usvMinutes {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Erwartete Pufferzeit:").font(.caption).bold()
                    Text("\(String(format: "%.1f", mins)) Minuten (\(String(format: "%.2f", mins / 60.0)) Std.)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(10)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal, 8)
    }
    
    // MARK: - 4. Widerstand & Farbcode View
    private var resistorColorView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("4-Ring Farbcode Dekoder").font(.caption).fontWeight(.bold).foregroundColor(.blue)
            
            // Optischer Widerstands-Balken
            HStack(spacing: 0) {
                Rectangle().fill(Color.gray.opacity(0.4)).frame(width: 20, height: 4)
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(UIColor.tertiarySystemBackground))
                        .frame(height: 36)
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 2).fill(ring1.displayColor).frame(width: 8, height: 28)
                        RoundedRectangle(cornerRadius: 2).fill(ring2.displayColor).frame(width: 8, height: 28)
                        RoundedRectangle(cornerRadius: 2).fill(multiplier.displayColor).frame(width: 8, height: 28)
                        Spacer().frame(width: 16)
                        RoundedRectangle(cornerRadius: 2).fill(tolerance.displayColor).frame(width: 8, height: 28)
                    }
                }
                Rectangle().fill(Color.gray.opacity(0.4)).frame(width: 20, height: 4)
            }
            .padding(.horizontal, 8)
            
            // Dropdowns für Farbringe
            VStack(spacing: 4) {
                HStack {
                    Text("1. Ring:").font(.caption2).frame(width: 60, alignment: .leading)
                    Picker("", selection: $ring1) {
                        ForEach([ResistorColor.brown, .red, .orange, .yellow, .green, .blue, .violet, .gray, .white], id: \.self) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }.pickerStyle(.menu).labelsHidden()
                }
                HStack {
                    Text("2. Ring:").font(.caption2).frame(width: 60, alignment: .leading)
                    Picker("", selection: $ring2) {
                        ForEach([ResistorColor.black, .brown, .red, .orange, .yellow, .green, .blue, .violet, .gray, .white], id: \.self) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }.pickerStyle(.menu).labelsHidden()
                }
                HStack {
                    Text("Multipl.:").font(.caption2).frame(width: 60, alignment: .leading)
                    Picker("", selection: $multiplier) {
                        ForEach(ResistorColor.allCases, id: \.self) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }.pickerStyle(.menu).labelsHidden()
                }
                HStack {
                    Text("Toleranz:").font(.caption2).frame(width: 60, alignment: .leading)
                    Picker("", selection: $tolerance) {
                        ForEach([ResistorColor.brown, .red, .green, .blue, .violet, .gray, .gold, .silver], id: \.self) { c in
                            Text("\(c.rawValue) (\(c.toleranceString))").tag(c)
                        }
                    }.pickerStyle(.menu).labelsHidden()
                }
            }
            
            let res4Band = ResistorCalculator.calculate4Band(ring1: ring1, ring2: ring2, multiplier: multiplier, tolerance: tolerance)
            HStack {
                Text("Widerstand:").font(.subheadline).bold()
                Spacer()
                Text("\(res4Band.formatted) \(res4Band.tol)")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
            }
            .padding(.top, 4)
            
            Divider()
            
            // Reihen- & Parallelschaltung Schnell-Berechnung
            Text("Reihen- & Parallelschaltung").font(.caption).fontWeight(.bold).foregroundColor(.blue)
            HStack(spacing: 8) {
                VStack(alignment: .leading) {
                    Text("R1 (Ω)").font(.caption2)
                    TextField("R1", text: $r1Text).textFieldStyle(.roundedBorder).keyboardType(.decimalPad)
                }
                VStack(alignment: .leading) {
                    Text("R2 (Ω)").font(.caption2)
                    TextField("R2", text: $r2Text).textFieldStyle(.roundedBorder).keyboardType(.decimalPad)
                }
            }
            
            if let v1 = Double(r1Text.replacingOccurrences(of: ",", with: ".")),
               let v2 = Double(r2Text.replacingOccurrences(of: ",", with: ".")) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Reihe (R1+R2):").font(.caption2).foregroundColor(.gray)
                        Text(ResistorCalculator.formatOhm(ResistorCalculator.series(r1: v1, r2: v2)))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Parallel (R1||R2):").font(.caption2).foregroundColor(.gray)
                        Text(ResistorCalculator.formatOhm(ResistorCalculator.parallel(r1: v1, r2: v2)))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                }
            }
        }
        .padding(10)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal, 8)
    }
}
