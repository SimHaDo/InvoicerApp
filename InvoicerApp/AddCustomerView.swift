//
//  AddCustomerView.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI

struct AddCustomerView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var customer = Customer()

    var canSave: Bool { !customer.name.trimmingCharacters(in: .whitespaces).isEmpty && !customer.email.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic") {
                    TextField("Full name", text: $customer.name)
                    TextField("Email", text: $customer.email).keyboardType(.emailAddress)
                    TextField("Phone", text: $customer.phone)
                    Picker("Status", selection: $customer.status) {
                        ForEach(CustomerStatus.allCases) { Text($0.rawValue).tag($0) }
                    }
                }
                Section("Organization") {
                    TextField("Organization", text: Binding(
                        get: { customer.organization ?? "" },
                        set: { customer.organization = $0.isEmpty ? nil : $0 }
                    ))
                }
                Section("Address") {
                    TextField("Address line", text: $customer.address.line1)
                    TextField("City", text: $customer.address.city)
                    TextField("State", text: $customer.address.state)
                    TextField("ZIP", text: $customer.address.zip)
                    TextField("Country", text: $customer.address.country)
                }
            }
            .navigationTitle("Add Customer")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        app.customers.append(customer)
                        dismiss()
                    }.disabled(!canSave)
                }
            }
        }
    }
}
