//
//  ScientificCalculator.swift
//  TheCalculator2.0
//
//  Created by Steffen Beier on 17.11.26.
//

import Foundation

struct ScientificCalculator {
    
    // Wichtige physikalische und technische Konstanten für die maKI Edition
    struct PhysicalConstant: Identifiable {
        let id = UUID()
        let name: String
        let symbol: String
        let value: Double
        let unit: String
        let description: String
    }
    
    static let constants: [PhysicalConstant] = [
        PhysicalConstant(
            name: "Lichtgeschwindigkeit",
            symbol: "c",
            value: 299_792_458.0,
            unit: "m/s",
            description: "Geschwindigkeit des Lichts im Vakuum"
        ),
        PhysicalConstant(
            name: "Planck-Wirkungsquantum",
            symbol: "h",
            value: 6.626_070_15e-34,
            unit: "J·s",
            description: "Fundamentale Konstante der Quantenmechanik"
        ),
        PhysicalConstant(
            name: "Elementarladung",
            symbol: "e",
            value: 1.602_176_634e-19,
            unit: "C",
            description: "Ladung eines Protons / Elektrons"
        ),
        PhysicalConstant(
            name: "Gravitationskonstante",
            symbol: "G",
            value: 6.674_30e-11,
            unit: "m³/(kg·s²)",
            description: "Newtonsche Gravitationskonstante"
        ),
        PhysicalConstant(
            name: "Boltzmann-Konstante",
            symbol: "k",
            value: 1.380_649e-23,
            unit: "J/K",
            description: "Verknüpft Temperatur und Energie"
        ),
        PhysicalConstant(
            name: "Elektrische Feldkonstante",
            symbol: "ε₀",
            value: 8.854_187_817e-12,
            unit: "F/m",
            description: "Dielektrizitätskonstante des Vakuums"
        ),
        PhysicalConstant(
            name: "Magnetische Feldkonstante",
            symbol: "μ₀",
            value: 1.256_637_062_12e-6,
            unit: "N/A²",
            description: "Permeabilität des Vakuums"
        ),
        PhysicalConstant(
            name: "Avogadro-Konstante",
            symbol: "N_A",
            value: 6.022_140_76e23,
            unit: "1/mol",
            description: "Anzahl Teilchen pro Mol"
        )
    ]
    
    // MARK: - Baustein A: log2, exp, Delta%

        /// Logarithmus zur Basis 2 (nur für Werte > 0 definiert)
        static func log2Value(_ x: Double) -> Double? {
            guard x.isFinite, x > 0 else { return nil }
            let res = Foundation.log2(x)
            return res.isFinite ? res : nil
        }

        /// Exponentialfunktion e^x
        static func expValue(_ x: Double) -> Double? {
            guard x.isFinite else { return nil }
            let res = Foundation.exp(x)
            return res.isFinite ? res : nil
        }

        /// Prozentuale Änderung von `oldValue` auf `newValue`: ((newValue - oldValue) / oldValue) * 100
        static func deltaPercent(from oldValue: Double, to newValue: Double) -> Double? {
            guard oldValue.isFinite, newValue.isFinite, oldValue != 0 else { return nil }
            let res = ((newValue - oldValue) / oldValue) * 100.0
            return res.isFinite ? res : nil
        }
    
    // Erweiterte wissenschaftliche Berechnungen
    static func evaluateScientific(expression: String) -> Double? {
        // Hier können bei Bedarf erweiterte Auswertungen oder Formeln ergänzt werden
        let expr = NSExpression(format: expression)
        return expr.expressionValue(with: nil, context: nil) as? Double
    }
}
