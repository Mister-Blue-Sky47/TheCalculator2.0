import SwiftUI

struct ITOverlaysView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Int = 0
    @State private var rj45Standard: String = "T568B"
    @State private var poeCableLength: Double = 50.0
    @State private var selectedPoeType: Int = 1
    
    private let poeStandards: [(name: String, ieee: String, pseWatt: Double, pdWatt: Double, pairs: String)] = [
        ("PoE (Typ 1)", "802.3af", 15.4, 12.95, "2 Paare (1-2, 3-6)"),
        ("PoE+ (Typ 2)", "802.3at", 30.0, 25.5, "2 Paare (1-2, 3-6)"),
        ("PoE++ (Typ 3)", "802.3bt", 60.0, 51.0, "4 Paare (alle 8 Adern)"),
        ("PoE++ (Typ 4)", "802.3bt", 90.0, 71.3, "4 Paare (alle 8 Adern)")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Picker("Overlay-Kategorie", selection: $selectedTab) {
                    Text("RJ45 Pinout").tag(0)
                    Text("LWL & Stecker").tag(1)
                    Text("PoE-Standards").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                ScrollView {
                    VStack(spacing: 12) {
                        if selectedTab == 0 {
                            rj45Section
                        } else if selectedTab == 1 {
                            lwlSection
                        } else {
                            poeSection
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("IT-Overlays & Referenzen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - 1. RJ45 Overlay (T568A / T568B)
    private var rj45Section: some View {
        let pins: [(pin: Int, colorName: String, color: Color, signal: String)] = rj45Standard == "T568B" ? [
            (1, "Weiß / Orange", .orange.opacity(0.45), "TX+ (BI_DA+)"),
            (2, "Orange", .orange, "TX- (BI_DA-)"),
            (3, "Weiß / Grün", .green.opacity(0.45), "RX+ (BI_DB+)"),
            (4, "Blau", .blue, "BI_DC+"),
            (5, "Weiß / Blau", .blue.opacity(0.45), "BI_DC-"),
            (6, "Grün", .green, "RX- (BI_DB-)"),
            (7, "Weiß / Braun", .brown.opacity(0.45), "BI_DD+"),
            (8, "Braun", .brown, "BI_DD-")
        ] : [
            (1, "Weiß / Grün", .green.opacity(0.45), "TX+ (BI_DA+)"),
            (2, "Grün", .green, "TX- (BI_DA-)"),
            (3, "Weiß / Orange", .orange.opacity(0.45), "RX+ (BI_DB+)"),
            (4, "Blau", .blue, "BI_DC+"),
            (5, "Weiß / Blau", .blue.opacity(0.45), "BI_DC-"),
            (6, "Orange", .orange, "RX- (BI_DB-)"),
            (7, "Weiß / Braun", .brown.opacity(0.45), "BI_DD+"),
            (8, "Braun", .brown, "BI_DD-")
        ]
        
        return VStack(alignment: .leading, spacing: 10) {
            Picker("Belegungsstandard", selection: $rj45Standard) {
                Text("TIA-568B (Standard DE)").tag("T568B")
                Text("TIA-568A").tag("T568A")
            }
            .pickerStyle(.segmented)
            
            VStack(spacing: 6) {
                ForEach(pins, id: \.pin) { item in
                    HStack(spacing: 10) {
                        Text("Pin \(item.pin)")
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .frame(width: 44, alignment: .leading)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(item.color)
                            .frame(width: 24, height: 14)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.primary.opacity(0.2), lineWidth: 1))
                        
                        Text(item.colorName)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(item.signal)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(6)
                }
            }
            
            Text("Hinweis: Crossover-Kabel = eine Seite T568A, andere Seite T568B (1↔3 und 2↔6 gekreuzt).")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - 2. LWL Overlay (Faser- & Steckertypen)
    private var lwlSection: some View {
        let fibers: [(type: String, core: String, color: String, wavelength: String, maxDist: String)] = [
            ("OM3 (Multimode)", "50/125 µm", "Aqua (Türkis)", "850 nm", "300 m @ 10 Gbit/s"),
            ("OM4 (Multimode)", "50/125 µm", "Erikaviolett / Aqua", "850 nm", "400–550 m @ 10 Gbit/s"),
            ("OM5 (Wideband MM)", "50/125 µm", "Limonengrün", "850–953 nm", "400 m @ 40/100 Gbit/s"),
            ("OS2 (Singlemode)", "9/125 µm", "Gelb", "1310 / 1550 nm", "bis 40+ km @ 10–100 Gbit/s")
        ]
        
        let connectors: [(name: String, info: String)] = [
            ("LC (Duplex)", "Standard für SFP / SFP+ Transceiver (1,25 mm Ferrule)"),
            ("SC (Simplex/Duplex)", "Steckverbinder in Patchfeldern & FTTH-Anschlüssen (2,5 mm Ferrule)"),
            ("MPO / MTP", "Mehrfaser-Stecker (12/24 Fasern) für 40G/100G/400G Rechenzentren"),
            ("APC vs. UPC", "APC (Grün, 8° Schrägschliff, geringste Reflexion) • UPC (Blau, 0°)")
        ]
        
        return VStack(alignment: .leading, spacing: 10) {
            Text("Glasfaser-Kategorien")
                .font(.caption).fontWeight(.bold).foregroundColor(.blue)
            
            ForEach(fibers, id: \.type) { f in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(f.type).font(.caption).fontWeight(.bold)
                        Spacer()
                        Text(f.core).font(.system(.caption2, design: .monospaced)).foregroundColor(.secondary)
                    }
                    Text("Mantel: \(f.color) • \(f.wavelength) • Reichweite: \(f.maxDist)")
                        .font(.caption2).foregroundColor(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
            }
            
            Text("Steckverbinder & Schliffe")
                .font(.caption).fontWeight(.bold).foregroundColor(.blue)
                .padding(.top, 4)
            
            ForEach(connectors, id: \.name) { c in
                VStack(alignment: .leading, spacing: 2) {
                    Text(c.name).font(.caption).fontWeight(.bold)
                    Text(c.info).font(.caption2).foregroundColor(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - 3. PoE Overlay & Kabellängen-Verlust
    private var poeSection: some View {
        let current = poeStandards[selectedPoeType]
        let lossFactor = min(poeCableLength / 100.0, 1.0)
        let estimatedPd = current.pseWatt - ((current.pseWatt - current.pdWatt) * lossFactor)
        
        return VStack(alignment: .leading, spacing: 10) {
            Picker("PoE-Standard", selection: $selectedPoeType) {
                ForEach(0..<poeStandards.count, id: \.self) { idx in
                    Text(poeStandards[idx].ieee).tag(idx)
                }
            }
            .pickerStyle(.segmented)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("\(current.name) (\(current.ieee))")
                    .font(.subheadline).fontWeight(.bold)
                Text("Max. Leistung am Switch (PSE): \(String(format: "%.1f", current.pseWatt)) W")
                    .font(.caption)
                Text("Garantiert am Endgerät (PD bei 100 m): \(String(format: "%.2f", current.pdWatt)) W")
                    .font(.caption)
                Text("Adernpaare: \(current.pairs) • Max. Segmentlänge: 100 m (Cat 5e/6/6A)")
                    .font(.caption2).foregroundColor(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Kabellänge: \(Int(poeCableLength)) m")
                        .font(.caption).fontWeight(.bold)
                    Spacer()
                    Text("Verfügbar am PD: ~\(String(format: "%.1f", estimatedPd)) W")
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                Slider(value: $poeCableLength, in: 5...100, step: 5)
            }
            .padding(10)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
        }
    }
}
