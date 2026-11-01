import SwiftUI

struct IPv6View: View {
    @State private var inputAddress: String = "2001:db8::1"
    @State private var selectedPrefix: Int = 64
    @State private var result: IPv6Calculator.IPv6Result? = nil
    
    let commonPrefixes = [32, 48, 56, 64, 80, 96, 128]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                Text("IPv6 Subnetz & Präfix-Analyse")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Eingabe-Bereich
                VStack(alignment: .leading, spacing: 8) {
                    Text("IPv6-Adresse (z. B. 2001:db8::1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("2001:db8::1", text: $inputAddress)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .monospaced()
                    
                    HStack {
                        Text("Präfix-Länge:")
                            .font(.subheadline)
                        
                        Picker("Präfix", selection: $selectedPrefix) {
                            ForEach(commonPrefixes, id: \.self) { prefix in
                                Text("/\(prefix)").tag(prefix)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Button(action: calculate) {
                        Label("IPv6 Berechnen", systemImage: "network")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 4)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // Ergebnis-Bereich
                if let res = result {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Berechnungsergebnis")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Divider()
                        
                        IPv6ResultRow(label: "Expandierte Adresse", value: res.expandedAddress)
                        IPv6ResultRow(label: "Komprimierte Adresse", value: res.compressedAddress)
                        IPv6ResultRow(label: "Netzwerk-Präfix", value: res.networkPrefix)
                        IPv6ResultRow(label: "Mögliche /64 Subnetze", value: res.totalSubnetsPrefix64)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .onAppear {
            calculate()
        }
    }
    
    private func calculate() {
        result = IPv6Calculator.calculate(address: inputAddress, prefix: selectedPrefix)
    }
}

struct IPv6ResultRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .monospaced()
                .foregroundColor(.primary)
                .textSelection(.enabled)
        }
    }
}
