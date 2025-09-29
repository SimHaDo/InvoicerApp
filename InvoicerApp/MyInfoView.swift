//
//  MyInfoView.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/29/25.
//

// MyInfoView.swift
import SwiftUI

struct MyInfoView: View {
    @EnvironmentObject private var app: AppState
    @State private var showAddEdit = false
    @State private var editing: PaymentMethod? = nil

    var body: some View {
        List {
            Section("Payment Methods") {
                if app.settings.paymentMethods.isEmpty {
                    Text("No payment methods yet").foregroundStyle(.secondary)
                } else {
                    ForEach(app.settings.paymentMethods) { m in
                        Button { editing = m } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(m.type.title).bold()
                                Text(m.type.subtitle).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { idx in
                        app.settings.paymentMethods.remove(atOffsets: idx)
                        app.saveSettings()
                    }
                }

                Button { showAddEdit = true } label: { Label("Add Method", systemImage: "plus") }
            }

            Section("Additional notes") {
                TextField(
                    "Notes shown on invoice (optional)",
                    text: Binding(
                        get: { app.settings.additionalNotes ?? "" },
                        set: { newVal in
                            app.settings.additionalNotes = newVal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newVal
                            app.saveSettings()
                        }
                    ),
                    axis: .vertical
                )
            }
        }
        .navigationTitle("My Info")
        .sheet(isPresented: $showAddEdit) {
            AddEditPaymentMethodSheet { new in
                app.settings.paymentMethods.append(new)
                app.saveSettings()
            }
        }
        .sheet(item: $editing) { m in
            AddEditPaymentMethodSheet(initial: m) { updated in
                if let i = app.settings.paymentMethods.firstIndex(where: { $0.id == m.id }) {
                    app.settings.paymentMethods[i] = updated
                    app.saveSettings()
                }
            }
        }
    }
}
