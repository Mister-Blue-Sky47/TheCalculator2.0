import XCTest
@testable import TheCalculator2_0

final class CalculatorTests: XCTestCase {

    func testBase64AndHashes() {
        let encoded = BaseCalculator.encodeBase64("maKI")
        XCTAssertEqual(encoded, "bWFLSQ==")
        XCTAssertEqual(BaseCalculator.decodeBase64(encoded), "maKI")
        XCTAssertNil(BaseCalculator.decodeBase64("%%%ungültig%%%"))

        let sha256abc = BaseCalculator.hash("abc", algorithm: .sha256)
        XCTAssertTrue(sha256abc.hasPrefix("ba7816bf8f01cfea414140de5dae2223"))

        let md5abc = BaseCalculator.hash("abc", algorithm: .md5)
        XCTAssertEqual(md5abc, "900150983cd24fb0d6963f7d28e17f72")
    }

    func testNetworkDiagnosticMACAndPorts() {
        let raspi = NetworkDiagnosticCalculator.lookupMAC("70:81:05:AA:BB:CC")
        XCTAssertTrue(raspi.isValid)
        XCTAssertEqual(raspi.vendor, "Raspberry Pi Trading Ltd")

        let randomMAC = NetworkDiagnosticCalculator.lookupMAC("02:00:00:11:22:33")
        XCTAssertTrue(randomMAC.isValid)
        XCTAssertTrue(randomMAC.vendor.contains("Private / Zufällige MAC"))

        let invalidMAC = NetworkDiagnosticCalculator.lookupMAC("12:34")
        XCTAssertFalse(invalidMAC.isValid)

        XCTAssertTrue(NetworkDiagnosticCalculator.standardPorts.contains { $0.port == 443 && $0.name == "HTTPS" })
    }
}
func testBausteinAScientific() {
        XCTAssertEqual(ScientificCalculator.log2Value(8), 3.0)
        XCTAssertNil(ScientificCalculator.log2Value(0))
        XCTAssertEqual(ScientificCalculator.expValue(0), 1.0)
        XCTAssertEqual(ScientificCalculator.deltaPercent(from: 100, to: 125), 25.0)
        XCTAssertNil(ScientificCalculator.deltaPercent(from: 0, to: 50))
    }
func testBausteinCRPNAndStats() {
        var s = RPNStatsCalculator.push(10, onto: [])
        s = RPNStatsCalculator.push(5, onto: s)
        let diff = RPNStatsCalculator.applyBinary("-", on: s)
        XCTAssertNil(diff.error)
        XCTAssertEqual(diff.stack.first, 5.0)

        let swapped = RPNStatsCalculator.swapTopTwo(in: [1, 2, 3])
        XCTAssertEqual(swapped, [2, 1, 3])

        let summary = RPNStatsCalculator.summarize(samples: [2, 4, 6])
        XCTAssertEqual(summary?.mean, 4.0)
        XCTAssertEqual(summary?.sum, 12.0)
    }
