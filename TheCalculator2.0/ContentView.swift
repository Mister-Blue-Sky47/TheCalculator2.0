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
    @State private var hasEvaluatedResult: Bool = false
    
    // Modus-Steuerung: Punkt-vor-Strich vs. Tischrechner
    @State private var useOrderOfOperations: Bool = true
    
    // Winkelfunktionen-Modus: DEG (Grad) vs. RAD (Bogenmaß)
    @State private var useRadDegrees: Bool = false
    
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
            
            // 1. MODUS SELECTION & EINSTELLUNGEN
            VStack(spacing: 6) {
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
                
                if selectedMode == .basic || selectedMode == .scientific {
                    HStack {
                        Toggle(isOn: $useOrderOfOperations) {
                            Text(useOrderOfOperations ? "Punkt-vor-Strich (Math)" : "Tischrechner (Sequentiell)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .orange))
                    }
                    .padding(.horizontal, 4)
                }
                
                // DEG / RAD Umschalter im Scientific-Modus
                if selectedMode == .scientific {
                    HStack {
                        Text("Winkelmaß:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Picker("Winkelmaß", selection: $useRadDegrees) {
                            Text("DEG (Grad)").tag(false)
                            Text("RAD (Rad)").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                    }
                    .padding(.horizontal, 4)
                }
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
                        .font(.system(size: 14, design: .monospaced))
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
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .minimumScaleFactor(0.4)
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
                calcButton("%", color: .gray) { applySmartPercentage() }
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
                calcButton("DEL", color: .red) { deleteLastChar() }
                calcButton("+", color: .orange) { appendSymbol("+") }
            }
            
            GeometryReader { geo in
                HStack(spacing: 8) {
                    calcButton("42", color: .purple) { trigger42Fact() }
                        .frame(width: (geo.size.width - 8) * 0.25)
                    
                    calcButton("=", color: .orange) { calculateResult() }
                        .frame(width: (geo.size.width - 8) * 0.75)
                }
            }
            .frame(height: 52)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Scientific Tastatur Grid
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
    
    // MARK: - ABGESICHERTE EINGABELOGIK
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
    
    private func deleteLastChar() {
        if !displayValue.isEmpty && displayValue != "0" {
            displayValue.removeLast()
            if displayValue.isEmpty { displayValue = "0" }
        }
        if !formulaExpression.isEmpty {
            formulaExpression.removeLast()
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
        guard let val = Int64(displayValue.replacingOccurrences(of: ",", with: ".")) else { return }
        displayValue = String(~val)
    }
    
    // MARK: - ABSOLUT ABGESICHERTER EVALUATOR
    private func calculateResult() {
        let cleanExpr = formulaExpression.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        
        // Prüfen auf explizite Division durch 0
        if cleanExpr.contains("/ 0") || cleanExpr.contains("÷ 0") {
            displayValue = "Division durch 0 nicht möglich"
            isTypingNewNumber = true
            hasEvaluatedResult = true
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
                displayValue = formatResult(res)
                formulaDisplay = "\(formulaExpression) ="
                formulaExpression = formatResult(res)
            }
            hasEvaluatedResult = true
            isTypingNewNumber = true
        } else {
            displayValue = "Syntaxfehler"
            hasEvaluatedResult = true
            isTypingNewNumber = true
        }
    }
    
    private func evaluateMathExpression(_ expr: String) -> Double? {
        var clean = expr.replacingOccurrences(of: "=", with: "").trimmingCharacters(in: .whitespaces)
        
        // Führende Operatoren abfangen
        while clean.hasPrefix("×") || clean.hasPrefix("÷") || clean.hasPrefix("*") || clean.hasPrefix("/") || clean.hasPrefix("%") {
            clean = String(clean.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        
        guard !clean.isEmpty else { return nil }
        
        // Potenzierung x^y direkt auflösen
        let tokens = clean.components(separatedBy: " ").filter { !$0.isEmpty }
        if tokens.count == 3 && tokens[1] == "^" {
            if let a = Double(tokens[0]), let b = Double(tokens[2]) {
                return pow(a, b)
            }
        }
        
        // Mehrgliedriges Modulo auflösen (z.B. "60 * 9 mod 6" -> "540 mod 6" -> 0)
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
    
    // Scientific-Funktionen mit mathematischen Schutzschaltern
    private func applyScientificFunc(_ function: String) {
        guard let val = Double(displayValue.replacingOccurrences(of: ",", with: ".")) else { return }
        var res: Double = 0.0
        
        // Grad vs. Bogenmaß Umrechnungsfaktor
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
        
        formulaDisplay = "\(function)(\(formatResult(val))) ="
        displayValue = formatResult(res)
        formulaExpression = formatResult(res)
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
}
