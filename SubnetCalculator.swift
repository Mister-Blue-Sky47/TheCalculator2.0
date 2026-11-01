import Foundation

// MARK: - Subnetz Ergebnis-Struktur
struct SubnetResult: Identifiable {
    let id = UUID()
    let name: String
    let networkAddress: String
    let netmask: String
    let wildcard: String
    let broadcastAddress: String
    let firstHost: String
    let lastHost: String
    let totalHosts: Int
    let usableHosts: Int
    let cidr: Int
}

// MARK: - Subnetz & VLSM Logik-Klasse
class SubnetCalculator {
    
    // IP-String (z.B. "192.168.1.1") zu UInt32 umwandeln
    static func ipToUInt32(_ ip: String) -> UInt32? {
        let parts = ip.split(separator: ".").compactMap { UInt32($0) }
        guard parts.count == 4, parts.allSatisfy({ $0 <= 255 }) else { return nil }
        return (parts[0] << 24) | (parts[1] << 16) | (parts[2] << 8) | parts[3]
    }
    
    // UInt32 zu IP-String umwandeln
    static func uint32ToIP(_ ipInt: UInt32) -> String {
        return "\(ipInt >> 24 & 255).\(ipInt >> 16 & 255).\(ipInt >> 8 & 255).\(ipInt & 255)"
    }
    
    // Berechnet einzelnes Subnetz aus IP und CIDR
    static func calculateSubnet(ipStr: String, cidr: Int, name: String = "Netzwerk") -> SubnetResult? {
        guard let ipInt = ipToUInt32(ipStr), cidr >= 0 && cidr <= 32 else { return nil }
        
        let maskInt: UInt32 = cidr == 0 ? 0 : (0xFFFFFFFF << (32 - cidr))
        let wildcardInt = ~maskInt
        let networkInt = ipInt & maskInt
        let broadcastInt = networkInt | wildcardInt
        
        let totalHosts = Int(pow(2.0, Double(32 - cidr)))
        let usableHosts = cidr >= 31 ? (cidr == 31 ? 2 : 1) : max(0, totalHosts - 2)
        
        let firstHostInt = (cidr >= 31) ? networkInt : networkInt + 1
        let lastHostInt = (cidr >= 31) ? broadcastInt : broadcastInt - 1
        
        return SubnetResult(
            name: name,
            networkAddress: uint32ToIP(networkInt),
            netmask: uint32ToIP(maskInt),
            wildcard: uint32ToIP(wildcardInt),
            broadcastAddress: uint32ToIP(broadcastInt),
            firstHost: uint32ToIP(firstHostInt),
            lastHost: uint32ToIP(lastHostInt),
            totalHosts: totalHosts,
            usableHosts: usableHosts,
            cidr: cidr
        )
    }
    
    // VLSM Berechnungs-Algorithmus nach Host-Bedarf
    static func calculateVLSM(baseIP: String, baseCIDR: Int, requirements: [(name: String, hosts: Int)]) -> [SubnetResult] {
        guard var currentIPInt = ipToUInt32(baseIP) else { return [] }
        
        // Nach Host-Bedarf absteigend sortieren (VLSM-Grundregel)
        let sortedReqs = requirements.sorted { $0.hosts > $1.hosts }
        var results: [SubnetResult] = []
        
        for req in sortedReqs {
            // Benötigte Bit-Anzahl für Hosts ermitteln (+2 für Net-ID & Broadcast)
            let neededHosts = req.hosts + 2
            var hostBits = 0
            while (1 << hostBits) < neededHosts {
                hostBits += 1
            }
            let reqCIDR = 32 - max(hostBits, 2)
            
            if let result = calculateSubnet(ipStr: uint32ToIP(currentIPInt), cidr: reqCIDR, name: req.name) {
                results.append(result)
                // Sprung zum nächsten freien Subnetz
                if let netInt = ipToUInt32(result.networkAddress) {
                    currentIPInt = netInt + UInt32(result.totalHosts)
                }
            }
        }
        
        return results
    }
}
