import Foundation

struct BaseCalculator {
    
    struct ConversionResult {
        let dec: String
        let hex: String
        let bin: String
        let oct: String
    }
    
    /// Konvertiert eine Ganzzahl in alle gängigen IT-Zahlenbasen
    static func convert(value: Int64) -> ConversionResult {
        let decStr = String(value)
        let hexStr = "0x" + String(value, radix: 16, uppercase: true)
        let binStr = "0b" + String(value, radix: 2)
        let octStr = "0o" + String(value, radix: 8)
        
        return ConversionResult(dec: decStr, hex: hexStr, bin: binStr, oct: octStr)
    }
    
    /// Führt bitweise Operationen zwischen zwei Integern aus
    static func bitwiseOp(_ a: Int64, _ b: Int64, op: String) -> Int64 {
        switch op {
        case "AND": return a & b
        case "OR":  return a | b
        case "XOR": return a ^ b
        case "<<":  return a << min(b, 63)
        case ">>":  return a >> min(b, 63)
        default:    return b
        }
    }
}
