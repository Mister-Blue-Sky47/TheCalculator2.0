//
//  ScientificView.swift
//  TheCalculator2.0
//
//  Created by Steffen Beier on 17.11.26.
//

import SwiftUI

struct ScientificView: View {
    @State private var searchText: String = ""
    @State private var copiedSymbol: String? = nil
    
    var filteredConstants: [ScientificCalculator.PhysicalConstant] {
        if searchText.isEmpty {
            return ScientificCalculator.constants
        } else {
            return ScientificCalculator.constants.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.symbol.localizedCaseInsensitiveContains(searchText) ||
                $0.unit.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("maKI Edition – Wissenschaft & Konstanten")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Physikalische und technische Standardwerte für Berechnungen.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Suchfeld
                TextField("Konstante suchen...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                
                if let copied = copiedSymbol {
                    Text("✓ \(copied) in die Zwischenablage kopiert!")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                // Liste der Konstanten
                VStack(spacing: 8) {
                    ForEach(filteredConstants) { item in
                        Button(action: {
                            UIPasteboard.general.string = String(item.value)
                            copiedSymbol = item.symbol
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(item.symbol)
                                            .font(.system(.body, design: .monospaced))
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                        Text("(\(item.name))")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                    }
                                    Text(item.description)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(item.value)")
                                        .font(.system(.caption, design: .monospaced))
                                        .fontWeight(.bold)
                                    Text(item.unit)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(10)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
    }
}
