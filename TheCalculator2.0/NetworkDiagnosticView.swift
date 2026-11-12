import SwiftUI

struct NetworkDiagnosticView: View {
    @State private var macInput: String = "70:81:05:AA:BB:CC"
    @State private var lookupResult: NetworkDiagnosticCalculator.MACLookupResult? = nil
    
    // States für Übertragungszeit-Rechner
    @State private var fileSizeInput: String = "50"
    @State private var selectedSizeUnit: String = "GiB"
    @State private var bandwidthInput: String = "1"
    @State private var selectedBandwidthUnit: String = "Gbit/s"
    @State private var includeProtocolOverhead: Bool = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                Text("Network Diagnostic Suite")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // --- BEREICH 1: MAC OUI LOOKUP ---
                VStack(alignment: .leading, spacing: 10) {
                    Label("MAC-Adresse OUI Lookup", systemImage: "text.magnifyingglass")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Ermittelt den Hersteller anhand der ersten 3 Bytes (OUI).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("z. B. 70:81:05:12:34:56", text: $macInput)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .monospaced()
                    
                    Button(action: performMACLookup) {
                        Label("Hersteller suchen", systemImage: "cpu")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    if let result = lookupResult {
                        VStack(alignment: .leading, spacing: 6) {
                            Divider()
                            
                            HStack {
                                Text("Hersteller:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(result.vendor)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(result.isValid ? .primary : .red)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // --- BEREICH 2: PORT REFERENZ ---
                VStack(alignment: .leading, spacing: 10) {
                    Label("Standard IT-Ports Referenz", systemImage: "network.badge.shield.half.filled")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    VStack(spacing: 8) {
                        ForEach(NetworkDiagnosticCalculator.standardPorts, id: \.port) { portInfo in
                            HStack {
                                Text("\(portInfo.port)")
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.bold)
                                    .frame(width: 50, alignment: .leading)
                                
                                VStack(alignment: .leading) {
                                    Text(portInfo.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text(portInfo.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(8)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // --- BEREICH 3: ÜBERTRAGUNGSZEIT-RECHNER ---
                VStack(alignment: .leading, spacing: 10) {
                    Label("Übertragungszeit-Rechner", systemImage: "arrow.left.arrow.right.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Berechnet die Dauer inkl. SI- (1000) & IEC-Präfixen (1024).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        TextField("Größe", text: $fileSizeInput)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .monospaced()
                        
                        Picker("Größeneinheit", selection: $selectedSizeUnit) {
                            ForEach(["Bit", "Byte", "KB", "MB", "GB", "TB", "PB", "EB", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB"], id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(8)
                    }
                    
                    HStack(spacing: 8) {
                        TextField("Bandbreite", text: $bandwidthInput)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .monospaced()
                        
                        Picker("Bandbreiteneinheit", selection: $selectedBandwidthUnit) {
                            ForEach(["bit/s", "kbit/s", "Mbit/s", "Gbit/s", "Tbit/s", "KB/s", "MB/s", "GB/s"], id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(8)
                    }
                    
                    Toggle("TCP/IP-Overhead (~6 % Verlust) berücksichtigen", isOn: $includeProtocolOverhead)
                        .font(.caption)
                    
                    Divider()
                    
                    HStack {
                        Text("Geschätzte Dauer:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(calculateTransferTime())
                            .font(.system(.subheadline, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
            .padding()
        }
        .onAppear {
            performMACLookup()
        }
    }
    
    private func performMACLookup() {
        lookupResult = NetworkDiagnosticCalculator.lookupMAC(macInput)
    }
    
    private func calculateTransferTime() -> String {
        let sizeVal = Double(fileSizeInput.replacingOccurrences(of: ",", with: ".")) ?? 0
        let bwVal = Double(bandwidthInput.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard sizeVal > 0, bwVal > 0 else { return "0 s" }
        
        let sizeToBits: [String: Double] = [
            "Bit": 1,
            "Byte": 8,
            "KB": 8e3, "MB": 8e6, "GB": 8e9, "TB": 8e12, "PB": 8e15, "EB": 8e18,
            "KiB": 8 * pow(1024, 1),
            "MiB": 8 * pow(1024, 2),
            "GiB": 8 * pow(1024, 3),
            "TiB": 8 * pow(1024, 4),
            "PiB": 8 * pow(1024, 5),
            "EiB": 8 * pow(1024, 6)
        ]
        
        let bwToBps: [String: Double] = [
            "bit/s": 1,
            "kbit/s": 1e3,
            "Mbit/s": 1e6,
            "Gbit/s": 1e9,
            "Tbit/s": 1e12,
            "KB/s": 8e3,
            "MB/s": 8e6,
            "GB/s": 8e9
        ]
        
        let totalBits = sizeVal * (sizeToBits[selectedSizeUnit] ?? 8)
        let effectiveBps = bwVal * (bwToBps[selectedBandwidthUnit] ?? 1) * (includeProtocolOverhead ? 0.94 : 1.0)
        let seconds = totalBits / effectiveBps
        
        if seconds < 1 {
            return String(format: "%.0f ms", seconds * 1000)
        } else if seconds < 60 {
            return String(format: "%.2f s", seconds)
        } else if seconds < 3600 {
            let m = Int(seconds) / 60
            let s = Int(seconds) % 60
            return "\(m) min \(s) s"
        } else {
            let h = Int(seconds) / 3600
            let m = (Int(seconds) % 3600) / 60
            let s = Int(seconds) % 60
            return "\(h) h \(m) min \(s) s"
        }
    }
}
