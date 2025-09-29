//
//  RootTabView.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        TabView {
            InvoicesScreen()
                .tabItem { Image(systemName: "banknote"); Text("Invoices") }

            CustomersScreen()
                .tabItem { Image(systemName: "person.2"); Text("Customers") }

            ProductsScreen()
                .tabItem { Image(systemName: "shippingbox"); Text("Products") }

            AnalyticsScreen()
                .tabItem { Image(systemName: "chart.line.uptrend.xyaxis"); Text("Analytics") }

            SettingsTab() // NEW
                .tabItem { Image(systemName: "gearshape"); Text("Settings") }
        }
    }
}
