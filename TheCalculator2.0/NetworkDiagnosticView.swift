import SwiftUI

struct NetworkDiagnosticView: View {
    @State private var macInput: String = "70:81:05:AA:BB:CC"
    @State private var lookupResult: NetworkDiagnosticCalculator.MACLookupResult? = nil
    
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
}
