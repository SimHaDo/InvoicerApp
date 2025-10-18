//
//  CustomersScreen.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI

// MARK: - FloatingElement

private struct FloatingElement: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var opacity: Double
    var scale: Double
    var rotation: Double
}

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
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var vm = CustomersVM()
    @Environment(\.colorScheme) private var scheme

    @State private var showAddCustomer = false
    @State private var showInvoiceCreation = false
    @State private var showEmptyPaywall = false
    @State private var showContent = false
    @State private var pulseAnimation = false
    @State private var shimmerOffset: CGFloat = -1
    @State private var floatingElements: [FloatingElement] = []

    var body: some View {
        NavigationStack {
            ZStack {
                // Анимированный фон
                backgroundView
                
                // Плавающие элементы
                ForEach(floatingElements) { element in
                    Circle()
                        .fill(Color.primary.opacity(0.05))
                        .frame(width: 40, height: 40)
                        .scaleEffect(element.scale)
                        .opacity(element.opacity)
                        .rotationEffect(.degrees(element.rotation))
                        .position(x: element.x, y: element.y)
                        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: element.scale)
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: UI.largeSpacing) {

                        // Header с анимациями
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Customers")
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundColor(.primary)
                                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                                    .offset(y: showContent ? 0 : -20)
                                    .opacity(showContent ? 1 : 0)
                                    .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1), value: showContent)
                                
                                Text("Manage your client relationships")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .offset(y: showContent ? 0 : -15)
                                    .opacity(showContent ? 1 : 0)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)
                            }
                            Spacer()
                        }

                        // Actions с анимациями
                        HStack(spacing: 16) {
                            Button { showAddCustomer = true } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Add Customer")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(scheme == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .foregroundColor(.primary)
                            }
                            .scaleEffect(showContent ? 1.0 : 0.9)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)

                            Button { onCreateInvoice() } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "doc.badge.plus")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Create Invoice")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.primary)
                                        .shadow(color: Color.black.opacity(0.2), radius: 12, y: 6)
                                )
                                .foregroundColor(scheme == .light ? .white : .black)
                            }
                            .scaleEffect(showContent ? 1.0 : 0.9)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: showContent)
                        }

                        // Search с анимацией
                        SearchBar(text: $vm.query)
                            .padding(.top, 4)
                            .offset(y: showContent ? 0 : 20)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: showContent)

                        // List с анимациями
                        if app.customers.isEmpty {
                            emptyList
                        } else {
                            VStack(spacing: 12) {
                                ForEach(Array(vm.filtered(app.customers).enumerated()), id: \.element.id) { index, c in
                                    NavigationLink {
                                        CustomerDetailsView(customerID: c.id)
                                    } label: {
                                        CustomerRow(customer: c)
                                    }
                                    .scaleEffect(showContent ? 1.0 : 0.9)
                                    .opacity(showContent ? 1 : 0)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6 + Double(index) * 0.1), value: showContent)
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .adaptiveContent()
                    .padding(.top, 16)
                }
            }
            .sheet(isPresented: $showAddCustomer) {
                AddCustomerSheet { newCustomer in
                    app.customers.append(newCustomer)
                }
            }
            .fullScreenCover(isPresented: $showInvoiceCreation) {
                InvoiceCreationFlow(onClose: {
                    showInvoiceCreation = false
                })
                .environmentObject(app)
            }
            .sheet(isPresented: $showEmptyPaywall) {
                PaywallScreen(onClose: { showEmptyPaywall = false })
                    .environmentObject(subscriptionManager)
            }
        }
        .onAppear {
            showContent = true
            pulseAnimation = true
            startShimmerAnimation()
            createFloatingElements()
        }
    }

    // MARK: - Background View
    
    private var backgroundView: some View {
        Group {
            if scheme == .light {
                ZStack {
                    // Основной градиент
                    LinearGradient(
                        colors: [Color.white, Color(white: 0.97), Color(white: 0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Радиальный градиент с анимацией
                    RadialGradient(
                        colors: [Color.white, Color(white: 0.96), .clear],
                        center: .topLeading,
                        startRadius: 24,
                        endRadius: 520
                    )
                    .blendMode(.screen)
                    
                    // Анимированный shimmer эффект
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: shimmerOffset * 400)
                    .blendMode(.overlay)
                    
                    // Плавающие световые пятна
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.primary.opacity(0.05))
                            .frame(width: 200, height: 200)
                            .position(
                                x: CGFloat(100 + i * 150),
                                y: CGFloat(200 + i * 100)
                            )
                            .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                            .opacity(pulseAnimation ? 0.6 : 0.3)
                            .animation(
                                .easeInOut(duration: 3.0 + Double(i) * 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.3),
                                value: pulseAnimation
                            )
                    }
                }
            } else {
                ZStack {
                    // Основной градиент для темной темы
                    LinearGradient(
                        colors: [Color.black, Color.black.opacity(0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Радиальный градиент
                    RadialGradient(
                        colors: [Color.white.opacity(0.08), .clear],
                        center: .topLeading,
                        startRadius: 24,
                        endRadius: 520
                    )
                    .blendMode(.screen)
                    
                    // Анимированный shimmer эффект для темной темы
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.1), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: shimmerOffset * 400)
                    .blendMode(.overlay)
                    
                    // Плавающие световые пятна для темной темы
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.primary.opacity(0.08))
                            .frame(width: 240, height: 240)
                            .position(
                                x: CGFloat(120 + i * 180),
                                y: CGFloat(180 + i * 120)
                            )
                            .scaleEffect(pulseAnimation ? 1.3 : 0.7)
                            .opacity(pulseAnimation ? 0.8 : 0.4)
                            .animation(
                                .easeInOut(duration: 4.0 + Double(i) * 0.7)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.4),
                                value: pulseAnimation
                            )
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Animation Functions
    
    private func startShimmerAnimation() {
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            shimmerOffset = 1
        }
    }
    
    private func createFloatingElements() {
        floatingElements = (0..<5).map { _ in
            FloatingElement(
                x: Double.random(in: 50...350),
                y: Double.random(in: 100...600),
                opacity: Double.random(in: 0.3...0.7),
                scale: Double.random(in: 0.8...1.2),
                rotation: Double.random(in: 0...360)
            )
        }
    }

    // MARK: - Helpers

    private func onCreateInvoice() {
        // если лимит исчерпан и нет подписки — показываем paywall
        guard app.canCreateInvoice else {
            showEmptyPaywall = true
            return
        }
        // Открываем полноэкранный флоу создания инвойса
        showInvoiceCreation = true
    }

    private var emptyList: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary)
                .scaleEffect(showContent ? 1.0 : 0.8)
                .opacity(showContent ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: showContent)
            
            VStack(spacing: 8) {
                Text("No customers yet")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Add a customer to start billing.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .offset(y: showContent ? 0 : 20)
            .opacity(showContent ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.7), value: showContent)
            
            Button {
                showAddCustomer = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Add Customer")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.primary)
                        .shadow(color: Color.black.opacity(0.2), radius: 12, y: 6)
                )
                .foregroundColor(scheme == .light ? .white : .black)
            }
            .scaleEffect(showContent ? 1.0 : 0.9)
            .opacity(showContent ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: showContent)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.top, 8)
    }
}

// MARK: - Row (как было)

private struct CustomerRow: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.colorScheme) private var scheme
    let customer: Customer

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Аватар с анимацией - центрирован по высоте
            ZStack {
                Circle()
                    .fill(scheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Text(initials(from: customer.name))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }

            // Основная информация
            VStack(alignment: .leading, spacing: 10) {
                // Имя и статус
                HStack(alignment: .top) {
                    Text(customer.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Spacer()
                    
                    CustomerStatusChip(status: customer.status)
                }

                // Контактная информация
                VStack(alignment: .leading, spacing: 6) {
                    if !customer.email.isEmpty { 
                        HStack(spacing: 8) {
                            Image(systemName: "envelope")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(width: 16)
                            
                            Text(customer.email)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    
                    if !customer.phone.isEmpty { 
                        HStack(spacing: 8) {
                            Image(systemName: "phone")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(width: 16)
                            
                            Text(customer.phone)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }

                // Статистика
                HStack {
                    Text("\(invoicesCount) invoices")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(Money.fmt(totalSpent, code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(scheme == .light ? 0.05 : 0.2), radius: 8, y: 4)
        )
    }

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

// MARK: - AddCustomerSheet (без изменений с методами оплаты)

// MARK: - AddCustomerSheet



struct AddCustomerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var organization = ""
    @State private var status: CustomerStatus = .active
    @State private var addressLine1 = ""
    @State private var addressLine2 = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    @State private var country = ""
    @State private var billingDetails = ""
    @State private var methods: [PaymentMethod] = []

    var onSave: (Customer) -> Void

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && email.contains("@")
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundView
                contentView
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
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
        }
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                basicInfoSection
                organizationSection
                addressSection
                billingSection
                paymentMethodsSection
                saveButton
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .foregroundColor(.blue)
                        .font(.title2)
                    Text("Add Customer")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Text("Add a new customer to your database")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .modifier(CompanySetupCard())
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.title3)
                    Text("Basic Information")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Text("Essential contact details")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 16) {
                ModernTextField(
                    title: "Full Name",
                    text: $name,
                    icon: "person"
                )

                ModernTextField(
                    title: "Email Address",
                    text: $email,
                    icon: "envelope"
                )

                ModernTextField(
                    title: "Phone Number",
                    text: $phone,
                    icon: "phone"
                )
            }
        }
        .modifier(CompanySetupCard())
    }
    
    private var organizationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "building.2")
                        .foregroundColor(.purple)
                        .font(.title3)
                    Text("Organization")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Text("Company or organization details")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 16) {
                ModernTextField(
                    title: "Organization Name",
                    text: $organization,
                    icon: "building.2"
                )
                
                HStack {
                    Text("Status")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Picker("Status", selection: $status) {
                        ForEach(CustomerStatus.allCases) { status in
                            Text(status.rawValue.capitalized).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
            }
        }
        .modifier(CompanySetupCard())
    }
    
    private var addressSection: some View {
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

            VStack(spacing: 16) {
                ModernTextField(
                    title: "Address Line 1",
                    text: $addressLine1,
                    icon: "location"
                )
                
                ModernTextField(
                    title: "Address Line 2",
                    text: $addressLine2,
                    icon: "location"
                )
                
                HStack(spacing: 12) {
                    ModernTextField(
                        title: "City",
                        text: $city,
                        icon: "building"
                    )
                    
                    ModernTextField(
                        title: "State",
                        text: $state,
                        icon: "building"
                    )
                }
                
                HStack(spacing: 12) {
                    ModernTextField(
                        title: "ZIP Code",
                        text: $zip,
                        icon: "number"
                    )
                    
                    ModernTextField(
                        title: "Country",
                        text: $country,
                        icon: "globe"
                    )
                }
            }
        }
        .modifier(CompanySetupCard())
    }
    
    private var billingSection: some View {
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
                Text("Additional billing information (optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 16) {
                ModernTextField(
                    title: "Billing Notes",
                    text: $billingDetails,
                    icon: "note.text"
                )
            }
        }
        .modifier(CompanySetupCard())
    }
    
    private var paymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "creditcard")
                        .foregroundColor(.orange)
                        .font(.title3)
                    Text("Payment Methods")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Text("Add payment methods for this customer")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            PaymentMethodsEditor(methods: $methods)
        }
        .modifier(CompanySetupCard())
    }
    
    private var saveButton: some View {
        Button(action: save) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Save Customer")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(saveButtonBackground)
        }
        .disabled(!canSave)
        .padding(.bottom, 32)
    }
    
    private var saveButtonBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                canSave ?
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [.gray, .gray],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
    
    private var backgroundView: some View {
        Group {
            if scheme == .light {
                ZStack {
                    // Основной градиент
                    LinearGradient(
                        colors: [Color.white, Color(white: 0.97), Color(white: 0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Радиальный градиент
                    RadialGradient(
                        colors: [Color.white, Color(white: 0.96), .clear],
                        center: .topLeading,
                        startRadius: 24,
                        endRadius: 520
                    )
                    .blendMode(.screen)
                }
            } else {
                ZStack {
                    // Основной градиент для темной темы
                    LinearGradient(
                        colors: [Color.black, Color.black.opacity(0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Радиальный градиент
                    RadialGradient(
                        colors: [Color.white.opacity(0.08), .clear],
                        center: .topLeading,
                        startRadius: 24,
                        endRadius: 520
                    )
                    .blendMode(.screen)
                }
            }
        }
        .ignoresSafeArea()
    }

    private func save() {
        var c = Customer(name: name, email: email, phone: phone)
        c.organization = organization.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : organization
        c.status = status
        c.address.line1 = addressLine1
        c.address.line2 = addressLine2
        c.address.city = city
        c.address.state = state
        c.address.zip = zip
        c.address.country = country
        c.billingDetails = billingDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : billingDetails
        c.paymentMethods = methods
        onSave(c)
        dismiss()
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
