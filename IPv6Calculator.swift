import Foundation

struct IPv6Calculator {
    
    struct IPv6Result {
        let expandedAddress: String
        let compressedAddress: String
        let prefixLength: Int
        let networkPrefix: String
        let totalSubnetsPrefix64: String
    }
    
    /// Baut eine eingegebene IPv6-Adresse voll aus (8 Blöcke à 4 Hex-Stellen) und ermittelt Präfix-Details
    static func calculate(address: String, prefix: Int) -> IPv6Result? {
        let cleanAddress = address.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanAddress.isEmpty else { return nil }
        
        let expanded = expandIPv6(cleanAddress)
        let compressed = compressIPv6(expanded)
        
        // Netzpräfix ermitteln (z.B. /64)
        let networkPrefix = calculateNetworkPrefix(expanded: expanded, prefixLength: prefix)
        
        // Anzahl möglicher /64 Subnetze bei kürzerem Präfix
        let subnets64Count: String
        if prefix <= 64 {
            let diff = 64 - prefix
            let count = pow(2.0, Double(diff))
            subnets64Count = String(format: "%.0f", count)
        } else {
            subnets64Count = "Subnetz kleiner als /64"
        }
        
        return IPv6Result(
            expandedAddress: expanded,
            compressedAddress: compressed,
            prefixLength: prefix,
            networkPrefix: networkPrefix,
            totalSubnetsPrefix64: subnets64Count
        )
    }
    
    /// Expandiert :: zu vollständigen 0000-Hex-Blöcken
    private static func expandIPv6(_ ip: String) -> String {
        let components = ip.components(separatedBy: "::")
        
        if components.count == 2 {
            let left = components[0].split(separator: ":")
            let right = components[1].split(separator: ":")
            let missingBlocks = 8 - (left.count + right.count)
            
            var middle = [String]()
            for _ in 0..<missingBlocks {
                middle.append("0000")
            }
            
            let fullLeft = left.map { padBlock(String($0)) }
            let fullRight = right.map { padBlock(String($0)) }
            let full = fullLeft + middle + fullRight
            return full.joined(separator: ":")
        } else {
            let blocks = ip.split(separator: ":").map { padBlock(String($0)) }
            return blocks.joined(separator: ":")
        }
    }
    
    private static func padBlock(_ block: String) -> String {
        let padded = String(repeating: "0", count: max(0, 4 - block.count)) + block
        return padded
    }
    
    /// Komprimiert aufeinanderfolgende 0000-Blöcke wieder zu ::
    private static func compressIPv6(_ expanded: String) -> String {
        // Vereinfachte Standard-Komprimierung für Präsentationszwecke
        return expanded.replacingOccurrences(of: ":0000:0000:", with: "::")
            .replacingOccurrences(of: ":0000:", with: ":0:")
    }
    
    private static func calculateNetworkPrefix(expanded: String, prefixLength: Int) -> String {
        let blocks = expanded.split(separator: ":")
        guard blocks.count == 8 else { return expanded }
        
        let fullHex = blocks.joined()
        let bitIndex = prefixLength / 4
        
        let prefixHex = String(fullHex.prefix(bitIndex))
        let remainingHex = String(repeating: "0", count: 32 - prefixHex.count)
        let fullNetworkHex = prefixHex + remainingHex
        
        var formatted = [String]()
        for i in stride(from: 0, to: 32, by: 4) {
            let start = fullNetworkHex.index(fullNetworkHex.startIndex, offsetBy: i)
            let end = fullNetworkHex.index(start, offsetBy: 4)
            formatted.append(String(fullNetworkHex[start..<end]))
        }
        
        return formatted.joined(separator: ":") + " /\(prefixLength)"
    }
}
