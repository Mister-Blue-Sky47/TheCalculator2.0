//
//  TheCalculator2_0App.swift
//  TheCalculator2.0
//
//  Created by Steffen Beier on 28.10.26.
//

import SwiftUI

@main
struct TheCalculator2_0App: App {
    @StateObject private var volleyballStore = VolleyballTournamentStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(volleyballStore)
        }
    }
}
