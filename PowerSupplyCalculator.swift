//
//  PowerSupplyCalculator.swift
//  TheCalculator2.0
//
//  Created by Steffen Beier on 16.11.26.
//

import Foundation

struct PCComponent: Identifiable, Hashable {
    let id = UUID()
    var name: String
    let category: ComponentCategory
    var typicalWattage: Double
    var isCustom: Bool = false
}

enum ComponentCategory: String, CaseIterable, Identifiable {
    case cpu = "Prozessor (CPU)"
    case gpu = "Grafikkarte (GPU)"
    case motherboard = "Mainboard & RAM"
    case storage = "Speichermedien (SSD/HDD)"
    case peripherals = "Lüfter, RGB & Kühlung"
    
    var id: String { self.rawValue }
}

struct PowerSupplyCalculator {
    static let presetComponents: [PCComponent] = [
        // CPUs
        PCComponent(name: "Intel Core i3 / AMD Ryzen 3 (Entry)", category: .cpu, typicalWattage: 65),
        PCComponent(name: "Intel Core i5 / AMD Ryzen 5 (Mid-Range)", category: .cpu, typicalWattage: 88),
        PCComponent(name: "Intel Core i7 / AMD Ryzen 7 (High-End)", category: .cpu, typicalWattage: 125),
        PCComponent(name: "Intel Core i9 / AMD Ryzen 9 (Enthusiast)", category: .cpu, typicalWattage: 200),
        PCComponent(name: "Intel Core i9 / Ryzen 9 (Overclocked / Peak)", category: .cpu, typicalWattage: 280),
        
        // GPUs
        PCComponent(name: "Keine (nur iGPU)", category: .gpu, typicalWattage: 10),
        PCComponent(name: "Mittelklasse (z.B. RTX 4060 / RX 7600)", category: .gpu, typicalWattage: 160),
        PCComponent(name: "Performance (z.B. RTX 4070 / RX 7800 XT)", category: .gpu, typicalWattage: 250),
        PCComponent(name: "High-End (z.B. RTX 4080 / RX 7900 XTX)", category: .gpu, typicalWattage: 320),
        PCComponent(name: "Enthusiast (z.B. RTX 4090)", category: .gpu, typicalWattage: 450),
        
        // Mainboard & RAM
        PCComponent(name: "Standard Mainboard + 2x RAM", category: .motherboard, typicalWattage: 35),
        PCComponent(name: "High-End Mainboard (X/Z-Chipset) + 4x RAM", category: .motherboard, typicalWattage: 65),
        
        // Storage
        PCComponent(name: "1x M.2 NVMe SSD", category: .storage, typicalWattage: 8),
        PCComponent(name: "2x M.2 NVMe SSD + 1x SATA HDD", category: .storage, typicalWattage: 25),
        
        // Peripherals / Cooling
        PCComponent(name: "Luftkühlung + 3 Gehäuselüfter", category: .peripherals, typicalWattage: 20),
        PCComponent(name: "AIO Wasserkühlung (240/360mm) + 6 RGB Lüfter", category: .peripherals, typicalWattage: 50)
    ]
    
    static func calculateTotalWattage(selectedComponents: [PCComponent]) -> (sumWatt: Double, recommendedPSU: Int) {
        let total = selectedComponents.reduce(0) { $0 + $1.typicalWattage }
        let withHeadroom = total * 1.30
        let roundedPSU = Int(ceil(withHeadroom / 50.0) * 50.0)
        let finalPSU = max(roundedPSU, 350)
        return (total, finalPSU)
    }
}
