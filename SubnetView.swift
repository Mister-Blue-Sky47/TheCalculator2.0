import SwiftUI

struct SubnetView: View {
    @State private var selectedTab: Int = 0
    
    // Standard Subnet-Rechner States
    @State private var ipInput: String = "192.168.1.0"
    @State private var cidrInput: Int = 24
    
    // VLSM-Rechner States
    @State private var vlsmBaseIP: String = "192.168.10.0"
    @State private var vlsmBaseCIDR: Int = 24
    @State private var newSubnetName: String = ""
    @State private var newSubnetHosts: String = ""
    @State private var requirements: [(name: String, hosts: Int)] = [
        ("Verwaltung", 50),
        ("Schulung", 20),
        ("Server", 5),
        ("PtP-Link", 2)
    ]
    
    var computedResult: SubnetResult? {
        SubnetCalculator.calculateSubnet(ipStr: ipInput, cidr: cidrInput)
    }
    
    var vlsmResults: [SubnetResult] {
        // Reinige den IP-String von eventuellen Leerzeichen
        let cleanIP = vlsmBaseIP.trimmingCharacters(in: .whitespacesAndNewlines)
        return SubnetCalculator.calculateVLSM(baseIP: cleanIP, baseCIDR: vlsmBaseCIDR, requirements: requirements)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            
            // Modus Umschaltung: Einzel-Subnetz vs. VLSM-Planer
            Picker("Subnetz Modus", selection: $selectedTab) {
                Text("Standard Subnetz").tag(0)
                Text("VLSM Planer").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            if selectedTab == 0 {
                standardSubnetView
            } else {
                vlsmPlannerView
            }
        }
    }
    
    // MARK: - Standard Subnetz Ansicht
    private var standardSubnetView: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("IPv4 Subnetz-Berechnung")
                        .font(.headline)
                    
                    HStack {
                        TextField("IP-Adresse", text: $ipInput)
                            .keyboardType(.numbersAndPunctuation)
                            .textFieldStyle(.roundedBorder)
                        
                        Picker("/", selection: $cidrInput) {
                            ForEach(8...30, id: \.self) { prefix in
                                Text("/\(prefix)").tag(prefix)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                if let res = computedResult {
                    VStack(spacing: 10) {
                        ResultRow(label: "Netz-ID:", value: "\(res.networkAddress)/\(res.cidr)")
                        ResultRow(label: "Subnetzmaske:", value: res.netmask)
                        ResultRow(label: "Wildcard-Maske:", value: res.wildcard)
                        ResultRow(label: "Broadcast:", value: res.broadcastAddress)
                        ResultRow(label: "Host-Bereich:", value: "\(res.firstHost) - \(res.lastHost)")
                        ResultRow(label: "Nutzbare Hosts:", value: "\(res.usableHosts)")
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                } else {
                    Text("Ungültige IP-Adresse")
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - VLSM Planer Ansicht
    private var vlsmPlannerView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Basis-IP und Subnetz-Auswahl
                VStack(alignment: .leading, spacing: 8) {
                    Text("VLSM Basis-Netzwerk")
                        .font(.headline)
                    
                    HStack {
                        TextField("Basis-IP (z.B. 192.168.10.0)", text: $vlsmBaseIP)
                            .keyboardType(.numbersAndPunctuation)
                            .textFieldStyle(.roundedBorder)
                        
                        Picker("/", selection: $vlsmBaseCIDR) {
                            ForEach(16...28, id: \.self) { prefix in
                                Text("/\(prefix)").tag(prefix)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // Neues Netz hinzufügen
                VStack(alignment: .leading, spacing: 8) {
                    Text("Neues Subnetz anfordern")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        TextField("Netz-Name (z.B. BAR)", text: $newSubnetName)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Hosts", text: $newSubnetHosts)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        
                        Button(action: addRequirement) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // Generierte VLSM Tabelle
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Erzeugte VLSM-Aufteilung")
                            .font(.headline)
                        Spacer()
                        if !requirements.isEmpty {
                            Button("Zurücksetzen") {
                                requirements.removeAll()
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }
                    
                    if vlsmResults.isEmpty {
                        Text("Keine Berechnung möglich. Bitte gültige Basis-IP eingeben.")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        ForEach(vlsmResults) { res in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(res.name)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Text("\(res.networkAddress)/\(res.cidr)")
                                        .font(.system(.body, design: .monospaced))
                                        .fontWeight(.bold)
                                }
                                
                                HStack {
                                    Text("Bereich: \(res.firstHost) - \(res.lastHost)")
                                        .font(.caption)
                                        .monospaced()
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("\(res.usableHosts) Hosts")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding(10)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
    
    private func addRequirement() {
        guard !newSubnetName.isEmpty, let hosts = Int(newSubnetHosts), hosts > 0 else { return }
        requirements.append((name: newSubnetName, hosts: hosts))
        newSubnetName = ""
        newSubnetHosts = ""
    }
}

struct ResultRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.bold)
        }
    }
}
