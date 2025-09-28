//
//  CustomersScreen.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI

// ============ Customers Tab ============

final class CustomersVM: ObservableObject {
    @Published var query = ""

    func filtered(_ customers: [Customer]) -> [Customer] {
        let q = query.lowercased()
        guard !q.isEmpty else { return customers }
        return customers.filter {
            $0.name.lowercased().contains(q)
            || $0.email.lowercased().contains(q)
            || ($0.organization ?? "").lowercased().contains(q)
        }
    }

    func summary(for customer: Customer, invoices: [Invoice]) -> (total: Decimal, count: Int) {
        let list = invoices.filter { $0.customer.id == customer.id }
        let total = list.map { $0.subtotal }.reduce(0, +)
        return (total, list.count)
    }
}

struct CustomersScreen: View {
    @EnvironmentObject private var app: AppState
    @StateObject private var vm = CustomersVM()

    @State private var showAdd = false
    @State private var showCompanySetup = false
    @State private var showTemplatePicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Header left texts + actions
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Customers").font(.largeTitle).bold()
                        Text("Manage your client relationships")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }

                    HStack(spacing: 10) {
                        Button {
                            showAdd = true
                        } label: {
                            Label("Add Customer", systemImage: "person.crop.circle.badge.plus")
                                .bold().padding(.horizontal, 14).padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
                        }

                        Button {
                            onCreateInvoice()
                        } label: {
                            Label("Create Invoice", systemImage: "doc.badge.plus")
                                .bold().padding(.horizontal, 14).padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.black))
                                .foregroundStyle(.white)
                        }
                    }

                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                        TextField("Search customers…", text: $vm.query)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))

                    // Free Plan callout (как на скрине)
                    FreePlanCustomersCard()

                    // List
                    VStack(spacing: 12) {
                        ForEach(vm.filtered(app.customers)) { c in
                            NavigationLink {
                                CustomerDetailsView(customerID: c.id)
                            } label: {
                                CustomerRow(customer: c,
                                            summary: vm.summary(for: c, invoices: app.invoices))
                            }
                        }
                    }
                }
                .padding()
            }
            .sheet(isPresented: $showAdd) { AddCustomerView() }
            .sheet(isPresented: $showCompanySetup) {
                CompanySetupView {
                    showCompanySetup = false
                    showTemplatePicker = true
                }
            }
            .sheet(isPresented: $showTemplatePicker) {
                TemplatePickerView()
            }
        }
    }

    private func onCreateInvoice() {
        if app.company == nil { showCompanySetup = true }
        else { showTemplatePicker = true }
    }
}

// Premium upsell card (customers tab flavor)
struct FreePlanCustomersCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "crown.fill").foregroundStyle(.yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Free Plan").bold()
                    Text("Invoice limit reached").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            Button("Upgrade to Create More") { }
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(
                    LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                ))
                .foregroundStyle(.white)

            Button("Create Invoice (Limit Reached)") { }
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.06)))
                .foregroundStyle(.secondary)

            HStack(spacing: 24) {
                Label("Unlimited invoices", systemImage: "checkmark")
                Label("Premium templates", systemImage: "checkmark")
                Label("Advanced features", systemImage: "checkmark")
            }.font(.caption).foregroundStyle(.secondary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).stroke(Color.yellow.opacity(0.4)))
    }
}

struct CustomerRow: View {
    let customer: Customer
    let summary: (total: Decimal, count: Int)

    var initials: String {
        customer.name.split(separator: " ").compactMap { $0.first }.prefix(2).map(String.init).joined()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16).fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.15)))

            HStack(alignment: .center, spacing: 12) {
                Circle().fill(Color.secondary.opacity(0.12)).frame(width: 44, height: 44)
                    .overlay(Text(initials).bold())
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(customer.name).bold()
                        CustomerStatusChip(status: customer.status)
                    }
                    HStack(spacing: 12) {
                        if !customer.email.isEmpty {
                            Label(customer.email, systemImage: "envelope").font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if !customer.phone.isEmpty {
                            Label(customer.phone, systemImage: "phone").font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let org = customer.organization, !org.isEmpty {
                        Text(org).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Money.fmt(summary.total, code: Locale.current.currency?.identifier ?? "USD"))
                        .bold()
                    HStack(spacing: 4) {
                        Text("\(summary.count)").font(.caption).foregroundStyle(.secondary)
                        Text("invoices").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding(16)
        }
    }
}

struct CustomerStatusChip: View {
    let status: CustomerStatus
    var body: some View {
        Text(status.rawValue)
            .font(.caption2).bold()
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(
                Capsule().fill(status == .active ? Color.black : Color.secondary.opacity(0.15))
            )
            .foregroundStyle(status == .active ? .white : .primary)
    }
}
