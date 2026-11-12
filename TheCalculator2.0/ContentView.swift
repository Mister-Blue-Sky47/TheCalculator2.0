import SwiftUI

enum CalculatorMode: String, CaseIterable, Identifiable {
    case basic = "BASIC"
    case scientific = "SCIENTIFIC"
    case units = "EINHEITEN"
    case subnet = "SUBNET (v4)"
    case ipv6 = "IPv6"
    case diag = "DIAGNOSE"
    case elektro = "ELEKTRO"
    case hexBin = "BASE/HEX"
    
    var id: String { self.rawValue }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case proDark = "Pro Dark"
    case cyberPurple = "Cyber Purple"
    case classicApple = "Classic Apple"
    case matrixGreen = "Matrix Green"
    
    var id: String { self.rawValue }
    
    var digitButtonColor: Color {
        switch self {
        case .proDark: return Color(UIColor.darkGray)
        case .cyberPurple: return Color(UIColor.systemPurple).opacity(0.8)
        case .classicApple: return Color(UIColor.systemGray)
        case .matrixGreen: return Color(UIColor.systemGreen).opacity(0.2)
        }
    }
    
    var operatorButtonColor: Color {
        switch self {
        case .proDark, .classicApple: return .orange
        case .cyberPurple: return .purple
        case .matrixGreen: return .green
        }
    }
}

struct HistoryItem: Identifiable {
    let id = UUID()
    let expression: String
    let result: String
}

struct PhysicsConstant: Identifiable {
    let id = UUID()
    let name: String
    let symbol: String
    let value: Double
    let unit: String
}

struct ContentView: View {
    @State private var selectedMode: CalculatorMode = .basic
    @State private var currentTheme: AppTheme = .proDark
    
    @State private var displayValue: String = "0"
    @State private var formulaDisplay: String = ""
    @State private var formulaExpression: String = ""
    @State private var isTypingNewNumber: Bool = true
    @State private var hasEvaluatedResult: Bool = false
    
    @State private var useOrderOfOperations: Bool = true
    @State private var useRadDegrees: Bool = false
    
    @State private var memoryValue: Double = 0.0
    @State private var hasMemory: Bool = false
    
    // Reverse-Konverter (Zeichen -> Code) im BASE/HEX-Modus
    @State private var reverseInputChar: String = "A"
    
    // Sheets
    @State private var history: [HistoryItem] = []
    @State private var showHistorySheet: Bool = false
    @State private var showSettingsSheet: Bool = false
    @State private var showConstantsSheet: Bool = false
    @State private var showITOverlays: Bool = false
    
    // Dice State (0 = A-Z Buchstaben-Würfel, sonst 6, 10, 20, 100)
    @State private var selectedDiceSides: Int = 6
    
    @State private var showNerdFact: Bool = false
    @State private var currentFact: String = ""
    
    let nerdFacts = [
        "42 ist die Antwort auf die Frage nach dem Leben, dem Universum und dem ganzen Rest.",
        "In ASCII entspricht 42 dem Sternchen (*).",
        "42 ist die Summe der ersten 6 geraden Zahlen: 2 + 4 + 6 + 8 + 10 + 12."
    ]
    
    let physicsConstants: [PhysicsConstant] = [
        PhysicsConstant(name: "Lichtgeschwindigkeit", symbol: "c", value: 299792458, unit: "m/s"),
        PhysicsConstant(name: "Gravitationskonstante", symbol: "G", value: 6.67430e-11, unit: "m³/(kg·s²)"),
        PhysicsConstant(name: "Planck-Wirkungsquantum", symbol: "h", value: 6.62607015e-34, unit: "J·s"),
        PhysicsConstant(name: "Elementarladung", symbol: "e", value: 1.602176634e-19, unit: "C"),
        PhysicsConstant(name: "Avogadro-Konstante", symbol: "N_A", value: 6.02214076e23, unit: "mol⁻¹"),
        PhysicsConstant(name: "Boltzmann-Konstante", symbol: "k_B", value: 1.380649e-23, unit: "J/K"),
        PhysicsConstant(name: "Euler'sche Zahl", symbol: "e", value: Double(M_E), unit: "Zahl"),
        PhysicsConstant(name: "Kreiszahl", symbol: "π", value: Double.pi, unit: "Zahl")
    ]

    var body: some View {
        VStack(spacing: 4) {
            headerControls
                .padding(.horizontal, 6)
                .padding(.top, 2)
            
            VStack(alignment: .trailing, spacing: 3) {
                HStack {
                    Text("SYS: READY")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                    Spacer()
                    Text("MODE: \(selectedMode.rawValue)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                    if selectedMode == .scientific {
                        Text("• \(useRadDegrees ? "RAD" : "DEG")")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                }
                
                Text(formulaDisplay.isEmpty ? " " : formulaDisplay)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                HStack {
                    if hasMemory {
                        Text("MEM: \(formatResult(memoryValue))")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                    Spacer()
                    if displayValue == "42" || displayValue == "42,0" || displayValue == "42.0" {
                        Text("(Ultimate Answer)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.purple)
                    }
                }
                
                Text(displayValue)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .minimumScaleFactor(0.35)
                    .lineLimit(1)
                    .foregroundColor(currentTheme == .matrixGreen ? .green : .primary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal, 8)
            
            Group {
                switch selectedMode {
                case .basic:
                    basicCalculatorGrid
                case .scientific:
                    scientificCalculatorGrid
                case .units:
                    UnitConverterView().dismissKeyboardOnTap()
                case .subnet:
                    SubnetView().dismissKeyboardOnTap()
                case .ipv6:
                    IPv6View().dismissKeyboardOnTap()
                case .diag:
                    NetworkDiagnosticView().dismissKeyboardOnTap()
                case .elektro:
                    ElektroView().dismissKeyboardOnTap()
                case .hexBin:
                    hexBinView.dismissKeyboardOnTap()
                }
            }
            .frame(maxHeight: .infinity)
        }
        .alert(isPresented: $showNerdFact) {
            Alert(title: Text("42 – Die Antwort auf ALLES"), message: Text(currentFact), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showHistorySheet) {
            historySheetView
        }
        .sheet(isPresented: $showSettingsSheet) {
            settingsSheetView
        }
        .sheet(isPresented: $showConstantsSheet) {
                        constantsSheetView
                    }
                    .sheet(isPresented: $showITOverlays) {
                        ITOverlaysView()
                    }
                }
    
    private var headerControls: some View {
        HStack(spacing: 3) {
            Picker("Modus", selection: $selectedMode) {
                ForEach(CalculatorMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(6)
            .fixedSize()
            
            Button(action: { showHistorySheet = true }) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 12, weight: .bold))
                    .padding(5)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .foregroundColor(currentTheme == .matrixGreen ? .green : .blue)
                    .cornerRadius(6)
            }
            
            Button(action: { showSettingsSheet = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 12, weight: .bold))
                    .padding(5)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .foregroundColor(.gray)
                    .cornerRadius(6)
            }
            Button(action: { showITOverlays = true }) {
                            Image(systemName: "rectangle.stack.badge.plus")
                                .font(.system(size: 12, weight: .bold))
                                .padding(5)
                                .background(Color(UIColor.tertiarySystemBackground))
                                .foregroundColor(currentTheme == .matrixGreen ? .green : .blue)
                                .cornerRadius(6)
                        }
            
            Spacer(minLength: 1)
            
            if selectedMode == .basic || selectedMode == .scientific {
                Toggle(isOn: $useOrderOfOperations) {
                    Text(useOrderOfOperations ? "Math" : "Tisch")
                        .font(.system(size: 9, weight: .bold))
                }
                .toggleStyle(.button)
                .tint(currentTheme.operatorButtonColor)
                .fixedSize()
            }
            
            if selectedMode == .scientific {
                Toggle(isOn: $useRadDegrees) {
                    Text(useRadDegrees ? "RAD" : "DEG")
                        .font(.system(size: 9, weight: .bold))
                }
                .toggleStyle(.button)
                .tint(.blue)
                .fixedSize()
            }
        }
    }
    
    private var constantsSheetView: some View {
        NavigationView {
            List(physicsConstants) { item in
                Button(action: {
                    let valStr = String(item.value)
                    appendDigit(valStr)
                    showConstantsSheet = false
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Text("\(item.symbol) = \(item.value) \(item.unit)")
                                .font(.caption)
                                .fontDesign(.monospaced)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Naturkonstanten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { showConstantsSheet = false }
                }
            }
        }
    }
    
    private var settingsSheetView: some View {
        NavigationView {
            Form {
                Section(header: Text("Design & Theme")) {
                    Picker("Farb-Stimmung", selection: $currentTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Würfel-Einstellungen")) {
                    Picker("Würfel-Typ", selection: $selectedDiceSides) {
                        Text("d6").tag(6)
                        Text("d10").tag(10)
                        Text("d20").tag(20)
                        Text("d100").tag(100)
                        Text("d A-Z").tag(0) // 0 steht für Buchstaben-Würfel
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Über TheCalculator 2.0")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("2.0 (Build 2026.11)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Entwickler")
                        Spacer()
                        Text("maKI Edition / Steffen")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Einstellungen & Themes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { showSettingsSheet = false }
                }
            }
        }
    }
    
    private var historySheetView: some View {
        NavigationView {
            List {
                if history.isEmpty {
                    Text("Noch keine Berechnungen im Verlauf")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(history.reversed()) { item in
                        Button(action: {
                            displayValue = item.result
                            formulaExpression = item.result
                            formulaDisplay = "\(item.expression) ="
                            showHistorySheet = false
                        }) {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(item.expression)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("= \(item.result)")
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .onDelete(perform: deleteHistoryItem)
                }
            }
            .navigationTitle("Rechenverlauf (Tape)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !history.isEmpty {
                        Button("Löschen") { history.removeAll() }
                            .foregroundColor(.red)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { showHistorySheet = false }
                }
            }
        }
    }
    
    private func deleteHistoryItem(at offsets: IndexSet) {
        let reversedIndices = offsets.map { history.count - 1 - $0 }
        for index in reversedIndices {
            history.remove(at: index)
        }
    }
    
    private var basicCalculatorGrid: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                calcButton("MC", color: Color(UIColor.systemGray4), textColor: .primary) { memoryClear() }
                calcButton("MR", color: Color(UIColor.systemGray4), textColor: .primary) { memoryRecall() }
                calcButton("M+", color: Color(UIColor.systemGray4), textColor: .primary) { memoryAdd() }
                calcButton("M-", color: Color(UIColor.systemGray4), textColor: .primary) { memorySub() }
            }
            HStack(spacing: 4) {
                calcButton("C", color: Color(UIColor.systemRed)) { clear() }
                calcButton("(", color: Color(UIColor.systemGray2)) { appendSymbol("(") }
                calcButton(")", color: Color(UIColor.systemGray2)) { appendSymbol(")") }
                calcButton("%", color: Color(UIColor.systemGray2)) { applySmartPercentage() }
            }
            HStack(spacing: 4) {
                calcButton("7", color: currentTheme.digitButtonColor) { appendDigit("7") }
                calcButton("8", color: currentTheme.digitButtonColor) { appendDigit("8") }
                calcButton("9", color: currentTheme.digitButtonColor) { appendDigit("9") }
                calcButton("÷", color: currentTheme.operatorButtonColor) { appendSymbol("÷") }
            }
            HStack(spacing: 4) {
                calcButton("4", color: currentTheme.digitButtonColor) { appendDigit("4") }
                calcButton("5", color: currentTheme.digitButtonColor) { appendDigit("5") }
                calcButton("6", color: currentTheme.digitButtonColor) { appendDigit("6") }
                calcButton("×", color: currentTheme.operatorButtonColor) { appendSymbol("×") }
            }
            HStack(spacing: 4) {
                calcButton("1", color: currentTheme.digitButtonColor) { appendDigit("1") }
                calcButton("2", color: currentTheme.digitButtonColor) { appendDigit("2") }
                calcButton("3", color: currentTheme.digitButtonColor) { appendDigit("3") }
                calcButton("-", color: currentTheme.operatorButtonColor) { appendSymbol("-") }
            }
            HStack(spacing: 4) {
                calcButton("0", color: currentTheme.digitButtonColor) { appendDigit("0") }
                calcButton(",", color: currentTheme.digitButtonColor) { appendComma() }
                calcButton("DEL", color: Color(UIColor.systemRed)) { deleteLastChar() }
                calcButton("+", color: currentTheme.operatorButtonColor) { appendSymbol("+") }
            }
            
            GeometryReader { geo in
                HStack(spacing: 4) {
                    calcButton("SWAP", color: .indigo) { swapOperands() }
                        .frame(width: (geo.size.width - 8) * 0.20)
                    
                    calcButton("42", color: .purple) { trigger42Fact() }
                        .frame(width: (geo.size.width - 8) * 0.20)
                    
                    calcButton("=", color: currentTheme.operatorButtonColor) { calculateResult() }
                        .frame(width: (geo.size.width - 8) * 0.60)
                }
            }
            .frame(height: 42)
        }
        .padding(.horizontal, 8)
    }
    
    private var scientificCalculatorGrid: some View {
        VStack(spacing: 4) {
            VStack(spacing: 3) {
                HStack(spacing: 3) {
                    squareScientificButton("sin") { applyScientificFunc("sin") }
                    squareScientificButton("cos") { applyScientificFunc("cos") }
                    squareScientificButton("tan") { applyScientificFunc("tan") }
                    squareScientificButton("asin") { applyScientificFunc("asin") }
                    squareScientificButton("acos") { applyScientificFunc("acos") }
                }
                HStack(spacing: 3) {
                    squareScientificButton("atan") { applyScientificFunc("atan") }
                    squareScientificButton("x²") { applyScientificFunc("square") }
                    squareScientificButton("xʸ") { appendSymbol("^") }
                    squareScientificButton("√") { applyScientificFunc("sqrt") }
                    squareScientificButton("n!") { applyScientificFunc("factorial") }
                }
                HStack(spacing: 3) {
                    squareScientificButton("ln") { applyScientificFunc("ln") }
                    squareScientificButton("log") { applyScientificFunc("log10") }
                    squareScientificButton("e") { appendDigit(String(M_E)) }
                    squareScientificButton("π") { appendDigit(String(Double.pi)) }
                    squareScientificButton("CONST") { showConstantsSheet = true }
                }
                HStack(spacing: 3) {
                    squareScientificButton("rnd") { generateRandomFloat() }
                    squareScientificButton(selectedDiceSides == 0 ? "🎲d A-Z" : "🎲d\(selectedDiceSides)") { generateDiceRoll() }
                    squareScientificButton("Rnd100") { generateRandomInt100() }
                    squareScientificButton("mod") { appendSymbol("mod") }
                    squareScientificButton("1/x") { applyReciprocal() }
                }
            }
            .padding(.horizontal, 8)
            
            basicCalculatorGrid
        }
    }
    
    private func squareScientificButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            hideKeyboard()
            action()
        }) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemIndigo))
                .foregroundColor(.white)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
    
    private var hexBinView: some View {
        VStack(spacing: 4) {
            ScrollView {
                VStack(spacing: 6) {
                    // 1. Bitweise Logik-Operationen
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bitweise Logik-Operationen").font(.caption).fontWeight(.bold).foregroundColor(.blue)
                        HStack(spacing: 4) {
                            calcButton("AND", color: Color(UIColor.systemBlue)) { applyBitwiseOp("&") }
                            calcButton("OR", color: Color(UIColor.systemBlue)) { applyBitwiseOp("|") }
                            calcButton("XOR", color: Color(UIColor.systemBlue)) { applyBitwiseOp("^") }
                            calcButton("NOT", color: Color(UIColor.systemBlue)) { applyBitwiseNot() }
                            calcButton("<<", color: Color(UIColor.systemBlue)) { applyBitwiseOp("<<") }
                            calcButton(">>", color: Color(UIColor.systemBlue)) { applyBitwiseOp(">>") }
                        }
                        .frame(height: 32)
                    }
                    .padding(8)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    
                    // 2. Basen, ASCII & Unicode (Zahl -> Zeichen & Basen)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Basen, ASCII & Unicode").font(.caption).fontWeight(.bold).foregroundColor(.blue)
                        
                        let cleanText = displayValue.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
                        let parsedInt: Int64? = {
                            if let d = Double(cleanText), d <= Double(Int64.max), d >= Double(Int64.min), d.truncatingRemainder(dividingBy: 1) == 0 {
                                return Int64(d)
                            } else if let hexVal = Int64(cleanText.replacingOccurrences(of: "0x", with: "").replacingOccurrences(of: "0X", with: ""), radix: 16) {
                                return hexVal
                            }
                            return nil
                        }()

                        if cleanText == "Syntaxfehler" || cleanText == "Ungültiger Wert" || cleanText.contains("Division") {
                            Text("Warte auf gültigen Ausdruck...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if let intVal = parsedInt {
                            let res = BaseCalculator.convert(value: intVal)
                            Text("DEC: \(res.dec)").font(.system(size: 12, design: .monospaced))
                            Text("HEX: \(res.hex)").font(.system(size: 12, design: .monospaced))
                            Text("BIN: \(res.bin)").font(.system(size: 11, design: .monospaced))
                            Text(res.charInfo)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                        } else {
                            Text("Bereichsüberschreitung / Ungültige Ganzzahl").font(.caption).foregroundColor(.red).bold()
                            Text("Bitte gültige Dezimal- oder Hex-Zahl eingeben").font(.caption2).foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    
                    // 3. Reverse-Konverter (Zeichen -> Code)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Reverse: Zeichen → Code").font(.caption).fontWeight(.bold).foregroundColor(.blue)
                                            HStack(spacing: 8) {
                                                TextField("Zeichen", text: $reverseInputChar)
                                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                                                    .multilineTextAlignment(.center)
                                                    .frame(width: 48, height: 34)
                                                    .background(Color(UIColor.tertiarySystemBackground))
                                                    .cornerRadius(6)
                                                    .submitLabel(.done)
                                                    .onSubmit { hideKeyboard() }
                                                    .onChange(of: reverseInputChar) { _, newValue in
                                                        if let firstChar = newValue.first {
                                                            let single = String(firstChar)
                                                            if reverseInputChar != single {
                                                                reverseInputChar = single
                                                            }
                                                        }
                                                    }
                                                
                                                let scalars = Array(reverseInputChar.unicodeScalars)
                                                if let scalar = scalars.first {
                                                    let code = Int64(scalar.value)
                                                    let res = BaseCalculator.convert(value: code)
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text("DEC: \(res.dec)  |  HEX: \(res.hex) (U+\(String(format: "%04X", scalar.value)))")
                                                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                                        if scalars.count > 1 {
                                                            let extra = scalars.dropFirst().map { String(format: "U+%04X", $0.value) }.joined(separator: " ")
                                                            Text("BIN: \(res.bin) • Sequenz: \(extra)")
                                                                .font(.system(size: 10, design: .monospaced))
                                                                .foregroundColor(.orange)
                                                        } else {
                                                            Text("BIN: \(res.bin)")
                                                                .font(.system(size: 10, design: .monospaced))
                                                                .foregroundColor(.secondary)
                                                        }
                                                    }
                                                } else {
                                                    Text("Einzelnes Zeichen eingeben (z. B. A, €, 🚀)")
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                }
                                                Spacer(minLength: 0)
                                            }
                                        }
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .cornerRadius(8)
                }
                .padding(.horizontal, 8)
            }
            
            HStack(spacing: 3) {
                calcButton("A", color: Color(UIColor.systemPurple)) { appendDigit("A") }
                calcButton("B", color: Color(UIColor.systemPurple)) { appendDigit("B") }
                calcButton("C", color: Color(UIColor.systemPurple)) { appendDigit("C") }
                calcButton("D", color: Color(UIColor.systemPurple)) { appendDigit("D") }
                calcButton("E", color: Color(UIColor.systemPurple)) { appendDigit("E") }
                calcButton("F", color: Color(UIColor.systemPurple)) { appendDigit("F") }
            }
            .frame(height: 32)
            .padding(.horizontal, 8)
            
            basicCalculatorGrid
        }
    }
    
    private func calcButton(_ label: String, color: Color = .blue, textColor: Color = .white, action: @escaping () -> Void) -> some View {
        Button(action: {
            hideKeyboard()
            action()
        }) {
            Text(label)
                .font(.system(size: 13, weight: .bold))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(color)
                .foregroundColor(textColor)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
    
    private func generateRandomFloat() {
        let rndVal = Double.random(in: 0.0...1.0)
        let formatted = formatResult(rndVal)
        displayValue = formatted
        formulaExpression = formatted
        isTypingNewNumber = true
    }
    
    private func generateDiceRoll() {
        if selectedDiceSides == 0 {
            // Buchstaben-Würfel A-Z
            let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            if let randomLetter = letters.randomElement() {
                displayValue = String(randomLetter)
                formulaExpression = String(randomLetter)
                isTypingNewNumber = true
            }
        } else {
            let roll = Int.random(in: 1...selectedDiceSides)
            displayValue = String(roll)
            formulaExpression = String(roll)
            isTypingNewNumber = true
        }
    }
    
    private func generateRandomInt100() {
        let roll = Int.random(in: 1...100)
        displayValue = String(roll)
        formulaExpression = String(roll)
        isTypingNewNumber = true
    }
    
    private func applyReciprocal() {
        guard let val = Double(displayValue.replacingOccurrences(of: ",", with: ".")), val != 0 else {
            displayValue = "Division durch 0"
            isTypingNewNumber = true
            return
        }
        let res = 1.0 / val
        displayValue = formatResult(res)
        formulaDisplay = "1/(\(formatResult(val))) ="
        formulaExpression = formatResult(res)
        hasEvaluatedResult = true
        isTypingNewNumber = true
    }
    
    private func swapOperands() {
        let tokens = formulaExpression.components(separatedBy: " ").filter { !$0.isEmpty }
        if tokens.count == 3 {
            let left = tokens[0]
            let op = tokens[1]
            let right = tokens[2]
            
            formulaExpression = "\(right) \(op) \(left)"
            formulaDisplay = formulaExpression
            displayValue = right
        }
    }
    
    private func appendDigit(_ digit: String) {
        if hasEvaluatedResult {
            displayValue = digit
            formulaExpression = digit
            hasEvaluatedResult = false
            isTypingNewNumber = false
        } else if isTypingNewNumber {
            displayValue = digit
            formulaExpression += digit
            isTypingNewNumber = false
        } else {
            if displayValue == "0" {
                displayValue = digit
                formulaExpression = String(formulaExpression.dropLast()) + digit
            } else {
                displayValue += digit
                formulaExpression += digit
            }
        }
        formulaDisplay = formulaExpression
    }
    
    private func appendSymbol(_ symbol: String) {
        if hasEvaluatedResult {
            formulaExpression = displayValue + " " + symbol + " "
            hasEvaluatedResult = false
        } else {
            if formulaExpression.hasSuffix(" ") {
                formulaExpression = String(formulaExpression.dropLast(2)) + symbol + " "
            } else {
                formulaExpression += " " + symbol + " "
            }
        }
        formulaDisplay = formulaExpression
        isTypingNewNumber = true
    }
    
    private func appendComma() {
        if hasEvaluatedResult {
            displayValue = "0,"
            formulaExpression = "0."
            hasEvaluatedResult = false
            isTypingNewNumber = false
        } else if isTypingNewNumber {
            displayValue = "0,"
            formulaExpression += "0."
            isTypingNewNumber = false
        } else if !displayValue.contains(",") {
            displayValue += ","
            formulaExpression += "."
        }
        formulaDisplay = formulaExpression
    }
    
    // INTELLIGENTES DEL: Löscht Zahlenzeichen einzeln & Operatoren mit Leerzeichen in 1 Schritt!
    private func deleteLastChar() {
        if !displayValue.isEmpty && displayValue != "0" {
            displayValue.removeLast()
            if displayValue.isEmpty { displayValue = "0" }
        }
        
        if !formulaExpression.isEmpty {
            if formulaExpression.hasSuffix(" ") {
                // Wenn Formel auf Leerzeichen endet (Operator z.B. " + "), lösche das gesamte Operator-Paket " Op "
                let trimmed = formulaExpression.trimmingCharacters(in: .whitespaces)
                let components = trimmed.components(separatedBy: " ")
                if components.count > 1 {
                    formulaExpression = components.dropLast().joined(separator: " ") + " "
                } else {
                    formulaExpression = ""
                }
            } else {
                formulaExpression.removeLast()
            }
        }
        formulaDisplay = formulaExpression
    }
    
    private func clear() {
        displayValue = "0"
        formulaDisplay = ""
        formulaExpression = ""
        isTypingNewNumber = true
        hasEvaluatedResult = false
    }
    
    private func trigger42Fact() {
        currentFact = nerdFacts.randomElement() ?? nerdFacts[0]
        showNerdFact = true
    }
    
    private func applySmartPercentage() {
        guard let current = Double(displayValue.replacingOccurrences(of: ",", with: ".")) else { return }
        
        if useOrderOfOperations {
            let pct = current / 100.0
            displayValue = formatResult(pct)
            
            var components = formulaExpression.components(separatedBy: " ").filter { !$0.isEmpty }
            if !components.isEmpty {
                components[components.count - 1] = formatResult(pct).replacingOccurrences(of: ",", with: ".")
                formulaExpression = components.joined(separator: " ")
            } else {
                formulaExpression = formatResult(pct).replacingOccurrences(of: ",", with: ".")
            }
            formulaDisplay = formulaExpression
        } else {
            let cleanExpr = formulaExpression.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
            let tokens = cleanExpr.components(separatedBy: " ").filter { !$0.isEmpty }
            
            if tokens.count >= 2, let baseVal = Double(tokens[0]) {
                let res = baseVal * (current / 100.0)
                displayValue = formatResult(res)
                formulaDisplay = "\(formatResult(baseVal)) × \(formatResult(current))% ="
                formulaExpression = formatResult(res)
                hasEvaluatedResult = true
                history.append(HistoryItem(expression: "\(formatResult(baseVal)) × \(formatResult(current))%", result: formatResult(res)))
            } else {
                let pct = current / 100.0
                displayValue = formatResult(pct)
                formulaExpression = formatResult(pct).replacingOccurrences(of: ",", with: ".")
                formulaDisplay = formulaExpression
            }
        }
    }
    
    private func applyBitwiseOp(_ op: String) {
        appendSymbol(op)
    }
    
    private func applyBitwiseNot() {
        guard let val = parseHexOrDec(displayValue.replacingOccurrences(of: ",", with: ".")) else { return }
        displayValue = String(~val)
    }
    
    private func calculateResult() {
        let cleanExpr = formulaExpression.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        
        if cleanExpr.contains("/ 0") || cleanExpr.contains("÷ 0") {
            displayValue = "Division durch 0 nicht möglich"
            isTypingNewNumber = true
            hasEvaluatedResult = true
            return
        }
        
        if containsHexOrBitwise(cleanExpr) {
            if let hexResult = evaluateBitwiseExpression(cleanExpr) {
                let resStr = String(hexResult)
                displayValue = resStr
                formulaDisplay = "\(formulaExpression) ="
                history.append(HistoryItem(expression: formulaExpression, result: resStr))
                formulaExpression = resStr
            } else {
                displayValue = "Syntaxfehler"
            }
            hasEvaluatedResult = true
            isTypingNewNumber = true
            return
        }
        
        let result: Double?
        if useOrderOfOperations {
            result = evaluateMathExpression(cleanExpr)
        } else {
            result = evaluateSequentialExpression(cleanExpr)
        }
        
        if let res = result {
            if res.isInfinite || res.isNaN {
                displayValue = "Ungültiger Wert"
            } else {
                let formattedRes = formatResult(res)
                displayValue = formattedRes
                formulaDisplay = "\(formulaExpression) ="
                history.append(HistoryItem(expression: formulaExpression, result: formattedRes))
                formulaExpression = formattedRes
            }
            hasEvaluatedResult = true
            isTypingNewNumber = true
        } else {
            displayValue = "Syntaxfehler"
            hasEvaluatedResult = true
            isTypingNewNumber = true
        }
    }
    
    private func containsHexOrBitwise(_ expr: String) -> Bool {
        let pureBitwiseOps = ["&", "|", "<<", ">>"]
        let hexChars = ["A", "B", "C", "D", "E", "F"]
        
        if pureBitwiseOps.contains(where: { expr.contains($0) }) || hexChars.contains(where: { expr.contains($0) }) {
            return true
        }
        
        if expr.contains("^") {
            let tokens = expr.components(separatedBy: " ").filter { !$0.isEmpty }
            for token in tokens {
                if hexChars.contains(where: { token.contains($0) }) {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func evaluateBitwiseExpression(_ expr: String) -> Int64? {
        let trimmed = expr.trimmingCharacters(in: .whitespaces)
        
        // Unäres NOT (~wert)
        if trimmed.hasPrefix("~") {
            let operandStr = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
            if let val = parseHexOrDec(operandStr) {
                return ~val
            }
            return nil
        }
        
        // Ausdrücke in Tokens zerlegen (z. B. ["54", "+", "36", "+", "E"])
        let tokens = trimmed.components(separatedBy: " ").filter { !$0.isEmpty }
        guard !tokens.isEmpty, let firstVal = parseHexOrDec(tokens[0]) else {
            return nil
        }
        
        // Einzelner Wert ohne Operator (z. B. "FF")
        if tokens.count == 1 {
            return firstVal
        }
        
        // Ketten-Auswertung von links nach rechts (ungerade Token-Anzahl: Wert Op Wert Op Wert ...)
        guard tokens.count >= 3 && tokens.count % 2 == 1 else {
            return nil
        }
        
        var accumulator = firstVal
        var i = 1
        while i < tokens.count - 1 {
            let op = tokens[i]
            guard let nextVal = parseHexOrDec(tokens[i + 1]) else {
                return nil
            }
            
            switch op {
            case "&": accumulator = accumulator & nextVal
            case "|": accumulator = accumulator | nextVal
            case "^": accumulator = accumulator ^ nextVal
            case "<<": accumulator = accumulator << min(max(nextVal, 0), 63)
            case ">>": accumulator = accumulator >> min(max(nextVal, 0), 63)
            case "+": accumulator = accumulator &+ nextVal
            case "-": accumulator = accumulator &- nextVal
            case "*", "×": accumulator = accumulator &* nextVal
            case "/", "÷":
                guard nextVal != 0 else { return nil }
                accumulator = accumulator / nextVal
            default:
                return nil
            }
            i += 2
        }
        
        return accumulator
    }
    
    private func parseHexOrDec(_ str: String) -> Int64? {
        let clean = str.replacingOccurrences(of: "0x", with: "")
                       .replacingOccurrences(of: "0X", with: "")
                       .trimmingCharacters(in: .whitespaces)
        if selectedMode == .hexBin || clean.rangeOfCharacter(from: CharacterSet(charactersIn: "ABCDEFabcdef")) != nil {
            return Int64(clean, radix: 16)
        }
        return Int64(clean)
    }

    private func evaluateMathExpression(_ expr: String) -> Double? {
        var clean = expr.replacingOccurrences(of: "=", with: "").trimmingCharacters(in: .whitespaces)
        
        while clean.hasPrefix("×") || clean.hasPrefix("÷") || clean.hasPrefix("*") || clean.hasPrefix("/") || clean.hasPrefix("%") {
            clean = String(clean.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        
        guard !clean.isEmpty else { return nil }
        
        if clean.contains("^") {
            let parts = clean.components(separatedBy: "^")
            if parts.count == 2 {
                let cleanBase = parts[0].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
                let cleanExp = parts[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
                if let base = Double(cleanBase), let exp = Double(cleanExp) {
                    return pow(base, exp)
                }
            }
        }
        
        if containsHexOrBitwise(clean) {
            if let bitRes = evaluateBitwiseExpression(clean) {
                return Double(bitRes)
            }
            return nil
        }
        
        if clean.contains("mod") || clean.contains("%") {
            let modSymbol = clean.contains("mod") ? "mod" : "%"
            let parts = clean.components(separatedBy: " \(modSymbol) ")
            if parts.count == 2 {
                if let leftVal = evaluateMathExpression(parts[0]), let rightVal = evaluateMathExpression(parts[1]), rightVal != 0 {
                    return fmod(leftVal, rightVal)
                }
                return nil
            }
        }

        let formatted = clean
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            
        let doubleExpr = formatted.components(separatedBy: " ")
        if doubleExpr.contains("") || formatted.contains("**") || formatted.contains("//") || formatted.contains("++") {
            return nil
        }

        let parsedExpr = NSExpression(format: formatted)
        if let result = parsedExpr.expressionValue(with: nil, context: nil) as? NSNumber {
            return result.doubleValue
        }
        
        return nil
    }
    
    private func evaluateSequentialExpression(_ expr: String) -> Double? {
        var clean = expr.replacingOccurrences(of: "=", with: "").trimmingCharacters(in: .whitespaces)
        
        while let rangeOfOpen = clean.range(of: "("), let rangeOfClose = clean.range(of: ")") {
            let innerExpr = String(clean[rangeOfOpen.upperBound..<rangeOfClose.lowerBound])
            if let innerResult = evaluateSequentialExpression(innerExpr) {
                clean.replaceSubrange(rangeOfOpen.lowerBound...rangeOfClose.upperBound, with: "\(innerResult)")
            } else {
                break
            }
        }
        
        let tokens = clean.components(separatedBy: " ").filter { !$0.isEmpty }
        guard var runningResult = Double(tokens.first ?? "") else { return nil }
        
        var idx = 1
        while idx < tokens.count - 1 {
            let op = tokens[idx]
            guard let nextVal = Double(tokens[idx + 1]) else { break }
            
            switch op {
            case "+": runningResult += nextVal
            case "-": runningResult -= nextVal
            case "×", "*": runningResult *= nextVal
            case "÷", "/":
                if nextVal == 0 { return nil }
                runningResult /= nextVal
            case "^": runningResult = pow(runningResult, nextVal)
            case "mod", "%":
                if nextVal == 0 { return nil }
                runningResult = fmod(runningResult, nextVal)
            default: break
            }
            idx += 2
        }
        return runningResult
    }
    
    private func applyScientificFunc(_ function: String) {
        guard let val = Double(displayValue.replacingOccurrences(of: ",", with: ".")) else { return }
        var res: Double = 0.0
        
        let angleMultiplier = useRadDegrees ? 1.0 : (.pi / 180.0)
        let invAngleMultiplier = useRadDegrees ? 1.0 : (180.0 / .pi)
        
        switch function {
        case "sin": res = sin(val * angleMultiplier)
        case "cos": res = cos(val * angleMultiplier)
        case "tan": res = tan(val * angleMultiplier)
        case "asin":
            guard val >= -1.0 && val <= 1.0 else { displayValue = "Ungültiger Wert"; isTypingNewNumber = true; return }
            res = asin(val) * invAngleMultiplier
        case "acos":
            guard val >= -1.0 && val <= 1.0 else { displayValue = "Ungültiger Wert"; isTypingNewNumber = true; return }
            res = acos(val) * invAngleMultiplier
        case "atan": res = atan(val) * invAngleMultiplier
        case "sqrt":
            guard val >= 0 else { displayValue = "Ungültiger Wert"; isTypingNewNumber = true; return }
            res = sqrt(val)
        case "square": res = val * val
        case "ln":
            guard val > 0 else { displayValue = "Ungültiger Wert"; isTypingNewNumber = true; return }
            res = log(val)
        case "log10":
            guard val > 0 else { displayValue = "Ungültiger Wert"; isTypingNewNumber = true; return }
            res = log10(val)
        case "factorial":
            guard val >= 0 && val <= 170 else { displayValue = "Ungültiger Wert"; isTypingNewNumber = true; return }
            res = factorial(Int(val))
        default: break
        }
        
        let exprStr = "\(function)(\(formatResult(val)))"
        formulaDisplay = "\(exprStr) ="
        let resStr = formatResult(res)
        displayValue = resStr
        formulaExpression = resStr
        history.append(HistoryItem(expression: exprStr, result: resStr))
        hasEvaluatedResult = true
        isTypingNewNumber = true
    }
    
    private func factorial(_ n: Int) -> Double {
        guard n >= 0 else { return 0 }
        if n == 0 || n == 1 { return 1 }
        var fact: Double = 1
        for i in 2...min(n, 170) { fact *= Double(i) }
        return fact
    }
    
    private func memoryClear() { memoryValue = 0.0; hasMemory = false }
    private func memoryRecall() { displayValue = formatResult(memoryValue); isTypingNewNumber = true }
    private func memoryAdd() {
        if let val = Double(displayValue.replacingOccurrences(of: ",", with: ".")) {
            memoryValue += val; hasMemory = true; isTypingNewNumber = true
        }
    }
    private func memorySub() {
        if let val = Double(displayValue.replacingOccurrences(of: ",", with: ".")) {
            memoryValue -= val; hasMemory = true; isTypingNewNumber = true
        }
    }
    
    private func formatResult(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", val)
        } else {
            return String(format: "%.4f", val).replacingOccurrences(of: ".", with: ",")
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
