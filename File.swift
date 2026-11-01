import SwiftUI

struct BaseHexView: View {
    @State private var inputVal: String = "42"
    @State private var secondVal: String = "15"
    @State private var selectedOp: String = "AND"
    
    private var currentInt: Int64 {
        Int64(inputVal) ?? 0
    }
    
    private var secondInt: Int64 {
        Int64(secondVal) ?? 0
    }
    
    private var conversion: BaseCalculator.ConversionResult {
        BaseCalculator.convert(value: currentInt)
    }
    
    private var bitwiseResult: BaseCalculator.ConversionResult {
        let res = BaseCalculator.bitwiseOp(currentInt, secondInt, op: selectedOp)
        return BaseCalculator.convert(value: res)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // KACHEL 1: Umrechnung der Zahlenbasen
                VStack(alignment: .leading, spacing: 12) {
                    Text("Zahlenbasis-Konverter")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dezimal-Eingabe (DEC)").font(.caption).foregroundColor(.secondary)
                        TextField("Zahl eingeben", text: $inputVal)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        resultRow(label: "HEX", value: conversion.hex)
                        resultRow(label: "BIN", value: conversion.bin)
                        resultRow(label: "OCT", value: conversion.oct)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                .padding(.horizontal)
                
                // KACHEL 2: Bitweise Logik
                VStack(alignment: .leading, spacing: 12) {
                    Text("Bitweise Logik-Operationen")
                        .font(.headline)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Wert A (DEC)").font(.caption).foregroundColor(.secondary)
                            TextField("Wert A", text: $inputVal)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Wert B (DEC)").font(.caption).foregroundColor(.secondary)
                            TextField("Wert B", text: $secondVal)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    Picker("Operation", selection: $selectedOp) {
                        Text("AND (&)").tag("AND")
                        Text("OR (|)").tag("OR")
                        Text("XOR (^)").tag("XOR")
                        Text("<<").tag("<<")
                        Text(">>").tag(">>")
                    }
                    .pickerStyle(.segmented)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ergebnis der Bit-Verknüpfung:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        resultRow(label: "DEC", value: bitwiseResult.dec)
                        resultRow(label: "HEX", value: bitwiseResult.hex)
                        resultRow(label: "BIN", value: bitwiseResult.bin)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
        }
    }
    
    private func resultRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.accentColor.opacity(0.15))
                .cornerRadius(4)
            
            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
            Spacer()
        }
    }
}
