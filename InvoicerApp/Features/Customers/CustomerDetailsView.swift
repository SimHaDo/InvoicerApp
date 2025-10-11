//
//  CustomerDetailsView.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI

struct CustomerDetailsView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.colorScheme) private var scheme
    let customerID: UUID

    @State private var isEditing = false
    @State private var showDeleteAlert = false
    @State private var tempCustomer: Customer = Customer()

    private var bindingIndex: Int? {
        app.customers.firstIndex(where: { $0.id == customerID })
    }

    private var binding: Binding<Customer>? {
        if let idx = bindingIndex { return $app.customers[idx] }
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
            VStack(alignment: .leading, spacing: 24) {
                // Header Section
                headerSection(customer: customer)
                
                // Contact Information
                contactSection(customer: customer)
                
                // Address Information
                addressSection(customer: customer)
                
                // Payment Methods
                paymentMethodsSection(customer: customer)
                
                // Billing Details
                billingDetailsSection(customer: customer)
                
                // Invoices Section
                invoicesSection(customer: customer)
                
                // Danger Zone
                dangerZoneSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .onTapGesture {
            hideKeyboard()
        }
        .simultaneousGesture(
            DragGesture()
                .onChanged { _ in
                    hideKeyboard()
                }
        )
        .navigationTitle(customer.wrappedValue.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing { /* данные уже в биндингах — сохранять нечего */ }
                    isEditing.toggle()
                }
            }
        }
        .alert("Delete this customer?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { deleteCustomer() }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private func headerSection(customer: Binding<Customer>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            scheme == .dark ?
                            Color(red: 0.12, green: 0.12, blue: 0.16) :
                            Color.secondary.opacity(0.12)
                        )
                        .frame(width: 64, height: 64)
                        .overlay(
                            Circle()
                                .stroke(
                                    scheme == .dark ?
                                    Color.blue.opacity(0.3) :
                                    Color.secondary.opacity(0.2),
                                    lineWidth: 2
                                )
                        )
                    
                    Text(initials(customer.wrappedValue.name))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(
                            scheme == .dark ?
                            Color.blue :
                            .primary
                        )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    if isEditing {
                        ModernTextField(
                            title: "Full Name",
                            text: customer.name,
                            icon: "person"
                        )
                    } else {
                        Text(customer.wrappedValue.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    if isEditing {
                        Picker("Status", selection: customer.status) {
                            ForEach(CustomerStatus.allCases) { status in
                                Text(status.rawValue.capitalized).tag(status)
                            }
                        }
                        .pickerStyle(.segmented)
                    } else {
                        CustomerStatusChip(status: customer.wrappedValue.status)
                    }
                }
                
                Spacer()
            }
        }
        .modifier(CompanySetupCard())
    }
    
    private func contactSection(customer: Binding<Customer>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "envelope.circle")
                        .foregroundColor(.blue)
                        .font(.title3)
                    Text("Contact Information")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Text("Customer contact details")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                if isEditing {
                    ModernTextField(
                        title: "Email Address",
                        text: customer.email,
                        icon: "envelope"
                    )
                    
                    ModernTextField(
                        title: "Phone Number",
                        text: customer.phone,
                        icon: "phone"
                    )
                    
                    ModernTextField(
                        title: "Organization",
                        text: Binding(
                            get: { customer.wrappedValue.organization ?? "" },
                            set: { customer.wrappedValue.organization = $0.isEmpty ? nil : $0 }
                        ),
                        icon: "building.2"
                    )
                } else {
                    contactInfoRow(
                        icon: "envelope",
                        title: "Email",
                        value: customer.wrappedValue.email.isEmpty ? "—" : customer.wrappedValue.email
                    )
                    
                    contactInfoRow(
                        icon: "phone",
                        title: "Phone",
                        value: customer.wrappedValue.phone.isEmpty ? "—" : customer.wrappedValue.phone
                    )
                    
                    contactInfoRow(
                        icon: "building.2",
                        title: "Organization",
                        value: customer.wrappedValue.organization ?? "—"
                    )
                }
            }
        }
        .modifier(CompanySetupCard())
    }
    
    private func contactInfoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private func addressSection(customer: Binding<Customer>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.red)
                        .font(.title3)
                    Text("Address")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Text("Customer address information")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                if isEditing {
                    ModernTextField(
                        title: "Address Line 1",
                        text: customer.address.line1,
                        icon: "location"
                    )
                    
                    ModernTextField(
                        title: "Address Line 2",
                        text: customer.address.line2,
                        icon: "location"
                    )
                    
                    HStack(spacing: 12) {
                        ModernTextField(
                            title: "City",
                            text: customer.address.city,
                            icon: "building"
                        )
                        
                        ModernTextField(
                            title: "State",
                            text: customer.address.state,
                            icon: "building"
                        )
                    }
                    
                    HStack(spacing: 12) {
                        ModernTextField(
                            title: "ZIP Code",
                            text: customer.address.zip,
                            icon: "number"
                        )
                        
                        ModernTextField(
                            title: "Country",
                            text: customer.address.country,
                            icon: "globe"
                        )
                    }
                } else {
                    if !customer.wrappedValue.address.oneLine.isEmpty {
                        contactInfoRow(
                            icon: "location",
                            title: "Address",
                            value: customer.wrappedValue.address.oneLine
                        )
                    } else {
                        contactInfoRow(
                            icon: "location",
                            title: "Address",
                            value: "—"
                        )
                    }
                }
            }
        }
        .modifier(CompanySetupCard())
    }
    
    private func paymentMethodsSection(customer: Binding<Customer>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "creditcard.circle")
                        .foregroundColor(.orange)
                        .font(.title3)
                    Text("Payment Methods")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Text("Customer payment options")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if isEditing {
                PaymentMethodsEditor(methods: customer.paymentMethods)
            } else {
                if customer.wrappedValue.paymentMethods.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text("No payment methods")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Add payment methods for this customer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    VStack(spacing: 8) {
                        ForEach(customer.wrappedValue.paymentMethods) { method in
                            paymentMethodRow(method: method)
                        }
                    }
                }
            }
        }
        .modifier(CompanySetupCard())
    }
    
    private func paymentMethodRow(method: PaymentMethod) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon(for: method.type))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(method.type.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text(method.type.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private func billingDetailsSection(customer: Binding<Customer>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.green)
                        .font(.title3)
                    Text("Billing Details")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Text("Additional billing information")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                if isEditing {
                    ModernTextField(
                        title: "Billing Notes",
                        text: Binding(
                            get: { customer.wrappedValue.billingDetails ?? "" },
                            set: { customer.wrappedValue.billingDetails = $0.isEmpty ? nil : $0 }
                        ),
                        icon: "note.text"
                    )
                } else {
                    contactInfoRow(
                        icon: "note.text",
                        title: "Billing Notes",
                        value: customer.wrappedValue.billingDetails ?? "—"
                    )
                }
            }
        }
        .modifier(CompanySetupCard())
    }
    
    private func invoicesSection(customer: Binding<Customer>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "doc.text.circle")
                        .foregroundColor(.green)
                        .font(.title3)
                    Text("Invoices")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Text("Customer invoice history")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            
            if invoicesForCustomer.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No invoices yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("This customer has no invoices yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(invoicesForCustomer) { invoice in
                        NavigationLink {
                            InvoiceDetailsView(invoice: invoice)
                        } label: {
                            invoiceRow(invoice: invoice)
                        }
                    }
                }
            }
        }
        .modifier(CompanySetupCard())
    }
    
    private func invoiceRow(invoice: Invoice) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(invoice.number)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text("Issued \(Dates.display.string(from: invoice.issueDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(Money.fmt(invoice.subtotal, code: invoice.currency))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                        .font(.title3)
                    Text("Danger Zone")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Text("Irreversible actions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Customer")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.red)
                )
            }
        }
        .modifier(CompanySetupCard())
    }

    private func icon(for t: PaymentMethodType) -> String {
        switch t {
        case .bankIBAN: return "building.columns"
        case .bankUS:   return "banknote"
        case .paypal:   return "envelope"
        case .cardLink: return "link"
        case .crypto:   return "bitcoinsign.circle"
        case .other:    return "square.and.pencil"
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

    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
