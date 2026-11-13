import Foundation

struct NetworkDiagnosticCalculator {
    
    struct MACLookupResult {
        let macAddress: String
        let vendor: String
        let isValid: Bool
    }
    
    struct CommonPort {
        let port: Int
        let name: String
        let description: String
    }
    
    // Einheitliche Offline IEEE-OUI Hersteller-Datenbank (Schlüssel ohne Trennzeichen, Großbuchstaben)
    static let ouiDatabase: [String: String] = [
        "001A2B": "Cisco Systems, Inc",
        "00000C": "Cisco Systems, Inc",
        "001B2A": "Cisco Systems, Inc",
        "002414": "Cisco Systems, Inc",
        "005056": "VMware, Inc.",
        "000C29": "VMware, Inc.",
        "001C14": "VMware, Inc.",
        "000569": "VMware, Inc.",
        "00155D": "Microsoft Corporation (Hyper-V)",
        "708105": "Raspberry Pi Trading Ltd",
        "B827EB": "Raspberry Pi Trading Ltd",
        "DCF505": "Raspberry Pi Trading Ltd",
        "E45F01": "Raspberry Pi Trading Ltd",
        "001A11": "Google, Inc.",
        "3C5AB4": "Google, Inc.",
        "F88FCA": "Apple, Inc.",
        "0017F2": "Apple, Inc.",
        "001E52": "Apple, Inc.",
        "002312": "Apple, Inc.",
        "28CFE9": "Apple, Inc.",
        "6854FD": "Apple, Inc.",
        "ACBC32": "Apple, Inc.",
        "34159E": "AVM GmbH (Fritz!Box)",
        "001A3F": "AVM GmbH (Fritz!Box)",
        "C42DCF": "AVM GmbH (Fritz!Box)",
        "0024FE": "AVM GmbH (Fritz!Box)",
        "989EE0": "Intel Corporate",
        "001B77": "Intel Corporate",
        "00215C": "Intel Corporate",
        "0022FB": "Intel Corporate",
        "0013EF": "Netgear",
        "204E7F": "Netgear",
        "00146C": "Netgear",
        "001EEC": "Realtek Semiconductor" // Schreibfehler bei 001EEEC korrigiert (OUI hat 6 Zeichen)
    ]
    
    // Statische Methode zur MAC-Adressanalyse (perfekt für SwiftUI Views & Controller)
    static func lookupMAC(_ mac: String) -> MACLookupResult {
        // Bereinigen der MAC-Adresse (nur Hex-Zeichen behalten)
        let cleaned = mac.uppercased().components(separatedBy: CharacterSet(charactersIn: "0123456789ABCDEF").inverted).joined()
        
        guard cleaned.count >= 6 else {
            return MACLookupResult(macAddress: mac, vendor: "Ungültige MAC-Adresse (Zu kurz)", isValid: false)
        }
        
        let prefix = String(cleaned.prefix(6))
        
        // 1. Prüfen auf zufällige / private MAC (LAA-Bit / Locally Administered Address: Bit 1 des ersten Bytes gesetzt)
        if let firstByte = UInt8(prefix.prefix(2), radix: 16), (firstByte & 0x02) != 0 {
            return MACLookupResult(macAddress: mac, vendor: "Private / Zufällige MAC-Adresse (iOS / Android / macOS)", isValid: true)
        }
        
        // 2. OUI in der Datenbank suchen
        if let vendor = ouiDatabase[prefix] {
            return MACLookupResult(macAddress: mac, vendor: vendor, isValid: true)
        } else {
            // Formatiertes OUI für die Anzeige (XX:XX:XX)
            let formattedOUI = stride(from: 0, to: 6, by: 2).map {
                let start = prefix.index(prefix.startIndex, offsetBy: $0)
                let end = prefix.index(start, offsetBy: 2)
                return String(prefix[start..<end])
            }.joined(separator: ":")
            
            return MACLookupResult(macAddress: mac, vendor: "Unbekannter Hersteller (OUI: \(formattedOUI))", isValid: true)
        }
    }
    
    // Standard-Ports für das Diagnose-Modul
    static let standardPorts: [CommonPort] = [
        CommonPort(port: 21, name: "FTP", description: "Dateiübertragung"),
        CommonPort(port: 22, name: "SSH", description: "Sichere Konsole / Terminal"),
        CommonPort(port: 80, name: "HTTP", description: "Unverschlüsseltes Web"),
        CommonPort(port: 443, name: "HTTPS", description: "Verschlüsseltes Web"),
        CommonPort(port: 3389, name: "RDP", description: "Remote Desktop"),
        CommonPort(port: 8080, name: "HTTP-ALT", description: "Alternative Web-Ports / Proxy")
    ]
}
