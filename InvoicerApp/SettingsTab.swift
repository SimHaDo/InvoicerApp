//
//  SettingsTab.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/29/25.
//


import SwiftUI

struct SettingsTab: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        MyInfoView()
                    } label: {
                        Label("My Info", systemImage: "person.crop.circle")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
