//
//  SubnetView.swift
//  TheCalculator2.0
//
//  Created by Steffen Beier on 16.11.26.
//

import SwiftUI
import VisionKit
import Vision

struct SubnetView: View {
    @State private var selectedTab: Int = 0
    
    // Standard Subnet-Rechner States
    @State private var ipInput: String = "192.168.1.0"
    @State private var cidrInput: Int = 24
    @State private var showScanner: Bool = false
    
    // VLSM-Rechner States
    @State private var vlsmBaseIP: String = "192.168.10.0"
    @State private var vlsmBaseCIDR: Int = 24
    @State private var newSubnetName: String = ""
    @State private var newSubnetHosts: String = ""
    @State private var requirements: [(name: String, hosts: Int)] = [
        ("Verwaltung", 50),
        ("Schulung", 20),
        ("Server", 5),
        ("PtP-Link", 2)
    ]
    
    var computedResult: SubnetResult? {
        SubnetCalculator.calculateSubnet(ipStr: ipInput, cidr: cidrInput)
    }
    
    var vlsmResults: [SubnetResult] {
        let cleanIP = vlsmBaseIP.trimmingCharacters(in: .whitespacesAndNewlines)
        return SubnetCalculator.calculateVLSM(baseIP: cleanIP, baseCIDR: vlsmBaseCIDR, requirements: requirements)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            
            // Modus Umschaltung: Einzel-Subnetz vs. VLSM-Planer
            Picker("Subnetz Modus", selection: $selectedTab) {
                Text("Standard Subnetz").tag(0)
                Text("VLSM Planer").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            if selectedTab == 0 {
                standardSubnetView
            } else {
                vlsmPlannerView
            }
        }
        .sheet(isPresented: $showScanner) {
            IPDocumentScannerView { scannedText in
                let extractedIP = extractIPAddress(from: scannedText)
                if !extractedIP.isEmpty {
                    ipInput = extractedIP
                }
            }
        }
    }
    
    // MARK: - Standard Subnetz Ansicht
    private var standardSubnetView: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("IPv4 Subnetz-Berechnung")
                            .font(.headline)
                        Spacer()
                        Button(action: { showScanner = true }) {
                            Label("IP Scannen", systemImage: "camera.viewfinder")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue.opacity(0.15))
                        .foregroundColor(.blue)
                    }
                     
                    HStack {
                        TextField("IP-Adresse", text: $ipInput)
                            .keyboardType(.numbersAndPunctuation)
                            .textFieldStyle(.roundedBorder)
                        
                        Picker("/", selection: $cidrInput) {
                            ForEach(8...30, id: \.self) { prefix in
                                Text("/\(prefix)").tag(prefix)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                 
                if let res = computedResult {
                    VStack(spacing: 10) {
                        ResultRow(label: "Netz-ID:", value: "\(res.networkAddress)/\(res.cidr)")
                        ResultRow(label: "Subnetzmaske:", value: res.netmask)
                        ResultRow(label: "Wildcard-Maske:", value: res.wildcard)
                        ResultRow(label: "Broadcast:", value: res.broadcastAddress)
                        ResultRow(label: "Host-Bereich:", value: "\(res.firstHost) – \(res.lastHost)")
                        ResultRow(label: "Nutzbare Hosts:", value: "\(res.usableHosts)")
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                } else {
                    Text("Ungültige IP-Adresse")
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - VLSM Planer Ansicht
    private var vlsmPlannerView: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("VLSM Basis-Netzwerk")
                        .font(.headline)
                    
                    HStack {
                        TextField("Basis-IP (z.B. 192.168.10.0)", text: $vlsmBaseIP)
                            .keyboardType(.numbersAndPunctuation)
                            .textFieldStyle(.roundedBorder)
                        
                        Picker("/", selection: $vlsmBaseCIDR) {
                            ForEach(16...28, id: \.self) { prefix in
                                Text("/\(prefix)").tag(prefix)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                 
                VStack(alignment: .leading, spacing: 8) {
                    Text("Neues Subnetz anfordern")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        TextField("Netz-Name (z.B. BAR)", text: $newSubnetName)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Hosts", text: $newSubnetHosts)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        
                        Button(action: addRequirement) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                 
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Erzeugte VLSM-Aufteilung")
                            .font(.headline)
                        Spacer()
                        if !requirements.isEmpty {
                            Button("Zurücksetzen") {
                                requirements.removeAll()
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }
                    
                    if vlsmResults.isEmpty {
                        Text("Keine Berechnung möglich. Bitte gültige Basis-IP eingeben.")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        ForEach(vlsmResults) { res in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(res.name)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Text("\(res.networkAddress)/\(res.cidr)")
                                        .font(.system(.body, design: .monospaced))
                                        .fontWeight(.bold)
                                }
                                
                                HStack {
                                    Text("Bereich: \(res.firstHost) – \(res.lastHost)")
                                        .font(.caption)
                                        .monospaced()
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("\(res.usableHosts) Hosts")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding(10)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
    
    private func addRequirement() {
        guard !newSubnetName.isEmpty, let hosts = Int(newSubnetHosts), hosts > 0 else { return }
        requirements.append((name: newSubnetName, hosts: hosts))
        newSubnetName = ""
        newSubnetHosts = ""
    }
    
    private func extractIPAddress(from text: String) -> String {
        let pattern = #"\b(?:\d{1,3}\.){3}\d{1,3}\b"#
        if let range = text.range(of: pattern, options: .regularExpression) {
            return String(text[range])
        }
        return ""
    }
}

// Hilfs-Controller für Live-Dokumenten-Scannen / OCR via VisionKit
struct IPDocumentScannerView: UIViewControllerRepresentable {
    var completion: (String) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var parent: IPDocumentScannerView
        
        init(_ parent: IPDocumentScannerView) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var fullText = ""
            let queue = DispatchQueue(label: "com.calculatormaki.ocr", qos: .userInitiated)
            
            queue.async {
                for i in 0..<scan.pageCount {
                    let image = scan.imageOfPage(at: i)
                    if let cgImage = image.cgImage {
                        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                        
                        // Jede Seite bekommt nun eine frische Request-Instanz, um den Crash zu verhindern
                        let request = VNRecognizeTextRequest { request, _ in
                            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                            for observation in observations {
                                if let bestCandidate = observation.topCandidates(1).first {
                                    fullText += bestCandidate.string + "\n"
                                }
                            }
                        }
                        request.recognitionLevel = .accurate
                        
                        try? requestHandler.perform([request])
                    }
                }
                
                DispatchQueue.main.async {
                    self.parent.completion(fullText)
                    self.parent.presentationMode.wrappedValue.dismiss()
                }
            }
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ResultRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.bold)
        }
    }
}
