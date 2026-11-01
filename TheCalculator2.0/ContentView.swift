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

struct ContentView: View {
    @State private var selectedMode: CalculatorMode = .basic
    @State private var displayValue: String = "0"
    @State private var formulaDisplay: String = ""
    @State private var formulaExpression: String = ""
    @State private var isTypingNewNumber: Bool = true
    
    // ASCII Reverse Input State
    @State private var asciiInputChar: String = "A"
    
    // Memory Status
    @State private var memoryValue: Double = 0.0
    @State private var hasMemory: Bool = false
    
    // Alert 42
    @State private var showNerdFact: Bool = false
    @State private var currentFact: String = ""
    
    let nerdFacts = [
        "42 ist die Antwort auf die Frage nach dem Leben, dem Universum und dem ganzen Rest.",
        "In ASCII entspricht 42 dem Sternchen (*).",
        "42 ist die Summe der ersten 6 geraden Zahlen: 2 + 4 + 6 + 8 + 10 + 12."
    ]

    var body: some View {
        VStack(spacing: 8) {
            
            // 1. MODUS SELECTION
            HStack {
                Text("Modus:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Picker("Modus", selection: $selectedMode) {
                    ForEach(CalculatorMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.top, 4)
            
            // 2. DISPLAY BEREICH
            VStack(alignment: .trailing, spacing: 4) {
                HStack {
                    if hasMemory {
                        Text("M (\(formatResult(memoryValue)))")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                    Spacer()
                    Text(formulaDisplay)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                HStack(alignment: .firstTextBaseline) {
                    if displayValue == "42" || displayValue == "42,0" || displayValue == "42.0" {
                        Text("(Ultimate Answer)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    }
                    Spacer()
                    Text(displayValue)
                        .font(.system(size: 38, weight: .bold, design: .monospaced))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(14)
            .padding(.horizontal)
            
            // 3. DYNAMISCHER INHALT
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
    }
    
    // MARK: - Basic Tastatur Grid
    private var basicCalculatorGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                calcButton("MC", color: .gray) { memoryClear() }
                calcButton("MR", color: .gray) { memoryRecall() }
                calcButton("M+", color: .gray) { memoryAdd() }
                calcButton("M-", color: .gray) { memorySub() }
            }
            HStack(spacing: 8) {
                calcButton("C", color: .red) { clear() }
                calcButton("(", color: .gray) { appendSymbol("(") }
                calcButton(")", color: .gray) { appendSymbol(")") }
                calcButton("%", color: .gray) { applyPercentage() }
            }
            HStack(spacing: 8) {
                calcButton("7") { appendDigit("7") }
                calcButton("8") { appendDigit("8") }
                calcButton("9") { appendDigit("9") }
                calcButton("÷", color: .orange) { appendSymbol("÷") }
            }
            HStack(spacing: 8) {
                calcButton("4") { appendDigit("4") }
                calcButton("5") { appendDigit("5") }
                calcButton("6") { appendDigit("6") }
                calcButton("×", color: .orange) { appendSymbol("×") }
            }
            HStack(spacing: 8) {
                calcButton("1") { appendDigit("1") }
                calcButton("2") { appendDigit("2") }
                calcButton("3") { appendDigit("3") }
                calcButton("-", color: .orange) { appendSymbol("-") }
            }
            HStack(spacing: 8) {
                calcButton("0") { appendDigit("0") }
                calcButton(",") { appendComma() }
                calcButton("42", color: .purple) { trigger42Fact() }
                calcButton("+", color: .orange) { appendSymbol("+") }
            }
            HStack(spacing: 8) {
                calcButton("=", color: .orange) { calculateResult() }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Scientific Tastatur Grid (Kompakte quadratische Blöcke oben)
    private var scientificCalculatorGrid: some View {
        VStack(spacing: 8) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    squareScientificButton("sin") { applyScientificFunc("sin") }
                    squareScientificButton("cos") { applyScientificFunc("cos") }
                    squareScientificButton("tan") { applyScientificFunc("tan") }
                    squareScientificButton("asin") { applyScientificFunc("asin") }
                    squareScientificButton("acos") { applyScientificFunc("acos") }
                }
                HStack(spacing: 4) {
                    squareScientificButton("atan") { applyScientificFunc("atan") }
                    squareScientificButton("x²") { applyScientificFunc("square") }
                    squareScientificButton("xʸ") { appendSymbol("^") }
                    squareScientificButton("√") { applyScientificFunc("sqrt") }
                    squareScientificButton("n!") { applyScientificFunc("factorial") }
                }
                HStack(spacing: 4) {
                    squareScientificButton("ln") { applyScientificFunc("ln") }
                    squareScientificButton("log") { applyScientificFunc("log10") }
                    squareScientificButton("e") { appendDigit(String(M_E)) }
                    squareScientificButton("π") { appendDigit(String(Double.pi)) }
                    squareScientificButton("mod") { appendSymbol("mod") }
                }
            }
            .padding(.horizontal)
            
            basicCalculatorGrid
        }
    }
    
    // MARK: - Quadratischer Button-Generator für Scientific-Funktionen
    private func squareScientificButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            hideKeyboard()
            action()
        }) {
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1.0, contentMode: .fit)
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Base / Hex View
    private var hexBinView: some View {
        ScrollView {
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bitweise Logik-Operationen").font(.subheadline).fontWeight(.bold).foregroundColor(.purple)
                    Divider()
                    HStack(spacing: 6) {
                        calcButton("AND", color: .indigo) { applyBitwiseOp("&") }
                        calcButton("OR", color: .indigo) { applyBitwiseOp("|") }
                        calcButton("XOR", color: .indigo) { applyBitwiseOp("^") }
                        calcButton("NOT", color: .indigo) { applyBitwiseNot() }
                        calcButton("<<", color: .indigo) { applyBitwiseOp("<<") }
                        calcButton(">>", color: .indigo) { applyBitwiseOp(">>") }
                    }
                    .frame(height: 38)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                if let val = Int64(displayValue.replacingOccurrences(of: ",", with: ".")) {
                    let res = BaseCalculator.convert(value: val)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display-Zahl → Basen & ASCII").font(.subheadline).fontWeight(.bold).foregroundColor(.blue)
                        Divider()
                        Text("Dezimal: \(res.dec)").monospaced()
                        Text("Hexadezimal: \(res.hex)").monospaced()
                        Text("Binär: \(res.bin)").monospaced()
                        if val >= 32 && val <= 126, let unicode = UnicodeScalar(Int(val)) {
                            Text("ASCII-Zeichen: '\(Character(unicode))'").monospaced().foregroundColor(.green).fontWeight(.bold)
                        } else {
                            Text("ASCII-Zeichen: (Nicht druckbar)").font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reverse ASCII (Zeichen → Code)").font(.subheadline).fontWeight(.bold).foregroundColor(.orange)
                    Divider()
                    HStack {
                        Text("Zeichen eingeben:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("A", text: $asciiInputChar)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 50)
                            .multilineTextAlignment(.center)
                            .onChange(of: asciiInputChar) { newValue in
                                if newValue.count > 1 { asciiInputChar = String(newValue.prefix(1)) }
                            }
                    }
                    
                    if let firstChar = asciiInputChar.first, let asciiVal = firstChar.asciiValue {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Dezimal: \(asciiVal)").monospaced().fontWeight(.semibold)
                            Text("Hexadezimal: 0x\(String(asciiVal, radix: 16, uppercase: true))").monospaced()
                            Text("Binär: 0b\(String(asciiVal, radix: 2))").monospaced()
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Button Generator
    private func calcButton(_ label: String, color: Color = .blue, action: @escaping () -> Void) -> some View {
        Button(action: {
            hideKeyboard()
            action()
        }) {
            Text(label)
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Eingabe-Logik
    private func appendDigit(_ digit: String) {
        if isTypingNewNumber {
            displayValue = digit
            isTypingNewNumber = false
        } else {
            displayValue += digit
        }
        formulaExpression += digit
        formulaDisplay = formulaExpression
    }
    
    private func appendSymbol(_ symbol: String) {
        if isTypingNewNumber && formulaExpression.isEmpty {
            formulaExpression = displayValue + " " + symbol + " "
        } else {
            formulaExpression += " " + symbol + " "
        }
        formulaDisplay = formulaExpression
        isTypingNewNumber = true
    }
    
    private func appendComma() {
        if !displayValue.contains(",") {
            displayValue += ","
            formulaExpression += "."
        }
    }
    
    private func clear() {
        displayValue = "0"
        formulaDisplay = ""
        formulaExpression = ""
        isTypingNewNumber = true
    }
    
    private func trigger42Fact() {
        currentFact = nerdFacts.randomElement() ?? nerdFacts[0]
        showNerdFact = true
    }
    
    private func applyPercentage() {
        guard let current = Double(displayValue.replacingOccurrences(of: ",", with: ".")) else { return }
        let pct = current / 100.0
        displayValue = formatResult(pct)
        isTypingNewNumber = true
    }
    
    private func applyBitwiseOp(_ op: String) {
        appendSymbol(op)
    }
    
    private func applyBitwiseNot() {
        guard let val = Int64(displayValue.replacingOccurrences(of: ",", with: ".")) else { return }
        displayValue = String(~val)
    }
    
    private func calculateResult() {
        let cleanExpr = formulaExpression.replacingOccurrences(of: ",", with: ".")
        if let result = evaluateMathExpression(cleanExpr) {
            displayValue = formatResult(result)
            formulaDisplay = "\(formulaExpression) ="
            formulaExpression = formatResult(result)
            isTypingNewNumber = true
        }
    }
    
    // MARK: - Absturzsicherer Evaluator (Unterstützt fmod für Modulo)
    private func evaluateMathExpression(_ expr: String) -> Double? {
        let tokens = expr.components(separatedBy: " ").filter { !$0.isEmpty }
        
        // Modulo-Berechnung direkt für 'A mod B' auswerten
        if tokens.count == 3 && tokens[1] == "mod" {
            if let a = Double(tokens[0]), let b = Double(tokens[2]), b != 0 {
                return fmod(a, b)
            }
        }

        let formatted = expr
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .replacingOccurrences(of: "mod", with: "%")
        
        var doubleExpr = ""
        let exprTokens = formatted.components(separatedBy: " ")
        for token in exprTokens {
            if let intVal = Int(token) {
                doubleExpr += "\(Double(intVal)) "
            } else {
                doubleExpr += "\(token) "
            }
        }
        
        let nsExpr = NSExpression(format: doubleExpr)
        return nsExpr.expressionValue(with: nil, context: nil) as? Double
    }
    
    private func applyScientificFunc(_ function: String) {
        guard let val = Double(displayValue.replacingOccurrences(of: ",", with: ".")) else { return }
        var res: Double = 0.0
        
        switch function {
        case "sin": res = sin(val * .pi / 180.0)
        case "cos": res = cos(val * .pi / 180.0)
        case "tan": res = tan(val * .pi / 180.0)
        case "asin": res = asin(val) * 180.0 / .pi
        case "acos": res = acos(val) * 180.0 / .pi
        case "atan": res = atan(val) * 180.0 / .pi
        case "sqrt": res = sqrt(val)
        case "square": res = val * val
        case "ln": res = log(val)
        case "log10": res = log10(val)
        case "factorial": res = factorial(Int(val))
        default: break
        }
        
        formulaDisplay = "\(function)(\(formatResult(val))) ="
        displayValue = formatResult(res)
        formulaExpression = formatResult(res)
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
}
