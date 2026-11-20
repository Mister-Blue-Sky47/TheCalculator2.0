//
//  ContentView.swift
//  TheCalculator2.0
//
//  Created by Steffen Beier on 16.11.26.
//

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
    case psu = "NETZTEIL (PC)"
    case volleyball = "Volleyball"
    case sokoban = "Sokoban Mini-Game"
    case itOverlays = "IT-Overlays"
    case rpnStats = "RPN & STATS"

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
        case .proDark: return Color(hex: 0x1C1C1E)
        case .cyberPurple: return Color(UIColor.systemPurple).opacity(0.8)
        case .classicApple: return Color(UIColor.systemGray4)
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
    
    var backgroundColor: Color {
        switch self {
        case .proDark: return .black
        case .cyberPurple: return Color(hex: 0x0D0221)
        case .classicApple: return Color(UIColor.systemGroupedBackground)
        case .matrixGreen: return .black
        }
    }
    
    var displayBackgroundColor: Color {
        switch self {
        case .proDark: return Color(hex: 0x111111)
        case .cyberPurple: return Color(UIColor.systemPurple).opacity(0.15)
        case .classicApple: return Color(UIColor.secondarySystemBackground)
        case .matrixGreen: return Color.green.opacity(0.1)
        }
    }
}

enum AngleMode: String, CaseIterable {
    case deg = "DEG"
    case rad = "RAD"
    case gon = "GON"
    
    var multiplierToRadians: Double {
        switch self {
        case .deg: return .pi / 180.0
        case .rad: return 1.0
        case .gon: return .pi / 200.0
        }
    }
    
    var multiplierFromRadians: Double {
        switch self {
        case .deg: return 180.0 / .pi
        case .rad: return 1.0
        case .gon: return 200.0 / .pi
        }
    }
}

enum ExportFormat: String, CaseIterable, Identifiable {
    case txt = "TXT (Protokoll)"
    case csv = "CSV (Tabelle)"
    case json = "JSON (Daten)"
    case markdown = "Markdown"
    
    var id: String { self.rawValue }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

struct HistoryItem: Identifiable {
    let id = UUID()
    let expression: String
    let result: String
}

struct PhysicsConstant: Identifiable {
    let id = UUID()
    let category: String
    let name: String
    let symbol: String
    let value: Double
    let unit: String
}

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State private var selectedMode: CalculatorMode = .basic
    @AppStorage("selectedAppTheme") private var currentTheme: AppTheme = .proDark
    @AppStorage("useThousandsSeparator") private var useThousandsSeparator: Bool = true
    @AppStorage("decimalPrecisionMode") private var decimalPrecisionMode: Int = 4 // 4 = Auto (bis 4), 2 = Fest 2 Stellen, 6 = Bis 6 Stellen, 8 = Bis 8 Stellen
    
    @State private var displayValue: String = "0"
    @State private var formulaDisplay: String = ""
    @State private var formulaExpression: String = ""
    @State private var isTypingNewNumber: Bool = true
    @State private var hasEvaluatedResult: Bool = false
    
    @State private var useOrderOfOperations: Bool = true
    @State private var currentAngleMode: AngleMode = .deg
    
    @State private var memoryValue: Double = 0.0
    @State private var hasMemory: Bool = false
    
    @State private var reverseInputChar: String = "A"
    @State private var cryptoInputText: String = "Hello"
    @State private var selectedHashAlgorithm: BaseCalculator.HashAlgorithm = .sha256
    @State private var base64DecodeError: Bool = false
    
    @State private var history: [HistoryItem] = []
    @State private var showHistorySheet: Bool = false
    @State private var showSettingsSheet: Bool = false
    @State private var showConstantsSheet: Bool = false
    
    @State private var selectedExportFormat: ExportFormat = .txt
    @State private var showExportAlert: Bool = false
    @State private var exportedString: String = ""
    
    @State private var selectedDiceSides: Int = 6
    
    @State private var showNerdFact: Bool = false
    @State private var currentFact: String = ""
    
    private let nerdFacts: [String] = [
        "42 – Die Antwort auf das Leben, das Universum und den ganzen Rest. (Und vergiss dein Handtuch nicht!)",
        "0x2A in Hex, 0b101010 in Binär – und 100 % die richtige Antwort in der IHK-Prüfung.",
        "Es gibt 10 Arten von Menschen: Die, die Binär verstehen, und die, die es nicht tun.",
        "Layer-8-Problem erkannt: Der Fehler sitzt meist ca. 40 cm vor dem Monitor.",
        "Kein Backup, kein Mitleid! (3-2-1-Regel: 3 Kopien, 2 Medien, 1 Offsite.)",
        "DNS is immer schuld. Selbst wenn es nicht DNS ist – es war trotzdem DNS.",
        "Ein UDP-Witz: Ich würde dir ja einen erzählen, aber ich weiß nicht, ob er ankommt.",
        "Ein TCP-Witz: Hallo, möchtest du einen TCP-Witz hören? – Ja, ich möchte einen TCP-Witz hören. – Okay, hier ist der TCP-Witz.",
        "127.0.0.1 – Nirgendwo ist es schöner als zu Hause (::1 für IPv6-Profis).",
        "Merksatz Elektrotechnik: Blau ist Schwarz und Plus ist Minus – zumindest bis es knallt.",
        "Wer misst, misst Mist – vor allem ohne Bezugspotenzial auf der falschen Messspitze.",
        "404: Kaffeepause nicht gefunden. Bitte Administrator neu starten.",
        "Freitag nach eins macht jeder seins – aber bitte vorher kein Produktiv-Update deployen!",
        "IPv6 has 3,4 × 10³⁸ Adressen. Das reicht für ca. 42 IP-Adressen pro Sandkorn auf der Erde.",
        "Widerstand ist zwecklos – zumindest wenn R gegen 0 Ω geht (Kurzschluss!).",
        "Ein Byte sind 8 Bit. Ein Nibble sind 4 Bit. Und ein Häppchen Pause hat sich jeder verdient.",
        "RJ45-Crimp-Regel Nr. 1: Erst die Knickschutztülle aufs Kabel schieben, DANN den Stecker crimpen!",
        "USV-Weisheit: Ein Stromausfall kommt immer exakt 3 Sekunden bevor man auf Speichern drückt.",
        "ASCII 42 ist das Sternchen '*' – in Regex der Quantifizierer, in C der Zeiger.",
        "Spannungsfall über 3 %? Entweder Kupferquerschnitt erhöhen oder das Rack näher ans Kraftwerk schieben!"
    ]
    
    let physicsConstants: [PhysicsConstant] = [
        // Fundamental
        PhysicsConstant(category: "Fundamentalkonstanten", name: "Lichtgeschwindigkeit", symbol: "c", value: 299792458, unit: "m/s"),
        PhysicsConstant(category: "Fundamentalkonstanten", name: "Gravitationskonstante", symbol: "G", value: 6.67430e-11, unit: "m³/(kg·s²)"),
        PhysicsConstant(category: "Fundamentalkonstanten", name: "Planck-Wirkungsquantum", symbol: "h", value: 6.62607015e-34, unit: "J·s"),
        PhysicsConstant(category: "Fundamentalkonstanten", name: "Elementarladung", symbol: "e", value: 1.602176634e-19, unit: "C"),
        PhysicsConstant(category: "Fundamentalkonstanten", name: "Elektrische Feldkonstante", symbol: "ε₀", value: 8.854187817e-12, unit: "F/m"),
        PhysicsConstant(category: "Fundamentalkonstanten", name: "Magnetische Feldkonstante", symbol: "μ₀", value: 1.25663706212e-6, unit: "N/A²"),
        PhysicsConstant(category: "Fundamentalkonstanten", name: "Avogadro-Konstante", symbol: "N_A", value: 6.02214076e23, unit: "mol⁻¹"),
        PhysicsConstant(category: "Fundamentalkonstanten", name: "Boltzmann-Konstante", symbol: "k_B", value: 1.380649e-23, unit: "J/K"),
        PhysicsConstant(category: "Fundamentalkonstanten", name: "Goldener Schnitt", symbol: "φ", value: 1.61803398875, unit: "Zahl"),
        PhysicsConstant(category: "Fundamentalkonstanten", name: "Euler'sche Zahl", symbol: "e", value: Double(M_E), unit: "Zahl"),
        PhysicsConstant(category: "Fundamentalkonstanten", name: "Kreiszahl", symbol: "π", value: Double.pi, unit: "Zahl"),
        PhysicsConstant(category: "Fundamentalkonstanten", name: "Hackett Number", symbol: "H", value: 1.61803398875, unit: "Zahl"),
        
        // Astronomie & Planeten
        PhysicsConstant(category: "Astronomische Daten & Planeten", name: "Erdmasse", symbol: "M_E", value: 5.9722e24, unit: "kg"),
        PhysicsConstant(category: "Astronomische Daten & Planeten", name: "Erdradius (mittler)", symbol: "R_E", value: 6371000, unit: "m"),
        PhysicsConstant(category: "Astronomische Daten & Planeten", name: "Mondmasse", symbol: "M_M", value: 7.342e22, unit: "kg"),
        PhysicsConstant(category: "Astronomische Daten & Planeten", name: "Mondradius (mittler)", symbol: "R_M", value: 1737400, unit: "m")
    ]

    var body: some View {
        ZStack {
            currentTheme.backgroundColor
                .ignoresSafeArea()
            
            if verticalSizeClass == .compact {
                // --- QUERFORMAT-LAYOUT ---
                HStack(spacing: 8) {
                    VStack(spacing: 6) {
                        headerControls
                        
                        if [.basic, .scientific, .hexBin].contains(selectedMode) {
                            displaySection(isCompact: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: [.basic, .scientific, .hexBin].contains(selectedMode) ? 260 : .infinity)
                    
                    if [.basic, .scientific, .hexBin].contains(selectedMode) {
                        activeModeContent
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        activeModeContent
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            } else {
                // --- HOCHFORMAT-LAYOUT ---
                VStack(spacing: 4) {
                    headerControls
                        .padding(.horizontal, 6)
                        .padding(.top, 2)
                    
                    if [.basic, .scientific, .hexBin].contains(selectedMode) {
                        displaySection(isCompact: false)
                            .padding(.horizontal, 8)
                    }
                    
                    activeModeContent
                        .frame(maxHeight: .infinity)
                }
            }
        }
        .preferredColorScheme(currentTheme == .classicApple ? .light : .dark)
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
    }
    
    @ViewBuilder
    private func displaySection(isCompact: Bool) -> some View {
        VStack(alignment: .trailing, spacing: isCompact ? 2 : 3) {
            HStack {
                Text("SYS: READY")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                Spacer()
                Text("MODE: \(selectedMode.rawValue)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                if selectedMode == .scientific {
                    Button(action: {
                        switch currentAngleMode {
                        case .deg: currentAngleMode = .rad
                        case .rad: currentAngleMode = .gon
                        case .gon: currentAngleMode = .deg
                        }
                    }) {
                        Text("• \(currentAngleMode.rawValue)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text(formulaDisplay.isEmpty ? " " : formulaDisplay)
                .font(.system(size: isCompact ? 16 : 22, weight: .semibold, design: .monospaced))
                .foregroundColor(.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            
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
                .font(.system(size: isCompact ? 32 : 42, weight: .bold, design: .monospaced))
                .minimumScaleFactor(0.35)
                .lineLimit(1)
                .foregroundColor(currentTheme == .matrixGreen ? .green : .primary)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 10)
        .padding(.vertical, isCompact ? 4 : 6)
        .background(currentTheme.displayBackgroundColor)
        .cornerRadius(10)
    }
    
    @ViewBuilder
    private var activeModeContent: some View {
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
        case .psu:
            PowerSupplyView().dismissKeyboardOnTap()
        case .volleyball:
            VolleyballView()
        case .sokoban:
            SokobanView()
        case .itOverlays:
            ITOverlaysView()
        case .rpnStats:
            RPNStatsView(formatNumber: { formatResult($0) }).dismissKeyboardOnTap()
        }
    }
    
    private var headerControls: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Picker("Modus", selection: $selectedMode) {
                    ForEach(CalculatorMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .tint(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.tertiarySystemBackground).opacity(0.3))
                .cornerRadius(8)
                .fixedSize(horizontal: true, vertical: false)
                
                Spacer(minLength: 4)
                
                Button(action: { showHistorySheet = true }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 13, weight: .bold))
                        .padding(8)
                        .background(Color(.tertiarySystemBackground).opacity(0.3))
                        .foregroundColor(currentTheme == .matrixGreen ? .green : .blue)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Button(action: { showSettingsSheet = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13, weight: .bold))
                        .padding(8)
                        .background(Color(.tertiarySystemBackground).opacity(0.3))
                        .foregroundColor(.gray)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            if selectedMode == .basic || selectedMode == .scientific {
                HStack(spacing: 8) {
                    Toggle(isOn: $useOrderOfOperations) {
                        Text(useOrderOfOperations ? "Math (Punkt vor Strich)" : "Tischrechner (Sequentiell)")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .toggleStyle(.button)
                    .tint(currentTheme.operatorButtonColor)
                    
                    if selectedMode == .scientific {
                        Button(action: {
                            switch currentAngleMode {
                            case .deg: currentAngleMode = .rad
                            case .rad: currentAngleMode = .gon
                            case .gon: currentAngleMode = .deg
                            }
                        }) {
                            Text(currentAngleMode.rawValue)
                                .font(.system(size: 11, weight: .bold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .frame(width: 70)
                    }
                }
            }
        }
    }

    private var constantsSheetView: some View {
        NavigationView {
            List {
                Section(header: Text("Fundamentalkonstanten")) {
                    ForEach(physicsConstants.filter { $0.category == "Fundamentalkonstanten" }) { item in
                        constantRow(item)
                    }
                }
                
                Section(header: Text("Astronomische Daten & Planeten")) {
                    ForEach(physicsConstants.filter { $0.category == "Astronomische Daten & Planeten" }) { item in
                        constantRow(item)
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
    
    private func constantRow(_ item: PhysicsConstant) -> some View {
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
                
                Section(header: Text("Zahlenanzeige & Präzision")) {
                                    Toggle("Tausendertrennzeichen (1.000)", isOn: $useThousandsSeparator)
                                    
                                    Picker("Nachkommastellen", selection: $decimalPrecisionMode) {
                                        Text("2 Stellen (Kaufmännisch)").tag(2)
                                        Text("Auto (bis 4 Stellen)").tag(4)
                                        Text("Präzise (bis 6 Stellen)").tag(6)
                                        Text("Maximal (bis 8 Stellen)").tag(8)
                                    }
                                    .pickerStyle(.menu)
                                }
                
                Section(header: Text("Würfel-Einstellungen")) {
                    Picker("Würfel-Typ", selection: $selectedDiceSides) {
                        Text("d6").tag(6)
                        Text("d10").tag(10)
                        Text("d20").tag(20)
                        Text("d100").tag(100)
                        Text("d A-Z").tag(0)
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
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Text("Export-Format:")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    Picker("Format", selection: $selectedExportFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(10)
                .background(Color(UIColor.secondarySystemBackground))
                
                List {
                    if history.isEmpty {
                        Text("Noch keine Berechnungen im Verlauf")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(history.reversed()) { item in
                            Button(action: {
                                displayValue = item.result
                                let cleanRes = item.result
                                    .replacingOccurrences(of: "\u{202F}", with: "")
                                    .replacingOccurrences(of: "\u{200A}", with: "")
                                    .replacingOccurrences(of: "'", with: "")
                                    .replacingOccurrences(of: #"(?<=\d)\.(?=\d{3}\b)"#, with: "", options: .regularExpression)
                                    .replacingOccurrences(of: ",", with: ".")
                                formulaExpression = cleanRes
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
            }
            .navigationTitle("Rechenverlauf (Tape)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !history.isEmpty {
                        Button("Exportieren") {
                            generateExportData()
                            showExportAlert = true
                        }
                        .foregroundColor(.blue)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { showHistorySheet = false }
                }
            }
            .alert(isPresented: $showExportAlert) {
                Alert(
                    title: Text("Verlauf exportiert (\(selectedExportFormat.rawValue))"),
                    message: Text("Die Daten wurden in die Zwischenablage kopiert:\n\n\(exportedString.prefix(150))..."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func generateExportData() {
        switch selectedExportFormat {
        case .txt:
            exportedString = history.map { "\($0.expression) = \($0.result)" }.joined(separator: "\n")
        case .csv:
            var csv = "Ausdruck;Ergebnis\n"
            csv += history.map { "\"\($0.expression)\";\"\($0.result)\"" }.joined(separator: "\n")
            exportedString = csv
        case .json:
            let dicts = history.map { ["expression": $0.expression, "result": $0.result] }
            if let data = try? JSONSerialization.data(withJSONObject: dicts, options: .prettyPrinted),
               let jsonStr = String(data: data, encoding: .utf8) {
                exportedString = jsonStr
            } else {
                exportedString = "[]"
            }
        case .markdown:
            var md = "| Ausdruck | Ergebnis |\n| --- | --- |\n"
            md += history.map { "| `\($0.expression)` | **`\($0.result)`** |" }.joined(separator: "\n")
            exportedString = md
        }
        UIPasteboard.general.string = exportedString
    }
    
    private func deleteHistoryItem(at offsets: IndexSet) {
        let reversedIndices = offsets.map { history.count - 1 - $0 }
        for index in reversedIndices {
            if index >= 0 && index < history.count {
                history.remove(at: index)
            }
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
                        .frame(width: max(0, (geo.size.width - 8) * 0.20))
                    
                    calcButton("42", color: .purple) { trigger42Fact() }
                        .frame(width: max(0, (geo.size.width - 8) * 0.20))
                    
                    calcButton("=", color: currentTheme.operatorButtonColor) { calculateResult() }
                        .frame(width: max(0, (geo.size.width - 8) * 0.60))
                }
            }
            .frame(height: verticalSizeClass == .compact ? 28 : 42)
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
                    squareScientificButton("log2") { applyScientificFunc("log2") }
                    squareScientificButton("exp") { applyScientificFunc("exp") }
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
                .font(.system(size: verticalSizeClass == .compact ? 14 : 18, weight: .bold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
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
                    
                    VStack(alignment: .leading, spacing: 6) {
                                            Text("Base64 & Hash (MD5 / SHA)").font(.caption).fontWeight(.bold).foregroundColor(.blue)

                                            TextField("Text oder Base64 eingeben...", text: $cryptoInputText)
                                                .font(.system(size: 13, design: .monospaced))
                                                .textFieldStyle(.roundedBorder)
                                                .autocorrectionDisabled(true)
                                                .textInputAutocapitalization(.never)
                                                .submitLabel(.done)
                                                .onSubmit { hideKeyboard() }

                                            HStack(spacing: 6) {
                                                Button("Base64 Encode") {
                                                    cryptoInputText = BaseCalculator.encodeBase64(cryptoInputText)
                                                    base64DecodeError = false
                                                    hideKeyboard()
                                                }
                                                .buttonStyle(.borderedProminent)
                                                .tint(.blue)
                                                .font(.caption.bold())

                                                Button("Base64 Decode") {
                                                    if let decoded = BaseCalculator.decodeBase64(cryptoInputText) {
                                                        cryptoInputText = decoded
                                                        base64DecodeError = false
                                                    } else {
                                                        base64DecodeError = true
                                                    }
                                                    hideKeyboard()
                                                }
                                                .buttonStyle(.bordered)
                                                .font(.caption.bold())
                                            }

                                            if base64DecodeError {
                                                Text("Kein gültiges Base64 / UTF-8.")
                                                    .font(.caption2)
                                                    .foregroundColor(.red)
                                            }

                                            Picker("Hash", selection: $selectedHashAlgorithm) {
                                                ForEach(BaseCalculator.HashAlgorithm.allCases) { algo in
                                                    Text(algo.rawValue).tag(algo)
                                                }
                                            }
                                            .pickerStyle(.segmented)

                                            let digest = BaseCalculator.hash(cryptoInputText, algorithm: selectedHashAlgorithm)
                                            Text("\(selectedHashAlgorithm.rawValue): \(digest)")
                                                .font(.system(size: 10, design: .monospaced))
                                                .foregroundColor(.green)
                                                .textSelection(.enabled)
                                                .lineLimit(3)
                                        }
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .cornerRadius(8)
                    
                    .padding(8)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    
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
                                        Text("BIN: \(res.bin) Sequenz: \n\(extra)")
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
                .font(.system(size: verticalSizeClass == .compact ? 18 : 25, weight: .bold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
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
        formulaExpression = String(res)
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
            if !formulaExpression.isEmpty && !formulaExpression.hasSuffix(" ") {
                let lastChar = String(formulaExpression.suffix(1))
                if ["+", "-", "×", "÷", "mod", "^"].contains(lastChar) {
                    formulaExpression += " "
                }
            }
            formulaExpression += digit
            isTypingNewNumber = false
        } else {
            if displayValue == "0" {
                displayValue = digit
                if !formulaExpression.isEmpty {
                    formulaExpression = String(formulaExpression.dropLast()) + digit
                } else {
                    formulaExpression = digit
                }
            } else {
                displayValue += digit
                formulaExpression += digit
            }
        }
        while formulaExpression.contains("  ") {
            formulaExpression = formulaExpression.replacingOccurrences(of: "  ", with: " ")
        }
        formulaDisplay = formulaExpression
    }
    
    private func appendSymbol(_ symbol: String) {
        if hasEvaluatedResult {
            formulaExpression = displayValue + " " + symbol + " "
            hasEvaluatedResult = false
        } else {
            let trimmed = formulaExpression.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                formulaExpression = trimmed + " " + symbol + " "
            } else {
                formulaExpression = displayValue + " " + symbol + " "
            }
        }
        formulaExpression = formulaExpression.replacingOccurrences(of: "  ", with: " ")
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
            if displayValue.isEmpty {
                displayValue = "0"
                isTypingNewNumber = true
            }
        }
        
        if !formulaExpression.isEmpty {
            formulaExpression.removeLast()
        }
        
        formulaExpression = formulaExpression.replacingOccurrences(of: "  ", with: " ")
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
        let candidates = nerdFacts.filter { $0 != currentFact }
        currentFact = candidates.randomElement() ?? nerdFacts[0]
        showNerdFact = true
    }
    
    private func applySmartPercentage() {
            let cleanDisplay = displayValue
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: ".")
            guard let current = Double(cleanDisplay) else { return }

            let cleanExpr = formulaExpression
                .replacingOccurrences(of: ",", with: ".")
                .trimmingCharacters(in: .whitespaces)
            let tokens = cleanExpr.components(separatedBy: " ").filter { !$0.isEmpty }

            if useOrderOfOperations {
                // Math-Modus: Bei + oder - wird X% relativ zur Basis berechnet (100 - 20% = 80)
                if tokens.count >= 3,
                   let baseVal = Double(tokens[tokens.count - 3]),
                   ["+", "-"].contains(tokens[tokens.count - 2]) {
                    let relativeVal = baseVal * (current / 100.0)
                    let rawStr = String(relativeVal)
                    displayValue = formatResult(relativeVal)
                    var updated = tokens
                    updated[updated.count - 1] = rawStr
                    formulaExpression = updated.joined(separator: " ")
                    formulaDisplay = formulaExpression
                } else {
                    let pct = current / 100.0
                    let rawStr = String(pct)
                    displayValue = formatResult(pct)
                    if !tokens.isEmpty {
                        var updated = tokens
                        updated[updated.count - 1] = rawStr
                        formulaExpression = updated.joined(separator: " ")
                    } else {
                        formulaExpression = rawStr
                    }
                    formulaDisplay = formulaExpression
                }
            } else {
                // Tischrechner-Modus: Sequenzielle Auswertung mit Prozentbezug auf Zwischenwert
                if tokens.count >= 2, let baseVal = Double(tokens[0]) {
                    let op = tokens[1]
                    let pctAmount = baseVal * (current / 100.0)
                    let res: Double
                    switch op {
                    case "+": res = baseVal + pctAmount
                    case "-": res = baseVal - pctAmount
                    case "×", "*": res = pctAmount
                    case "÷", "/":
                        guard pctAmount != 0 else {
                            displayValue = "Division durch 0"
                            isTypingNewNumber = true
                            return
                        }
                        res = baseVal / (current / 100.0)
                    default:
                        res = pctAmount
                    }
                    let formattedRes = formatResult(res)
                    displayValue = formattedRes
                    formulaDisplay = "\(formatResult(baseVal)) \(op) \(formatResult(current))% ="
                    formulaExpression = String(res)
                    hasEvaluatedResult = true
                    isTypingNewNumber = true
                    appendHistoryItem(expression: "\(formatResult(baseVal)) \(op) \(formatResult(current))%", result: formattedRes)
                } else {
                    let pct = current / 100.0
                    displayValue = formatResult(pct)
                    formulaExpression = String(pct)
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
        if hasEvaluatedResult {
            if let lastItem = history.last {
                let parts = lastItem.expression.components(separatedBy: " ").filter { !$0.isEmpty }
                if parts.count >= 3 {
                    let op = parts[1]
                    let operand = parts[2]
                    formulaExpression = displayValue + " " + op + " " + operand
                }
            }
        }
        
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
                appendHistoryItem(expression: formulaExpression, result: resStr)
                formulaExpression = String(hexResult)
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
                appendHistoryItem(expression: formulaExpression, result: formattedRes)
                formulaExpression = String(res)
            }
            hasEvaluatedResult = true
            isTypingNewNumber = true
        } else {
            displayValue = "Syntaxfehler"
            hasEvaluatedResult = true
            isTypingNewNumber = true
        }
    }
    
    private func appendHistoryItem(expression: String, result: String) {
        if let last = history.last, last.expression == expression && last.result == result {
            return
        }
        history.append(HistoryItem(expression: expression, result: result))
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
        
        if trimmed.hasPrefix("~") {
            let operandStr = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
            if let val = parseHexOrDec(operandStr) {
                return ~val
            }
            return nil
        }
        
        let tokens = trimmed.components(separatedBy: " ").filter { !$0.isEmpty }
        guard !tokens.isEmpty, let firstVal = parseHexOrDec(tokens[0]) else {
            return nil
        }
        
        if tokens.count == 1 {
            return firstVal
        }
        
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
        let rawExpr = expr
            .replacingOccurrences(of: "\u{202F}", with: "")
            .replacingOccurrences(of: "\u{2009}", with: "")
            .replacingOccurrences(of: "\u{200A}", with: "")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: #"(?<=\d)\.(?=\d{3}\b)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: " ", with: "")
        
        var clean = rawExpr.replacingOccurrences(of: "=", with: "").trimmingCharacters(in: .whitespaces)
        
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

        var formatted = clean
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
                
        formatted = formatted.replacingOccurrences(
            of: #"(\d|\))\s*\("#,
            with: "$1 * (",
            options: .regularExpression
        )
        formatted = formatted.replacingOccurrences(
            of: #"\)\s*(\d)"#,
            with: ") * $1",
            options: .regularExpression
        )
                
        var parenBalance = 0
        for char in formatted {
            if char == "(" { parenBalance += 1 }
            else if char == ")" { parenBalance -= 1 }
            if parenBalance < 0 { return nil }
        }
        if parenBalance != 0 { return nil }
                
        let compact = formatted.replacingOccurrences(of: " ", with: "")
        if compact.isEmpty || compact.contains("()") || compact.contains("**") || compact.contains("//") || compact.contains("++") || compact.contains("--") {
            return nil
        }
   
        if let last = compact.last, ["+", "-", "*", "/", "."].contains(String(last)) {
                    return nil
                }
        
        formatted = formatted.replacingOccurrences(
            of: #"(?<![\d.])(\d+)(?![\d.])"#,
            with: "$1.0",
            options: .regularExpression
        )
                
        let parsedExpr = NSExpression(format: formatted)
        if let result = parsedExpr.expressionValue(with: nil, context: nil) as? NSNumber {
            let val = result.doubleValue
            return val.isFinite ? val : nil
        }
                
        return nil
    }
    
    private func evaluateSequentialExpression(_ expr: String) -> Double? {
            let rawExpr = expr
                .replacingOccurrences(of: "\u{202F}", with: "")
                .replacingOccurrences(of: "\u{2009}", with: "")
                .replacingOccurrences(of: "\u{200A}", with: "")
                .replacingOccurrences(of: "'", with: "")
                .replacingOccurrences(of: #"(?<=\d)\.(?=\d{3}\b)"#, with: "", options: .regularExpression)
                // Wichtig: KEIN .replacingOccurrences(of: " ", with: "") hier,
                // da der Tischrechner die Leerzeichen für die Token-Trennung braucht!

            var clean = rawExpr.replacingOccurrences(of: "=", with: "").trimmingCharacters(in: .whitespaces)
            
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
        
        let angleMultiplier = currentAngleMode.multiplierToRadians
        let invAngleMultiplier = currentAngleMode.multiplierFromRadians
        
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
        case "log2":
            guard let r = ScientificCalculator.log2Value(val) else {
            displayValue = "Ungültiger Wert"; isTypingNewNumber = true; return
            }
            res = r
        case "exp":
            guard let r = ScientificCalculator.expValue(val) else {
            displayValue = "Ungültiger Wert"; isTypingNewNumber = true; return
            }
            res = r        default: break
        }
        
        let exprStr = "\(function)(\(formatResult(val)))"
        formulaDisplay = "\(exprStr) ="
        let resStr = formatResult(res)
        displayValue = resStr
        formulaExpression = resStr
        appendHistoryItem(expression: exprStr, result: resStr)
        hasEvaluatedResult = true
        isTypingNewNumber = true
    }
    
    private func applyDeltaPercent() {
            guard let current = Double(displayValue.replacingOccurrences(of: ",", with: ".")) else { return }
            let tokens = formulaExpression.components(separatedBy: " ").filter { !$0.isEmpty }

            // Wenn in formulaExpression ein vorheriger Wert steht (z. B. "80 + 100" oder "80"), nutze den ersten Wert als Basis
            if let firstToken = tokens.first, let base = Double(firstToken), tokens.count >= 2 {
                guard let pctChange = ScientificCalculator.deltaPercent(from: base, to: current) else {
                    displayValue = "Ungültiger Wert"
                    isTypingNewNumber = true
                    return
                }
                let formatted = formatResult(pctChange)
                displayValue = formatted
                formulaDisplay = "Δ% (\(formatResult(base)) → \(formatResult(current))) ="
                formulaExpression = String(pctChange)
                hasEvaluatedResult = true
                isTypingNewNumber = true
                appendHistoryItem(expression: "Δ% (\(formatResult(base)) → \(formatResult(current)))", result: formatted)
            }
        }
    
    private func factorial(_ n: Int) -> Double {
        guard n >= 0 else { return 0 }
        if n == 0 || n == 1 { return 1 }
        var fact: Double = 1
        for i in 2...min(n, 170) { fact *= Double(i) }
        return fact
    }
    
    private func memoryClear() {
            memoryValue = 0.0
            hasMemory = false
        }

        private func memoryRecall() {
            guard hasMemory, memoryValue.isFinite else { return }
            let formatted = formatResult(memoryValue)
            let rawStr = String(memoryValue)
            displayValue = formatted

            if hasEvaluatedResult || formulaExpression.trimmingCharacters(in: .whitespaces).isEmpty {
                formulaExpression = rawStr
                hasEvaluatedResult = false
            } else {
                let trimmed = formulaExpression.trimmingCharacters(in: .whitespaces)
                if let lastChar = trimmed.last, ["+", "-", "×", "÷", "^"].contains(String(lastChar)) || trimmed.hasSuffix("mod") {
                    formulaExpression = trimmed + " " + rawStr
                } else {
                    // Ersetzt den letzten Operanden sauber durch den Speicherwert
                    var tokens = trimmed.components(separatedBy: " ").filter { !$0.isEmpty }
                    if !tokens.isEmpty {
                        tokens[tokens.count - 1] = rawStr
                        formulaExpression = tokens.joined(separator: " ")
                    } else {
                        formulaExpression = rawStr
                    }
                }
            }
            formulaDisplay = formulaExpression
            isTypingNewNumber = true
        }

        private func memoryAdd() {
            let clean = displayValue.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            if let val = Double(clean), val.isFinite {
                memoryValue += val
                hasMemory = true
                isTypingNewNumber = true
            }
        }

        private func memorySub() {
            let clean = displayValue.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            if let val = Double(clean), val.isFinite {
                memoryValue -= val
                hasMemory = true
                isTypingNewNumber = true
            }
        }
    
    private func formatResult(_ val: Double) -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.locale = Locale(identifier: "de_DE")
            formatter.minimumFractionDigits = (decimalPrecisionMode == 2) ? 2 : 0
            formatter.maximumFractionDigits = decimalPrecisionMode
            formatter.usesGroupingSeparator = useThousandsSeparator
            formatter.groupingSeparator = "."
            
            return formatter.string(from: NSNumber(value: val)) ?? "\(val)"
        }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
