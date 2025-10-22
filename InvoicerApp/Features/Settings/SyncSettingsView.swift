//
//  SyncSettingsView.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/30/25.
//

import SwiftUI

struct SyncSettingsView: View {
    @StateObject private var coreDataAdapter = CoreDataAdapter.shared
    @EnvironmentObject private var appState: AppState
    
    @State private var showingSyncAlert = false
    @State private var syncAlertMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                // iCloud Status Section
                Section {
                    HStack {
                        Image(systemName: coreDataAdapter.isCloudKitAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(coreDataAdapter.isCloudKitAvailable ? .green : .red)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(coreDataAdapter.isCloudKitAvailable ? "iCloud Connected" : "iCloud Not Connected")
                                .font(.headline)
                            
                            if let error = coreDataAdapter.syncError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            } else {
                                Text("Your data will sync across all your devices")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("iCloud Status")
                }
                
                // Sync Status Section
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last Sync")
                                .font(.headline)
                            
                            if let lastSync = coreDataAdapter.lastSyncDate {
                                Text(lastSync, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Never synced")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Sync status indicator
                        Group {
                            if coreDataAdapter.isCloudKitAvailable {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Sync Status")
                }
                
                // Manual Sync Section
                Section {
                    Button(action: {
                        coreDataAdapter.forceSync()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Sync Now")
                        }
                    }
                    .disabled(!coreDataAdapter.isCloudKitAvailable)
                    
                    Button(action: {
                        appState.syncFromCloud()
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.circle")
                            Text("Pull from iCloud")
                        }
                    }
                    .disabled(!coreDataAdapter.isCloudKitAvailable)
                } header: {
                    Text("Manual Sync")
                } footer: {
                    Text("Sync your data manually or pull the latest changes from iCloud.")
                }
                
                // Data Overview Section
                Section {
                    DataOverviewRow(
                        title: "Company Info",
                        count: appState.company != nil ? 1 : 0,
                        icon: "building.2"
                    )
                    
                    DataOverviewRow(
                        title: "Customers",
                        count: appState.customers.count,
                        icon: "person.2"
                    )
                    
                    DataOverviewRow(
                        title: "Products",
                        count: appState.products.count,
                        icon: "cube.box"
                    )
                    
                    DataOverviewRow(
                        title: "Invoices",
                        count: appState.invoices.count,
                        icon: "doc.text"
                    )
                    
                    DataOverviewRow(
                        title: "Payment Methods",
                        count: appState.paymentMethods.count,
                        icon: "creditcard"
                    )
                } header: {
                    Text("Data Overview")
                } footer: {
                    Text("This data will be synced across all your devices signed in with the same Apple ID.")
                }
                
                // Troubleshooting Section
                Section {
                    Button("Troubleshoot Sync Issues") {
                        syncAlertMessage = """
                        If you're experiencing sync issues:
                        
                        1. Make sure you're signed in to iCloud
                        2. Check your internet connection
                        3. Try signing out and back into iCloud
                        4. Restart the app
                        
                        If problems persist, contact support.
                        """
                        showingSyncAlert = true
                    }
                    .foregroundColor(.blue)
                } header: {
                    Text("Troubleshooting")
                }
            }
            .navigationTitle("iCloud Sync")
            .navigationBarTitleDisplayMode(.large)
            .alert("Sync Troubleshooting", isPresented: $showingSyncAlert) {
                Button("OK") { }
            } message: {
                Text(syncAlertMessage)
            }
        }
    }
}

struct DataOverviewRow: View {
    let title: String
    let count: Int
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Text("\(count)")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    SyncSettingsView()
        .environmentObject(AppState())
}
