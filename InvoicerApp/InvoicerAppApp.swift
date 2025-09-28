//
//  InvoicerAppApp.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

// MARK: - InvoicerApp.swift
import SwiftUI

@main
struct InvoicerApp: App {
    @StateObject private var app = AppState()
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(app)
        }
    }
}
