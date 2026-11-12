import Foundation

struct BaseCalculator {
    struct ConversionResult {
        let dec: String
        let hex: String
        let oct: String
        let bin: String
        let charInfo: String
    }

    static func convert(value: Int64) -> ConversionResult {
        let unsignedPattern = UInt64(bitPattern: value)
        let hexStr = "0x" + String(unsignedPattern, radix: 16).uppercased()
        let octStr = "0o" + String(unsignedPattern, radix: 8)
        let binStr = "0b" + String(unsignedPattern, radix: 2)
        
        return ConversionResult(
            dec: String(value),
            hex: hexStr,
            oct: octStr,
            bin: binStr,
            charInfo: describeCharacter(for: value)
        )
    }

    // Kompatibilitäts-Methode für File.swift
        static func bitwiseOp(_ a: Int64, _ b: Int64 = 0, op: String) -> Int64 {
            switch op {
            case "AND", "&": return a & b
            case "OR", "|": return a | b
            case "XOR", "^": return a ^ b
            case "NOT", "~": return ~a
            case "<<": return a << min(max(b, 0), 63)
            case ">>": return a >> min(max(b, 0), 63)
            default: return a
            }
        }

    static func describeCharacter(for value: Int64) -> String {
        guard value >= 0 && value <= 0x10FFFF else {
            return "Zeichen: (Außerhalb Unicode-Bereich)"
        }
        
        let code = Int(value)
        
        // ASCII Steuerzeichen 0..31 und 127
        let controlNames: [Int: String] = [
            0: "NUL (Null)", 1: "SOH (Start of Heading)", 2: "STX (Start of Text)",
            3: "ETX (End of Text)", 4: "EOT (End of Transmission)", 5: "ENQ (Enquiry)",
            6: "ACK (Acknowledge)", 7: "BEL (Bell / Signal)", 8: "BS (Backspace)",
            9: "TAB (Horizontal Tab)", 10: "LF (Line Feed)", 11: "VT (Vertical Tab)",
            12: "FF (Form Feed)", 13: "CR (Carriage Return)", 14: "SO (Shift Out)",
            15: "SI (Shift In)", 16: "DLE (Data Link Escape)", 17: "DC1 (Device Control 1)",
            18: "DC2 (Device Control 2)", 19: "DC3 (Device Control 3)", 20: "DC4 (Device Control 4)",
            21: "NAK (Negative Ack)", 22: "SYN (Synchronous Idle)", 23: "ETB (End of Block)",
            24: "CAN (Cancel)", 25: "EM (End of Medium)", 26: "SUB (Substitute)",
            27: "ESC (Escape)", 28: "FS (File Separator)", 29: "GS (Group Separator)",
            30: "RS (Record Separator)", 31: "US (Unit Separator)", 127: "DEL (Delete)"
        ]
        
        if let ctrl = controlNames[code] {
            return "ASCII Steuerzeichen: [\(ctrl)]"
        }
        
        // C1 Steuerzeichen (128..159)
        if code >= 128 && code <= 159 {
            return String(format: "Unicode Steuerzeichen (U+%04X)", code)
        }
        
        // Druckbares ASCII (32..126) oder Unicode Scalar
        if let scalar = UnicodeScalar(code) {
            let char = Character(scalar)
            if code <= 126 {
                return "ASCII: '\(char)' (Dec \(code))"
            } else {
                return String(format: "Unicode: '%@' (U+%04X)", String(char), code)
            }
        }
        
        return "Zeichen: (UTF-16 Surrogate / Ungültig)"
    }
}
