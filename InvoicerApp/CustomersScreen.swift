//
//  CustomersScreen.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI

// MARK: - ViewModel

final class CustomersVM: ObservableObject {
    @Published var query: String = ""

    func filtered(_ customers: [Customer]) -> [Customer] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return customers }
        return customers.filter {
            $0.name.lowercased().contains(q) || $0.email.lowercased().contains(q)
        }
    }
}

// MARK: - Screen

struct CustomersScreen: View {
    @EnvironmentObject private var app: AppState
    @StateObject private var vm = CustomersVM()

    @State private var showAddCustomer = false
    @State private var showEmptyPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {

                    // Header (единый стиль)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Customers").font(.largeTitle).bold()
                            Text("Manage your client relationships")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if app.isPremium { ProBadge() }
                    }

                    // Actions
                    HStack(spacing: 12) {
                        Button {
                            showAddCustomer = true
                        } label: {
                            Label("Add Customer", systemImage: "person.crop.circle.badge.plus")
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))

                        Button {
                            onCreateInvoice()
                        } label: {
                            Label("Create Invoice", systemImage: "doc.badge.plus")
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black))
                        .foregroundStyle(.white)
                    }

                    // Search
                    SearchBar(text: $vm.query)
                        .padding(.top, 2)

                    // Free plan banner (только для free)
                    if !app.isPremium {
                        FreePlanCardCompact(
                            remaining: app.remainingFreeInvoices,
                            onUpgrade: { showEmptyPaywall = true },
                            onCreate: onCreateInvoice
                        )
                    }

                    // List
                    if app.customers.isEmpty {
                        emptyList
                    } else {
                        VStack(spacing: 10) {
                            ForEach(vm.filtered(app.customers)) { c in
                                NavigationLink {
                                    // ВАЖНО: детали открываем по id, внутри вью найдёт Binding сам
                                    CustomerDetailsView(customerID: c.id)
                                } label: {
                                    CustomerRow(customer: c)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 6)
            }
            .sheet(isPresented: $showAddCustomer) {
                AddCustomerSheet { newCustomer in
                    app.customers.append(newCustomer)
                }
            }
            .sheet(isPresented: $showEmptyPaywall) { EmptyScreen() }
        }
    }

    // MARK: - Helpers

    private func onCreateInvoice() {
        // если бесплатный лимит исчерпан — показываем пэйволл-заглушку
        guard app.canCreateInvoice else {
            showEmptyPaywall = true
            return
        }
        // поведение по твоему ТЗ: пока тоже показываем заглушку (подключим позже реальный переход)
        showEmptyPaywall = true
    }

    private var emptyList: some View {
        VStack(spacing: 12) {
            Text("No customers yet").font(.headline)
            Text("Add a customer to start billing.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                showAddCustomer = true
            } label: {
                Text("Add Customer")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.black))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.15)))
        .padding(.top, 6)
    }
}

// MARK: - Row

private struct CustomerRow: View {
    @EnvironmentObject private var app: AppState
    let customer: Customer

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 44, height: 44)
                    .overlay(Text(initials(from: customer.name)).bold())

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(customer.name).font(.headline)
                        Spacer()
                        // Можно заменить на CustomerStatusChip(status: customer.status) если он у тебя уже есть
                        CustomerStatusChip(status: customer.status)
                    }

                    HStack(spacing: 14) {
                        if !customer.email.isEmpty {
                            Label(customer.email, systemImage: "envelope")
                        }
                        if !customer.phone.isEmpty {
                            Label(customer.phone, systemImage: "phone")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    HStack {
                        Text("\(invoicesCount) invoices")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(Money.fmt(totalSpent, code: Locale.current.currency?.identifier ?? "USD"))
                            .font(.subheadline).bold()
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.secondary.opacity(0.15))
            )
        }
    }

    // Вычисления по данным AppState
    private var invoicesCount: Int {
        app.invoices.filter { $0.customer.id == customer.id }.count
    }
    private var totalSpent: Decimal {
        app.invoices.filter { $0.customer.id == customer.id }
            .map(\.subtotal)
            .reduce(0, +)
    }
    private func initials(from name: String) -> String {
        name.split(separator: " ").compactMap { $0.first }.prefix(2).map(String.init).joined()
    }
}

// MARK: - AddCustomerSheet

struct AddCustomerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    var onSave: (Customer) -> Void

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email).textInputAutocapitalization(.never)
                    TextField("Phone", text: $phone).keyboardType(.phonePad)
                }
            }
            .navigationTitle("Add Customer")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(Customer(name: name, email: email, phone: phone))
                        dismiss()
                    }.disabled(!canSave)
                }
            }
        }
    }
}
