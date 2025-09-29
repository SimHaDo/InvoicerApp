//
//  CustomerDetailsView.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI

// ============ Customer Details ============

struct CustomerDetailsView: View {
    @EnvironmentObject private var app: AppState
    let customerID: UUID

    @State private var isEditing = false
    @State private var showDeleteAlert = false
    @State private var showTemplatePicker = false
    @State private var tempCustomer: Customer = Customer()

    private var bindingIndex: Int? {
        app.customers.firstIndex(where: { $0.id == customerID })
    }

    private var binding: Binding<Customer>? {
        if let idx = bindingIndex {
            return $app.customers[idx]
        }
        return nil
    }

    private var invoicesForCustomer: [Invoice] {
        guard let c = binding?.wrappedValue else { return [] }
        return app.invoices.filter { $0.customer.id == c.id }
    }

    var body: some View {
        Group {
            if let binding = binding {
                content(customer: binding)
            } else {
                Text("Customer not found").foregroundStyle(.secondary)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(customer: Binding<Customer>) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Header
                HStack {
                    Circle().fill(Color.secondary.opacity(0.12)).frame(width: 56, height: 56)
                        .overlay(Text(initials(customer.wrappedValue.name)).bold())
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Full name", text: isEditing ? customer.name : .constant(customer.wrappedValue.name))
                            .disabled(!isEditing)
                            .font(.title3).bold()
                        if isEditing {
                            Picker("Status", selection: customer.status) {
                                ForEach(CustomerStatus.allCases) { Text($0.rawValue).tag($0) }
                            }.pickerStyle(.segmented).labelsHidden()
                        } else {
                            CustomerStatusChip(status: customer.wrappedValue.status)
                        }
                    }
                    Spacer()
                }

                // Contact card
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "envelope")
                        if isEditing {
                            TextField("email@example.com", text: customer.email)
                        } else {
                            Text(customer.wrappedValue.email.isEmpty ? "—" : customer.wrappedValue.email)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.06)))

                    HStack {
                        Image(systemName: "phone")
                        if isEditing {
                            TextField("+1 (555) 123-4567", text: customer.phone)
                        } else {
                            Text(customer.wrappedValue.phone.isEmpty ? "—" : customer.wrappedValue.phone)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.06)))

                    HStack {
                        Image(systemName: "building.2")
                        if isEditing {
                            TextField("Organization", text: Binding(
                                get: { customer.wrappedValue.organization ?? "" },
                                set: { customer.wrappedValue.organization = $0.isEmpty ? nil : $0 }
                            ))
                        } else {
                            Text(customer.wrappedValue.organization ?? "—")
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.06)))

                    HStack(alignment: .top) {
                        Image(systemName: "mappin.and.ellipse")
                        if isEditing {
                            TextField("Address line", text: customer.address.line1, axis: .vertical)
                        } else {
                            Text(customer.wrappedValue.address.oneLine.isEmpty ? "—" : customer.wrappedValue.address.oneLine)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.06)))
                }

                // Invoices section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Invoices").font(.headline)
                        Spacer()
                        Button {
                            createInvoiceFor(customer: customer.wrappedValue)
                        } label: {
                            Label("Create Invoice", systemImage: "doc.badge.plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    if invoicesForCustomer.isEmpty {
                        Text("No invoices yet").foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(invoicesForCustomer) { inv in
                            NavigationLink { InvoiceDetailsView(invoice: inv) } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.15))
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(inv.number).bold()
                                            Text("Issued \(Dates.display.string(from: inv.issueDate))")
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(Money.fmt(inv.subtotal, code: inv.currency)).bold()
                                        Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                                    }
                                    .padding(12)
                                }
                            }
                        }
                    }
                }

                // Danger zone
                VStack(alignment: .leading, spacing: 8) {
                    Text("Danger Zone").font(.headline)
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: { Text("Delete Customer").frame(maxWidth: .infinity) }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .navigationTitle(customer.wrappedValue.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing { /* данные уже в биндингах — ничего не делаем */ }
                    isEditing.toggle()
                }
            }
        }
        .alert("Delete this customer?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { deleteCustomer() }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showTemplatePicker) {
            TemplatePickerView()
        }
    }

    private func initials(_ name: String) -> String {
        name.split(separator: " ").compactMap { $0.first }.prefix(2).map(String.init).joined()
    }

    private func deleteCustomer() {
        if let idx = app.customers.firstIndex(where: { $0.id == customerID }) {
            app.customers.remove(at: idx)
        }
    }

    private func createInvoiceFor(customer: Customer) {
        app.preselectedCustomer = customer
        showTemplatePicker = true
    }
}
// MARK: - Customer Status Chip

struct CustomerStatusChip: View {
    let status: CustomerStatus

    private var title: String {
        switch status {
        case .active: return "active"
        case .inactive: return "inactive"
        }
    }

    private var tint: Color {
        switch status {
        case .active: return .green
        case .inactive: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tint)
                .frame(width: 6, height: 6)
            Text(title).bold()
        }
        .font(.caption2)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(tint.opacity(0.12)))
        .foregroundStyle(tint)
    }
}
