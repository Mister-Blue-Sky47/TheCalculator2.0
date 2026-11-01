import Foundation

struct NetworkDiagnosticCalculator {
    
    struct MACLookupResult {
        let macAddress: String
        let vendor: String
        let isValid: Bool
    }
    
    private static let ouiDatabase: [String: String] = [
        "00:50:56": "VMware, Inc.",
        "00:0C:29": "VMware, Inc.",
        "00:1A:11": "Google, Inc.",
        "08:00:27": "Oracle / VirtualBox",
        "B8:27:EB": "Raspberry Pi Foundation",
        "DC:A6:32": "Raspberry Pi Trading Ltd",
        "E4:5F:01": "Raspberry Pi Trading Ltd",
        "00:1B:63": "Apple, Inc.",
        "3C:D0:F8": "Apple, Inc.",
        "D0:11:E5": "Apple, Inc.",
        "00:04:4B": "NVIDIA Corporation",
        "00:15:5D": "Microsoft Corporation",
        "00:1E:67": "Cisco Systems",
        "00:26:99": "Cisco Systems",
        "70:81:05": "AVM GmbH (FRITZ!Box)",
        "34:31:C4": "AVM GmbH (FRITZ!Box)"
    ]
    
    static func lookupMAC(_ mac: String) -> MACLookupResult {
        let clean = mac.replacingOccurrences(of: ":", with: "")
                       .replacingOccurrences(of: "-", with: "")
                       .replacingOccurrences(of: ".", with: "")
                       .uppercased()
        
        guard clean.count >= 6 else {
            return MACLookupResult(macAddress: mac, vendor: "Ungültige MAC-Adresse", isValid: false)
        }
        
        let ouiPrefix = String(clean.prefix(6))
        let formattedOUI = stride(from: 0, to: 6, by: 2).map {
            let start = ouiPrefix.index(ouiPrefix.startIndex, offsetBy: $0)
            let end = ouiPrefix.index(start, offsetBy: 2)
            return String(ouiPrefix[start..<end])
        }.joined(separator: ":")
        
        // Prüfen auf zufällige/private MAC (LAA-Bit gesetzt)
        if let firstByte = UInt8(clean.prefix(2), radix: 16), (firstByte & 0x02) != 0 {
            return MACLookupResult(macAddress: mac, vendor: "Private / Zufällige MAC-Adresse (iOS/Android)", isValid: true)
        }
        
        if let vendor = ouiDatabase[formattedOUI] {
            return MACLookupResult(macAddress: mac, vendor: vendor, isValid: true)
        } else {
            return MACLookupResult(macAddress: mac, vendor: "Hersteller-OUI: \(formattedOUI) (Nicht in Offline-DB)", isValid: true)
        }
    }
    
    struct CommonPort {
        let port: Int
        let name: String
        let description: String
    }
    
    static let standardPorts: [CommonPort] = [
        CommonPort(port: 21, name: "FTP", description: "Dateiübertragung"),
        CommonPort(port: 22, name: "SSH", description: "Sichere Konsole / Terminal"),
        CommonPort(port: 80, name: "HTTP", description: "Unverschlüsseltes Web"),
        CommonPort(port: 443, name: "HTTPS", description: "Verschlüsseltes Web"),
        CommonPort(port: 3389, name: "RDP", description: "Remote Desktop"),
        CommonPort(port: 8080, name: "HTTP-ALT", description: "Alternative Web-Ports / Proxy")
    ]
}
