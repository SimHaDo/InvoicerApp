//
//  InvoiceWizardVM.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//
import SwiftUI
import UIKit

// MARK: - ViewModel

final class InvoiceWizardVM: ObservableObject {
    @Published var step: Int = 1
    @Published var number: String = "INV-" + String(Int.random(in: 100000...999999))
    @Published var status: Invoice.Status = .draft
    @Published var issueDate: Date = .init()
    @Published var dueDate: Date = Calendar.current.date(byAdding: .day, value: 14, to: .init()) ?? .init()
    @Published var customer: Customer? = nil
    @Published var items: [LineItem] = []
    @Published var currency: String = Locale.current.currency?.identifier ?? "USD"

    // Payment step state
    enum PaymentChoice: String, CaseIterable, Identifiable { case saved, custom, none
        var id: String { rawValue }
        var title: String {
            switch self {
            case .saved:  return "Saved methods"
            case .custom: return "Custom for this invoice"
            case .none:   return "Do not include"
            }
        }
    }
    @Published var paymentChoice: PaymentChoice = .saved
    @Published var selectedSaved: Set<UUID> = []              // selected from app.paymentMethods
    @Published var customMethods: [PaymentMethod] = []        // custom for this invoice
    @Published var paymentNotes: String = ""                  // additional notes (on invoice)
    @Published var includeLogo: Bool = true                   // include logo in invoice

    // Tax and Discount state
    @Published var taxRate: Decimal = 0
    @Published var taxType: TaxType = .percentage
    @Published var discountValue: Decimal = 0
    @Published var discountType: DiscountType = .percentage
    @Published var isDiscountEnabled: Bool = false


    var subtotal: Decimal { items.map { $0.total }.reduce(0, +) }
    
    var taxableAmount: Decimal {
        items.filter { !$0.isTaxExempt }.map { $0.total }.reduce(0, +)
    }
    
    var taxAmount: Decimal {
        if taxType == .percentage {
            return taxableAmount * (taxRate / 100)
        } else {
            return taxRate
        }
    }
    
    var calculatedDiscountAmount: Decimal {
        if !isDiscountEnabled { return 0 }
        if discountType == .percentage {
            return subtotal * (discountValue / 100)
        } else {
            return discountValue
        }
    }
    
    var total: Decimal {
        subtotal + taxAmount - calculatedDiscountAmount
    }
}

// MARK: - Wizard

struct InvoiceWizardView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = InvoiceWizardVM()

    // Template picker
    @State private var showTemplatePicker = false
    @State private var navigationPath = NavigationPath()

    // PDF share
    @State private var shareURL: URL?
    @State private var showShare = false
    @State private var shouldDismissAfterShare = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                StepHeader(step: vm.step)
                content
            }
            .onAppear {
                print("🎯 InvoiceWizardView appeared with template: \(app.selectedTemplate.name)")
            }
            .navigationTitle("Create Invoice")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button(action: { showTemplatePicker = true }) {
                        Label(app.selectedTemplate.name, systemImage: "tag")
                            .labelStyle(.titleAndIcon)
                    }
                    .accessibilityIdentifier("TemplatePickerButton")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: save) {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .accessibilityIdentifier("SaveInvoiceButton")
                }
            }
            .fullScreenCover(isPresented: $showTemplatePicker) {
                TemplatePickerView { selected in
                    app.selectedTemplate = selected      // save selection
                    showTemplatePicker = false           // close ONLY picker
                }
            }
            .onAppear(perform: configureFromAppState)
            .sheet(isPresented: $showShare, onDismiss: {
                if shouldDismissAfterShare { dismiss() }
            }) {
                if let url = shareURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    // Steps routing
    @ViewBuilder private var content: some View {
        switch vm.step {
        case 1:
            StepCompanyInfoView(vm: vm, next: { vm.step = 2 }, prev: nil)
        case 2:
            StepClientInfoView(vm: vm, next: { vm.step = 3 }, prev: { vm.step = 1 })
        case 3:
            StepPaymentDetailsView(vm: vm, prev: { vm.step = 2 }, next: { vm.step = 4 })
        default:
            StepItemsPricingView(vm: vm, prev: { vm.step = 3 }, onSaved: save)
        }
    }

    private func configureFromAppState() {
        // if came from "quick start" buttons
        var jumped = false
        if vm.customer == nil, let pre = app.preselectedCustomer {
            vm.customer = pre
            app.preselectedCustomer = nil
            if vm.step < 2 { vm.step = 2 }
            jumped = true
        }
        if let presetItems = app.preselectedItems, !presetItems.isEmpty {
            if vm.items.isEmpty {
                vm.items = presetItems
            } else {
                vm.items.append(contentsOf: presetItems)
            }
            app.preselectedItems = nil
            vm.step = 4
            jumped = true
        }
        if !jumped, vm.customer != nil, vm.step < 2 {
            vm.step = 2
        }
    }

    // Collect final payment methods list based on step selection
    private func resolvedPaymentMethods() -> [PaymentMethod] {
        switch vm.paymentChoice {
        case .none:
            return []
        case .custom:
            return vm.customMethods
        case .saved:
            let all = app.paymentMethods
            return all.filter { vm.selectedSaved.contains($0.id) }
        }
    }

    // Save -> PDF -> Share
    private func save() {
        guard let company = app.company,
              let customer = vm.customer,
              !vm.items.isEmpty
        else { return }

        var invoice = Invoice(
            number: vm.number,
            status: vm.status,
            issueDate: vm.issueDate,
            dueDate: vm.dueDate,
            company: company,
            customer: customer,
            currency: vm.currency,
            items: vm.items
        )

        // Apply payment methods and notes selected on Payment Details step
        invoice.paymentMethods = resolvedPaymentMethods()
        invoice.paymentNotes = vm.paymentNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : vm.paymentNotes
        
        // Apply tax and discount settings
        print("🔍 InvoiceWizardVM Tax settings: rate=\(vm.taxRate), type=\(vm.taxType)")
        print("🔍 InvoiceWizardVM Discount settings: enabled=\(vm.isDiscountEnabled), value=\(vm.discountValue), type=\(vm.discountType)")
        
        invoice.taxRate = vm.taxRate
        invoice.taxType = vm.taxType
        invoice.discountValue = vm.discountValue
        invoice.discountType = vm.discountType
        invoice.isDiscountEnabled = vm.isDiscountEnabled
        
        print("🔍 InvoiceWizardVM Invoice tax amount: \(invoice.taxAmount)")
        print("🔍 InvoiceWizardVM Invoice discount amount: \(invoice.calculatedDiscountAmount)")

        app.invoices.append(invoice)

        Task {
        do {
            let url = try PDFService.shared.generatePDF(
                invoice: invoice,
                company: company,
                customer: customer,
                currencyCode: vm.currency,
                template: app.selectedTemplate,
                logo: vm.includeLogo ? app.logoImage : nil
            )
                await MainActor.run {
            shareURL = url
            shouldDismissAfterShare = false
            showShare = true
                }
        } catch {
            print("PDF generation error:", error)
            // if something went wrong - just stay in wizard
            }
        }
    }
}

// MARK: - Step header

struct StepHeader: View {
    let step: Int
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(spacing: 0) {
            if UIDevice.current.userInterfaceIdiom == .pad || ProcessInfo.processInfo.isiOSAppOnMac {
                // iPad layout - horizontal
                VStack(spacing: 8) {
                    // Current step info for iPad
                    currentStepInfo
                    
                    // Step indicators
                    HStack(spacing: 8) {
                        stepItem(1, "", "")
            divider
                        stepItem(2, "", "")
            divider
                        stepItem(3, "", "")
            divider
                        stepItem(4, "", "")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            } else {
                // iPhone layout - vertical with progress bar
                VStack(spacing: 2) {
                    // Progress bar
                    progressBar
                    
                    // Current step info
                    currentStepInfo
                        .padding(.top, 4)
                        .padding(.bottom, 8)
                        .padding(.horizontal, 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 2)
            }
        }
    }
    
    private var progressBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Step \(step) of 4")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int((Double(step) / 4.0) * 100))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(scheme == .dark ? UI.darkAccent : .black)
                    .scaleEffect(step == 1 ? 1.0 : 1.1)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: step)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                        )
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(scheme == .dark ? UI.darkAccent : Color.black)
                        .frame(width: geometry.size.width * (Double(step) / 4.0), height: 6)
                        .shadow(
                            color: scheme == .dark ? UI.darkAccent.opacity(0.3) : .black.opacity(0.2), 
                            radius: 4, x: 0, y: 2
                        )
                        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: step)
                    
                }
            }
            .frame(height: 6)
        }
    }
    
    private var currentStepInfo: some View {
        HStack(spacing: 12) {
            // Animated step indicator
                ZStack {
                // Background pulse ring
                Circle()
                    .stroke(
                        scheme == .dark ? UI.darkAccent.opacity(0.4) : Color.black.opacity(0.3), 
                        lineWidth: 2
                    )
                    .frame(width: 40, height: 40)
                    .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 2) * 0.1)
                    .opacity(0.6)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: step)
                
                // Main circle
                Circle()
                    .fill(mainCircleFill)
                    .frame(width: 36, height: 36)
                    .shadow(
                        color: scheme == .dark ? UI.darkAccent.opacity(0.3) : .black.opacity(0.2), 
                        radius: 8, 
                        x: 0, 
                        y: 4
                    )
                    .scaleEffect(step == 1 ? 1.0 : 1.1)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: step)
                
                // Step number with bounce animation
                Text("\(step)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(scheme == .dark ? UI.darkText : .white)
                    .scaleEffect(step == 1 ? 1.0 : 1.2)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: step)
            }
            
            // Step content with slide animation
            VStack(alignment: .leading, spacing: 4) {
                Text(stepTitle)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(scheme == .dark ? UI.darkText : .primary)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                
                Text(stepDescription)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(scheme == .dark ? UI.darkSecondaryText : .secondary)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
            .animation(.easeInOut(duration: 0.4), value: step)
            
            Spacer()
            
            // Progress indicator with animated dots
            HStack(spacing: 6) {
                ForEach(1...4, id: \.self) { stepNumber in
                    Circle()
                        .fill(
                            stepNumber <= step ? 
                            (scheme == .dark ? UI.darkAccent : Color.black) : 
                            Color.secondary.opacity(0.3)
                        )
                        .frame(width: stepNumber == step ? 8 : 6, height: stepNumber == step ? 8 : 6)
                        .scaleEffect(stepNumber == step ? 1.3 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: step)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    private var divider: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color.secondary.opacity(0.3))
            .frame(width: 12, height: 1)
    }
    
    private func stepItem(_ n: Int, _ title: String, _ sub: String) -> some View {
        ZStack {
            // Background pulse for current step
            if n == step {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.blue.opacity(0.4), .purple.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                .frame(width: 24, height: 24)
                    .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 3) * 0.15)
                    .opacity(0.7)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: step)
            }
            
            // Main circle
            Circle()
                .fill(
                    n <= step ? 
                    (scheme == .dark ? UI.darkAccent : Color.black) : 
                    Color.secondary.opacity(0.3)
                )
                .frame(width: 20, height: 20)
                .shadow(
                    color: n == step ? 
                    (scheme == .dark ? UI.darkAccent.opacity(0.3) : .black.opacity(0.2)) : 
                    .clear, 
                    radius: 4, x: 0, y: 2
                )
                .scaleEffect(n == step ? 1.2 : 1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: step)
            
            // Content
            if n < step {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(n < step ? 1.0 : 0.8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: step)
            } else {
                Text("\(n)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(n == step ? .white : .secondary)
                    .scaleEffect(n == step ? 1.1 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: step)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var stepTitle: String {
        switch step {
        case 1: return "Company Information"
        case 2: return "Customer Details"
        case 3: return "Payment Methods"
        case 4: return "Invoice Items"
        default: return "Unknown Step"
        }
    }
    
    private var stepDescription: String {
        switch step {
        case 1: return "Set up your business details"
        case 2: return "Add customer information"
        case 3: return "Configure payment options"
        case 4: return "Add products and services"
        default: return "Complete this step"
        }
    }
    
    private var mainCircleFill: AnyShapeStyle {
        if scheme == .dark {
            return AnyShapeStyle(LinearGradient(colors: [UI.darkAccent, UI.darkAccentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing))
        } else {
            return AnyShapeStyle(Color.black)
        }
    }
}

// MARK: - Step 1: Company

struct CompanySetupCard: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        scheme == .dark ? 
                        AnyShapeStyle(Color(red: 0.12, green: 0.12, blue: 0.16)) : 
                        AnyShapeStyle(Material.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                scheme == .dark ? 
                                LinearGradient(
                                    colors: [.blue.opacity(0.4), .purple.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: scheme == .dark ? .black.opacity(0.3) : .black.opacity(0.05), 
                        radius: 8, x: 0, y: 4
                    )
            )
    }
}

struct StepCompanyInfoView: View {
    @EnvironmentObject private var app: AppState
    @ObservedObject var vm: InvoiceWizardVM
    var next: () -> Void
    var prev: (() -> Void)?
    @State private var company = Company()
    
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                    HStack {
                            Image(systemName: "building.2.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                            Text("Company Information")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        Text("Set up your business details for professional invoices")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 12) {
                        ModernTextField(
                            title: "Company Name",
                            text: $company.name,
                            icon: "building.2"
                        )
                        
                        HStack(spacing: 12) {
                            ModernTextField(
                                title: "Email",
                                text: $company.email,
                                icon: "envelope",
                                keyboardType: .emailAddress
                            )
                            
                            ModernTextField(
                                title: "Phone",
                                text: $company.phone,
                                icon: "phone",
                                keyboardType: .phonePad
                            )
                        }
                        
                        ModernTextField(
                            title: "Address",
                            text: $company.address.line1,
                            icon: "location"
                        )
                    }
                }
                .modifier(CompanySetupCard())
                
                // Logo Toggle Section
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "photo.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                            Text("Logo Settings")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            // Edit button to go to MyInfoView
                            if app.logoData != nil {
                                Button(action: {
                                    // Dismiss the entire invoice creation flow and navigate to MyInfoView
                                    NotificationCenter.default.post(name: NSNotification.Name("NavigateToMyInfo"), object: nil)
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "pencil.circle.fill")
                                        Text("Edit")
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(
                                                scheme == .dark ? 
                                                Color.blue.opacity(0.2) : 
                                                Color.blue.opacity(0.1)
                                            )
                                    )
                                }
                            }
                        }
                        Text(app.logoData != nil ? "Your company logo is ready" : "No logo uploaded yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Logo Preview
                    if let logoData = app.logoData, let uiImage = UIImage(data: logoData) {
                        HStack {
                            Spacer()
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 120, maxHeight: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            scheme == .dark ? 
                                            Color.blue.opacity(0.5) : 
                                            Color.blue.opacity(0.3), 
                                            lineWidth: 2
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Include Logo")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(app.logoData != nil ? .primary : .secondary)
                            
                            Text(app.logoData != nil ? "Show your company logo on the invoice" : "Upload a logo in Settings to enable this option")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $vm.includeLogo)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                            .disabled(app.logoData == nil)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(app.logoData != nil ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
                .modifier(CompanySetupCard())

                HStack(spacing: 16) {
                    Button(action: { prev?() }) {
                HStack {
                            Image(systemName: "chevron.left")
                            Text("Previous")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    scheme == .dark ? 
                                    Color(red: 0.15, green: 0.15, blue: 0.20) : 
                                    Color.secondary.opacity(0.1)
                                )
                        )
                        .foregroundColor(.secondary)
                    }
                        .disabled(prev == nil)
                    
                    Button(action: {
                        app.company = company
                        next()
                    }) {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    }
                    .disabled(company.name.trimmingCharacters(in: .whitespaces).isEmpty ||
                              company.email.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .onAppear {
            company = app.company ?? Company()
            // Automatically disable includeLogo if no logo is loaded
            if app.logoData == nil {
                vm.includeLogo = false
            }
        }
        .onChange(of: app.logoData) { newLogoData in
            // Automatically disable includeLogo if logo is removed
            if newLogoData == nil {
                vm.includeLogo = false
            }
        }
        .onTapGesture {
            // Close keyboard when tapping ScrollView
            hideKeyboard()
        }
        .simultaneousGesture(
            DragGesture()
                .onChanged { _ in
                    // Close keyboard when scrolling
                    hideKeyboard()
                }
        )
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Step 2: Client

struct StepClientInfoView: View {
    @EnvironmentObject private var app: AppState
    @ObservedObject var vm: InvoiceWizardVM
    var next: () -> Void
    var prev: () -> Void
    
    @State private var showAddCustomer = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Customer Selection
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                    HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                            Text("Customer Details")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        Text("Choose a customer for this invoice")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 12) {
                        ForEach(app.customers) { customer in
                            CustomerCard(
                                customer: customer,
                                isSelected: vm.customer?.id == customer.id,
                                onTap: { vm.customer = customer }
                            )
                        }
                        
                        // Add New Customer Button
                        Button(action: { showAddCustomer = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.blue)
                                
                                Text("Add New Customer")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.blue)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        
                        if app.customers.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                
                                Text("No customers yet")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("Add your first customer to get started")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 32)
                        }
                    }
                }
                .modifier(CompanySetupCard())

                // Invoice Details
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                    HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                            Text("Invoice Details")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        Text("Configure invoice number and dates")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            ModernTextField(
                                title: "Invoice Number",
                                text: $vm.number,
                                icon: "number"
                            )
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Status")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                
                        Picker("Status", selection: $vm.status) {
                                    ForEach(Invoice.Status.allCases) { status in
                                        Text(status.rawValue.capitalized).tag(status)
                            }
                        }
                        .pickerStyle(.menu)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.secondary.opacity(0.08))
                                )
                            }
                        }
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Issue Date")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                DatePicker("", selection: $vm.issueDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.secondary.opacity(0.08))
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Due Date")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                DatePicker("", selection: $vm.dueDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.secondary.opacity(0.08))
                                    )
                            }
                        }
                    }
                }
                .modifier(CompanySetupCard())

                // Navigation Buttons
                HStack(spacing: 16) {
                    Button(action: prev) {
                HStack {
                            Image(systemName: "chevron.left")
                            Text("Previous")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.secondary.opacity(0.1))
                        )
                        .foregroundColor(.secondary)
                    }
                    
                    Button(action: next) {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    vm.customer == nil ?
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) :
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .foregroundColor(vm.customer == nil ? .gray : .white)
                        .fontWeight(.semibold)
                    }
                        .disabled(vm.customer == nil)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .onTapGesture {
            // Close keyboard when tapping ScrollView
            hideKeyboard()
        }
        .simultaneousGesture(
            DragGesture()
                .onChanged { _ in
                    // Close keyboard when scrolling
                    hideKeyboard()
                }
        )
        .sheet(isPresented: $showAddCustomer) {
            AddCustomerView()
                .environmentObject(app)
        }
    }

    private func initials(for name: String) -> String {
        name.split(separator: " ").compactMap { $0.first }.prefix(2).map(String.init).joined()
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Step 3: Payment Details

struct StepPaymentDetailsView: View {
    @EnvironmentObject private var app: AppState
    @ObservedObject var vm: InvoiceWizardVM
    var prev: () -> Void
    var next: () -> Void

    @State private var showAddSheet = false
    @State private var editing: PaymentMethod? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                            Text("Payment Details")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        Text("Choose how to display payment information on the invoice")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Custom Payment Choice Picker
                    VStack(spacing: 12) {
                        Text("Payment Information")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 8) {
                            ForEach(InvoiceWizardVM.PaymentChoice.allCases) { choice in
                                PaymentChoiceCard(
                                    choice: choice,
                                    isSelected: vm.paymentChoice == choice,
                                    onTap: { vm.paymentChoice = choice }
                                )
                            }
                        }
                    }
                }
                .modifier(CompanySetupCard())

                // Payment Methods Section
                if vm.paymentChoice == .saved || vm.paymentChoice == .custom {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "list.bullet")
                                    .foregroundColor(.green)
                                    .font(.title3)
                                Text("Payment Methods")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            Text("Select payment methods to include on the invoice")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Saved Methods
                        if vm.paymentChoice == .saved {
                            if app.paymentMethods.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("You have no saved payment methods")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    Button(action: { showAddSheet = true }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add Payment Method")
                                        }
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.blue.opacity(0.1))
                                        )
                                    }
                                }
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(app.paymentMethods) { method in
                                        SavedMethodCard(
                                            method: method,
                                            isSelected: vm.selectedSaved.contains(method.id),
                                            onToggle: {
                                                if vm.selectedSaved.contains(method.id) {
                                                    vm.selectedSaved.remove(method.id)
                                                } else {
                                                    vm.selectedSaved.insert(method.id)
                                                }
                                            },
                                            onEdit: { editing = method }
                                        )
                                    }
                                    
                                    Button(action: { showAddSheet = true }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add Another Method")
                                        }
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.blue.opacity(0.1))
                                        )
                                    }
                                }
                            }
                        }

                        // Custom Methods
                        if vm.paymentChoice == .custom {
                            PaymentMethodsEditor(methods: $vm.customMethods)
                        }
                    }
                    .modifier(CompanySetupCard())
                }

                // Notes Section
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundColor(.orange)
                                .font(.title3)
                            Text("Additional Notes")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        Text("Optional notes to include with payment information")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Payment Notes")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        TextField("Shown below the payment block in PDF",
                                  text: $vm.paymentNotes,
                                  axis: .vertical)
                        .textInputAutocapitalization(.never)
                        .lineLimit(2...5)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary.opacity(0.08))
                        )
                    }
                }
                .modifier(CompanySetupCard())

                // Navigation Buttons
                HStack(spacing: 16) {
                    Button(action: prev) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Previous")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.secondary.opacity(0.1))
                        )
                        .foregroundColor(.secondary)
                    }
                    
                    Button(action: next) {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    }
                    .disabled(!canProceed)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showAddSheet) {
            AddEditPaymentMethodSheet { new in
                // if in saved mode - add to saved and immediately mark as selected
                if vm.paymentChoice == .saved {
                    app.paymentMethods.append(new)
                    app.savePaymentMethods()
                    vm.selectedSaved.insert(new.id)
                } else {
                    vm.customMethods.append(new)
                }
            }
        }
        .sheet(item: $editing) { m in
            AddEditPaymentMethodSheet(existing: m) { updated in
                if let idx = app.paymentMethods.firstIndex(where: { $0.id == m.id }) {
                    app.paymentMethods[idx] = updated
                    app.savePaymentMethods()
                }
            }
        }
        .onTapGesture {
            // Close keyboard when tapping ScrollView
            hideKeyboard()
        }
        .simultaneousGesture(
            DragGesture()
                .onChanged { _ in
                    // Close keyboard when scrolling
                    hideKeyboard()
                }
        )
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private var canProceed: Bool {
        switch vm.paymentChoice {
        case .none:   return true
        case .saved:  return !vm.selectedSaved.isEmpty
        case .custom: return !vm.customMethods.isEmpty
        }
    }
}

private struct SavedMethodRow: View {
    let method: PaymentMethod
    let isSelected: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(method.type.title).bold()
                Text(method.type.subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Edit", action: onEdit)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1)))
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.15)))
    }
}

// MARK: - Step 4: Items & Pricing

struct StepItemsPricingView: View {
    @EnvironmentObject private var app: AppState
    @ObservedObject var vm: InvoiceWizardVM
    var prev: () -> Void
    var onSaved: () -> Void

    @State private var search = ""
    @State private var category = "All"
    @State private var showAddItemSheet = false
    @State private var editingItem: LineItem? = nil
    
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                    VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "list.bullet.rectangle")
                                .foregroundColor(.blue)
                                .font(.title2)
                            Text("Invoice Items")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        Text("Add products and services to your invoice")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .modifier(CompanySetupCard())

                // Add Items Section
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                            Text("Add Items")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        Text("Choose from your catalog or add custom items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Search and Filter
                    VStack(spacing: 12) {
                        ModernTextField(
                            title: "Search products/services",
                            text: $search,
                            icon: "magnifyingglass"
                        )
                        
                        HStack(spacing: 12) {
                            Menu {
                                Picker("Category", selection: $category) {
                                    Text("All Categories").tag("All")
                                    ForEach(Array(Set(app.products.map { $0.category })).sorted(), id: \.self) { c in
                                        Text(c).tag(c)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(category == "All" ? "All Categories" : category)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            scheme == .dark ? 
                                            Color(red: 0.12, green: 0.12, blue: 0.16) : 
                                            Color.secondary.opacity(0.08)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    scheme == .dark ? 
                                                    Color.blue.opacity(0.2) : 
                                                    Color.clear,
                                                    lineWidth: 1
                                                )
                                        )
                                )
                            }
                            
                            Button(action: { showAddItemSheet = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add New")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                            }
                        }
                    }
                    
                    // Products List
                    if !filteredProducts.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(filteredProducts) { product in
                                ProductCard(
                                    product: product,
                                    onAdd: { add(product: product) }
                                )
                            }
                        }
                    } else if !search.isEmpty || category != "All" {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text("No products found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Try adjusting your search or category filter")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 20)
                    }
                }
                .modifier(CompanySetupCard())

                // Invoice Items
                if !vm.items.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                        HStack {
                                Image(systemName: "list.bullet")
                                    .foregroundColor(.orange)
                                    .font(.title3)
                                Text("Invoice Items")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            Text("Items added to this invoice")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 12) {
                        ForEach(vm.items) { item in
                                InvoiceItemCard(
                                    item: binding(for: item),
                                    onDelete: { deleteItem(item) }
                                )
                            }
                        }
                    }
                    .modifier(CompanySetupCard())
                }

                // Tax Section
                TaxSection(vm: vm)
                    .modifier(CompanySetupCard())

                // Discount Section
                DiscountSection(vm: vm)
                    .modifier(CompanySetupCard())

                // Summary Section
                SummarySection(vm: vm)
                    .modifier(CompanySetupCard())

                // Navigation Buttons
                HStack(spacing: 16) {
                    Button(action: prev) {
                HStack {
                            Image(systemName: "chevron.left")
                            Text("Previous")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.secondary.opacity(0.1))
                        )
                        .foregroundColor(.secondary)
                    }
                    
                    Button(action: onSaved) {
                        HStack {
                            Text("Generate Invoice")
                            Image(systemName: "chevron.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    }
                        .disabled(vm.items.isEmpty)
                }
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
        .sheet(isPresented: $showAddItemSheet) {
            AddEditItemSheet { newItem in
                vm.items.append(newItem)
            }
        }
        .sheet(item: $editingItem) { item in
            AddEditItemSheet(existing: item) { updatedItem in
                if let idx = vm.items.firstIndex(where: { $0.id == item.id }) {
                    vm.items[idx] = updatedItem
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private var filteredProducts: [Product] {
        app.products.filter {
            (category == "All" || $0.category == category) &&
            (search.isEmpty || $0.name.lowercased().contains(search.lowercased()))
        }
    }

    private func add(product p: Product) {
        vm.items.append(LineItem(description: p.name, quantity: 1, rate: p.rate))
    }
    
    private func deleteItem(_ item: LineItem) {
        vm.items.removeAll { $0.id == item.id }
    }

    private func binding(for item: LineItem) -> Binding<LineItem> {
        guard let idx = vm.items.firstIndex(where: { $0.id == item.id }) else {
            return .constant(item)
        }
        return $vm.items[idx]
    }
}

// MARK: - Product Card

private struct ProductCard: View {
    let product: Product
    let onAdd: () -> Void
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(product.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(product.category)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                        )
                }
                
                if !product.details.isEmpty {
                    Text(product.details)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text("\(Money.fmt(product.rate, code: Locale.current.currency?.identifier ?? "USD")) / hour")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
            }
            
            // Add Button
            Button(action: onAdd) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    scheme == .dark ? 
                    Color(red: 0.12, green: 0.12, blue: 0.16) : 
                    Color.secondary.opacity(0.05)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            scheme == .dark ? 
                            Color.blue.opacity(0.2) : 
                            Color.secondary.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Invoice Details View

struct InvoiceDetailsView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.colorScheme) private var scheme
    let invoice: Invoice
    
    @State private var showShareSheet = false
    @State private var showDeleteAlert = false
    @State private var showEditAlert = false
    @State private var pdfURL: URL?
    @State private var isGeneratingPDF = false
    @State private var showCustomerNotFoundAlert = false
    @State private var showPDFLoading = false
    
    private var bindingIndex: Int? {
        app.invoices.firstIndex(where: { $0.id == invoice.id })
    }
    
    private var binding: Binding<Invoice>? {
        if let idx = bindingIndex { return $app.invoices[idx] }
        return nil
    }
    
    private func navigateToCustomer() {
        let customerExists = app.customers.contains { $0.id == invoice.customer.id }
        if customerExists {
            // Navigation will be handled through NavigationLink
        } else {
            showCustomerNotFoundAlert = true
        }
    }
    
    var body: some View {
        Group {
            if let binding = binding {
                content(invoice: binding)
            } else {
                Text("Invoice not found").foregroundStyle(.secondary)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    // Status Actions
                    if invoice.status != .paid {
                        Button(action: { togglePaymentStatus() }) {
                            Label("Mark as Paid", systemImage: "checkmark.circle")
                        }
                    }
                    
                    if invoice.status != .sent {
                        Button(action: { markAsSent() }) {
                            Label("Mark as Sent", systemImage: "paperplane.circle")
                        }
                    }
                    
                    if invoice.status != .draft {
                        Button(action: { markAsDraft() }) {
                            Label("Mark as Draft", systemImage: "doc.circle")
                        }
                    }
                    
                    Divider()
                    
                    Button(action: { showEditAlert = true }) {
                        Label("Edit Invoice", systemImage: "pencil")
                    }
                    
                    Button(action: { generateAndSharePDF() }) {
                        Label("Share PDF", systemImage: "square.and.arrow.up")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        Label("Delete Invoice", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.blue)
                }
            }
        }
        .alert("Delete Invoice", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { deleteInvoice() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this invoice? This action cannot be undone.")
        }
        .alert("Edit Invoice", isPresented: $showEditAlert) {
            Button("Edit") { /* TODO: Navigate to edit */ }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Invoice editing functionality will be available in a future update.")
        }
        .sheet(isPresented: $showShareSheet) {
            if let pdfURL = pdfURL {
                ShareSheet(items: [pdfURL])
            }
        }
        .alert("Customer Not Found", isPresented: $showCustomerNotFoundAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This customer has been deleted and is no longer available. The invoice information is preserved for your records.")
        }
        .fullScreenCover(isPresented: $showPDFLoading) {
            PDFLoadingView()
        }
    }
    
    @ViewBuilder
    private func content(invoice: Binding<Invoice>) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Section
                headerSection(invoice: invoice)
                
                // Status & Actions Section
                statusSection(invoice: invoice)
                
                // Company & Customer Info
                companyCustomerSection(invoice: invoice)
                
                // Invoice Details
                invoiceDetailsSection(invoice: invoice)
                
                // Items Section
                itemsSection(invoice: invoice)
                
                // Summary Section
                summarySection(invoice: invoice)
                
                // Payment Methods
                paymentMethodsSection(invoice: invoice)
                
                // PDF Actions
                pdfActionsSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .onAppear {
            generatePDFIfNeeded()
        }
    }
    
    private func headerSection(invoice: Binding<Invoice>) -> some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Invoice #\(invoice.wrappedValue.number)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Created \(Dates.display.string(from: invoice.wrappedValue.issueDate))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                    Spacer()
                
                StatusChip(status: invoice.wrappedValue.status)
                }
            
            if let dueDate = invoice.wrappedValue.dueDate {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.orange)
                    Text("Due: \(Dates.display.string(from: dueDate))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if dueDate < Date() && invoice.wrappedValue.status != .paid {
                        Text("Overdue")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.red)
                            )
                    }
                }
            }
        }
        .modifier(CompanySetupCard())
    }
    
    private func statusSection(invoice: Binding<Invoice>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.title3)
                Text("Invoice Status")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            VStack(spacing: 16) {
                HStack {
                    StatusChip(status: invoice.wrappedValue.status)
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    // Показываем две кнопки в зависимости от текущего статуса
                    if invoice.wrappedValue.status == .draft {
                        // Если статус draft, показываем Paid и Sent
                        Button(action: { 
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                togglePaymentStatus()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                Text("Mark as Paid")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.green)
                                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                        }
                        .scaleEffect(invoice.wrappedValue.status == .paid ? 0.95 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: invoice.wrappedValue.status)
                        
                        Button(action: { 
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                markAsSent()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "paperplane.circle.fill")
                                    .font(.title2)
                                Text("Mark as Sent")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.blue)
                                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                        }
                        .scaleEffect(invoice.wrappedValue.status == .sent ? 0.95 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: invoice.wrappedValue.status)
                        
                    } else if invoice.wrappedValue.status == .sent {
                        // Если статус sent, показываем Paid и Draft
                        Button(action: { 
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                togglePaymentStatus()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                Text("Mark as Paid")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.green)
                                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                        }
                        .scaleEffect(invoice.wrappedValue.status == .paid ? 0.95 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: invoice.wrappedValue.status)
                        
                        Button(action: { 
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                markAsDraft()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.circle.fill")
                                    .font(.title2)
                                Text("Mark as Draft")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray)
                                    .shadow(color: .gray.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                        }
                        .scaleEffect(invoice.wrappedValue.status == .draft ? 0.95 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: invoice.wrappedValue.status)
                        
                    } else if invoice.wrappedValue.status == .paid {
                        // Если статус paid, показываем Sent и Draft
                        Button(action: { 
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                markAsSent()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "paperplane.circle.fill")
                                    .font(.title2)
                                Text("Mark as Sent")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.blue)
                                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                        }
                        .scaleEffect(invoice.wrappedValue.status == .sent ? 0.95 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: invoice.wrappedValue.status)
                        
                        Button(action: { 
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                markAsDraft()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.circle.fill")
                                    .font(.title2)
                                Text("Mark as Draft")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray)
                                    .shadow(color: .gray.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                        }
                        .scaleEffect(invoice.wrappedValue.status == .draft ? 0.95 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: invoice.wrappedValue.status)
                    }
                }
            }
        }
        .modifier(CompanySetupCard())
    }
    
    private func companyCustomerSection(invoice: Binding<Invoice>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "building.2")
                    .foregroundColor(.purple)
                    .font(.title3)
                Text("Company & Customer")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            VStack(spacing: 16) {
                // Company Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("From")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(invoice.wrappedValue.company.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if !invoice.wrappedValue.company.address.oneLine.isEmpty {
                            Text(invoice.wrappedValue.company.address.oneLine)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if !invoice.wrappedValue.company.email.isEmpty {
                            Text(invoice.wrappedValue.company.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if !invoice.wrappedValue.company.phone.isEmpty {
                            Text(invoice.wrappedValue.company.phone)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Divider()
                
                // Customer Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("To")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    let customerExists = app.customers.contains { $0.id == invoice.wrappedValue.customer.id }
                    
                    if customerExists {
                        NavigationLink(destination: CustomerDetailsView(customerID: invoice.wrappedValue.customer.id)) {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(invoice.wrappedValue.customer.name)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    if !invoice.wrappedValue.customer.address.oneLine.isEmpty {
                                        Text(invoice.wrappedValue.customer.address.oneLine)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if !invoice.wrappedValue.customer.email.isEmpty {
                                        Text(invoice.wrappedValue.customer.email)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if !invoice.wrappedValue.customer.phone.isEmpty {
                                        Text(invoice.wrappedValue.customer.phone)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Красивая стрелочка
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue.opacity(0.6))
                                    .padding(.top, 2)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Button(action: { showCustomerNotFoundAlert = true }) {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(invoice.wrappedValue.customer.name)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    if !invoice.wrappedValue.customer.address.oneLine.isEmpty {
                                        Text(invoice.wrappedValue.customer.address.oneLine)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if !invoice.wrappedValue.customer.email.isEmpty {
                                        Text(invoice.wrappedValue.customer.email)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if !invoice.wrappedValue.customer.phone.isEmpty {
                                        Text(invoice.wrappedValue.customer.phone)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Красивая стрелочка
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue.opacity(0.6))
                                    .padding(.top, 2)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .modifier(CompanySetupCard())
    }
    
    private func invoiceDetailsSection(invoice: Binding<Invoice>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
                        HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.green)
                    .font(.title3)
                Text("Invoice Details")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            VStack(spacing: 12) {
                detailRow(title: "Invoice Number", value: invoice.wrappedValue.number)
                detailRow(title: "Issue Date", value: Dates.display.string(from: invoice.wrappedValue.issueDate))
                
                if let dueDate = invoice.wrappedValue.dueDate {
                    detailRow(title: "Due Date", value: Dates.display.string(from: dueDate))
                }
                
                detailRow(title: "Currency", value: invoice.wrappedValue.currency)
                
                if let notes = invoice.wrappedValue.paymentNotes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Text(notes)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .modifier(CompanySetupCard())
    }
    
    private func itemsSection(invoice: Binding<Invoice>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.orange)
                    .font(.title3)
                Text("Items")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            if invoice.wrappedValue.items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No items")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("This invoice has no items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(invoice.wrappedValue.items) { item in
                        itemRow(item: item, currency: invoice.wrappedValue.currency)
                    }
                }
            }
        }
        .modifier(CompanySetupCard())
    }
    
    private func itemRow(item: LineItem, currency: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.description.isEmpty ? "Untitled Item" : item.description)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                            Spacer()
                
                Text(Money.fmt(item.total, code: currency))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            HStack {
                Text("Qty: \(NSDecimalNumber(decimal: item.quantity).doubleValue, specifier: "%.1f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("×")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(Money.fmt(item.rate, code: currency))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if item.isTaxExempt {
                    Text("Tax Exempt")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.1))
                        )
                }
            }
            
            if item.discount > 0 {
                HStack {
                    Text("Discount: \(NSDecimalNumber(decimal: item.discount).doubleValue, specifier: "%.2f")\(item.discountType == .percentage ? "%" : "")")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func summarySection(invoice: Binding<Invoice>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calculator")
                    .foregroundColor(.blue)
                    .font(.title3)
                Text("Summary")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            VStack(spacing: 12) {
                // Показываем детализацию по каждому товару
                ForEach(invoice.wrappedValue.items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.description.isEmpty ? "Untitled Item" : item.description)
                                .font(.body)
                                .foregroundColor(.primary)
                            Spacer()
                            Text(Money.fmt(item.total, code: invoice.wrappedValue.currency))
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        // Показываем скидку на товар, если есть
                        if item.discount > 0 {
                            HStack {
                                Text("Item Discount (\(NSDecimalNumber(decimal: item.discount).doubleValue, specifier: "%.1f")\(item.discountType == .percentage ? "%" : ""))")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                Spacer()
                                let itemSubtotal = item.quantity * item.rate
                                let itemDiscountAmount = item.discountType == .percentage ? itemSubtotal * (item.discount / 100) : item.discount
                                Text("-\(Money.fmt(itemDiscountAmount, code: invoice.wrappedValue.currency))")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    Text("Subtotal")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(Money.fmt(invoice.wrappedValue.subtotal, code: invoice.wrappedValue.currency))
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                // Subtotal
                HStack {
                    Text("Subtotal")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(Money.fmt(invoice.wrappedValue.subtotal, code: invoice.wrappedValue.currency))
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                // Tax (всегда показываем для отладки)
                HStack {
                    Text("Tax")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(Money.fmt(invoice.wrappedValue.taxAmount, code: invoice.wrappedValue.currency))
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(invoice.wrappedValue.taxAmount > 0 ? .red : .secondary)
                }
                
                // Discount (всегда показываем для отладки)
                HStack {
                    Text("Discount")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("-\(Money.fmt(invoice.wrappedValue.calculatedDiscountAmount, code: invoice.wrappedValue.currency))")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(invoice.wrappedValue.calculatedDiscountAmount > 0 ? .green : .secondary)
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(Money.fmt(invoice.wrappedValue.total, code: invoice.wrappedValue.currency))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
        }
        .modifier(CompanySetupCard())
    }
    
    private func paymentMethodsSection(invoice: Binding<Invoice>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "creditcard")
                    .foregroundColor(.purple)
                    .font(.title3)
                Text("Payment Methods")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            if invoice.wrappedValue.paymentMethods.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "creditcard")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No payment methods")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("No payment methods specified for this invoice")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(invoice.wrappedValue.paymentMethods) { method in
                        paymentMethodRow(method: method)
                    }
                }
            }
            
            if let paymentNotes = invoice.wrappedValue.paymentNotes, !paymentNotes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payment Notes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Text(paymentNotes)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .padding(.top, 8)
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
        .padding(.vertical, 4)
    }
    
    private var pdfActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.richtext")
                    .foregroundColor(.red)
                    .font(.title3)
                Text("PDF Document")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            VStack(spacing: 12) {
                if isGeneratingPDF {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Generating PDF...")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    Button(action: { generateAndSharePDF() }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share PDF")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                    
                }
            }
        }
        .modifier(CompanySetupCard())
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
    
    private func icon(for type: PaymentMethodType) -> String {
        switch type {
        case .bankIBAN: return "building.columns"
        case .bankUS:   return "banknote"
        case .paypal:   return "envelope"
        case .cardLink: return "link"
        case .crypto:   return "bitcoinsign.circle"
        case .other:    return "square.and.pencil"
        }
    }
    
    private func togglePaymentStatus() {
        guard let binding = binding else { return }
        binding.wrappedValue.status = binding.wrappedValue.status == .paid ? .draft : .paid
    }
    
    private func markAsSent() {
        guard let binding = binding else { return }
        binding.wrappedValue.status = .sent
    }
    
    private func markAsDraft() {
        guard let binding = binding else { return }
        binding.wrappedValue.status = .draft
    }
    
    private func deleteInvoice() {
        guard let idx = bindingIndex else { return }
        app.invoices.remove(at: idx)
    }
    
    private func generatePDFIfNeeded() {
        // Generate PDF in background if not already generated
        Task {
            await generatePDF()
        }
    }
    
    private func generateAndSharePDF() {
        showPDFLoading = true
        Task {
            await generatePDF()
            await MainActor.run {
                // Убеждаемся что PDF готов и URL доступен
                if pdfURL != nil {
                    showPDFLoading = false
                    // Небольшая задержка чтобы ShareSheet успел подготовиться
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showShareSheet = true
                    }
                } else {
                    // Если PDF не сгенерировался, скрываем loading
                    showPDFLoading = false
                }
            }
        }
    }
    
    
    @MainActor
    private func generatePDF() async {
        isGeneratingPDF = true
        pdfURL = nil // Сбрасываем предыдущий URL
        
        do {
            let url = try await PDFService.shared.generatePDF(
                invoice: invoice,
                company: invoice.company,
                customer: invoice.customer,
                currencyCode: invoice.currency,
                template: app.selectedTemplate,
                logo: app.logoImage
            )
            pdfURL = url
            print("PDF generated successfully: \(url)")
        } catch {
            print("Error generating PDF: \(error)")
            pdfURL = nil
        }
        
        isGeneratingPDF = false
    }
    
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - PDF Loading View

struct PDFLoadingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: CGFloat = 0
    @State private var backgroundOpacity: CGFloat = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowIntensity: CGFloat = 0
    @State private var breatheScale: CGFloat = 1.0
    @State private var textOpacity: CGFloat = 0
    @State private var progressOpacity: CGFloat = 0
    @State private var progressWidth: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Dynamic background
            LinearGradient(
                colors: colorScheme == .dark ? [
                    Color.black,
                    Color.black.opacity(0.9),
                    Color.black.opacity(0.8)
                ] : [
                    Color.white,
                    Color.white.opacity(0.95),
                    Color.white.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(backgroundOpacity)
            
            // Animated background particles
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                    .frame(width: CGFloat.random(in: 15...40))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .scaleEffect(pulseScale)
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 2...4))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.3),
                        value: pulseScale
                    )
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                // PDF Icon with animation
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: colorScheme == .dark ? [
                                    Color.blue.opacity(0.3 * glowIntensity),
                                    Color.blue.opacity(0.1 * glowIntensity),
                                    Color.clear
                                ] : [
                                    Color.blue.opacity(0.2 * glowIntensity),
                                    Color.blue.opacity(0.1 * glowIntensity),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 15)
                    
                    // PDF Icon
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 80, weight: .light))
                        .foregroundColor(.blue)
                        .scaleEffect(logoScale * breatheScale)
                        .opacity(logoOpacity)
                        .shadow(
                            color: colorScheme == .dark ? .blue.opacity(0.5) : .blue.opacity(0.3), 
                            radius: 15, x: 0, y: 0
                        )
                        .overlay(
                            // Shimmer effect
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.clear,
                                            Color.blue.opacity(0.6),
                                            Color.clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 60, height: 80)
                                .offset(x: shimmerOffset)
                                .mask(
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 80, weight: .light))
                                )
                        )
                }
                
                // Loading text
                VStack(spacing: 16) {
                    Text("Preparing...")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.8))
                        .opacity(textOpacity)
                    
                    Text("Please wait while we create your invoice")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .opacity(textOpacity)
                }
                
                // Progress bar
                VStack(spacing: 12) {
                    HStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                            .frame(height: 8)
                            .overlay(
                                HStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue, .blue.opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: progressWidth)
                                        .animation(.easeInOut(duration: 2.0), value: progressWidth)
                                    Spacer(minLength: 0)
                                }
                            )
                    }
                    .frame(width: 200)
                    .opacity(progressOpacity)
                }
                
                Spacer()
            }
        }
        .onAppear {
            startProgressiveAnimation()
        }
    }
    
    private func startProgressiveAnimation() {
        // Phase 1: Background fade in
        withAnimation(.easeInOut(duration: 0.8)) {
            backgroundOpacity = 1.0
        }
        
        // Phase 2: Icon entrance (0.5s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 1.0)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
        
        // Phase 3: Glow effect (1.0s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 1.5)) {
                glowIntensity = 1.0
            }
        }
        
        // Phase 4: Shimmer effect (1.5s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 2.0)) {
                shimmerOffset = 200
            }
        }
        
        // Phase 5: Text appears (2.0s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.8)) {
                textOpacity = 1.0
            }
        }
        
        // Phase 6: Progress bar appears (2.5s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.8)) {
                progressOpacity = 1.0
            }
            
            // Animate progress bar
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 2.0)) {
                    progressWidth = 200
                }
            }
        }
        
        // Phase 7: Start breathing animation (3.0s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                breatheScale = 1.05
            }
        }
        
        // Start pulse animation for background particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            pulseScale = 1.15
        }
    }
}

// MARK: - Reusable UI

extension View {
    func fieldStyle() -> some View {
        self.padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        Color.secondary.opacity(0.08)
                    )
            )
    }
}

struct ModernTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var textInputAutocapitalization: TextInputAutocapitalization = .sentences
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                TextField(title, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(textInputAutocapitalization)
                    .font(.system(size: 16))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        scheme == .dark ? 
                        Color(red: 0.12, green: 0.12, blue: 0.16) : 
                        Color.secondary.opacity(0.08)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                text.isEmpty ? 
                                (scheme == .dark ? Color.blue.opacity(0.2) : Color.clear) : 
                                Color.blue.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
        }
    }
}

struct CustomerCard: View {
    let customer: Customer
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var scheme
    
    private var backgroundColor: Color {
        if isSelected {
            return scheme == .dark ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1)
        } else {
            return scheme == .dark ? Color(red: 0.12, green: 0.12, blue: 0.16) : Color.secondary.opacity(0.05)
        }
    }
    
    private var strokeColor: Color {
        if isSelected {
            return scheme == .dark ? Color.blue.opacity(0.5) : Color.blue.opacity(0.3)
        } else {
            return scheme == .dark ? Color.blue.opacity(0.2) : Color.clear
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Avatar(initials: initials(for: customer.name))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(customer.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(customer.email)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(strokeColor, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func initials(for name: String) -> String {
        name.split(separator: " ").compactMap { $0.first }.prefix(2).map(String.init).joined()
    }
}

struct Avatar: View {
    let initials: String
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 48, height: 48)
            .overlay(
                Text(initials)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            )
    }
}

struct Tag: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.secondary.opacity(0.1)))
    }
}

// MARK: - Invoice Item Card

private struct InvoiceItemCard: View {
    @Binding var item: LineItem
    let onDelete: () -> Void
    
    @Environment(\.colorScheme) private var scheme
    @State private var showDetails = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Main Item Info
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.description.isEmpty ? "Untitled Item" : item.description)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 16) {
                        Text("Qty: \(NSDecimalNumber(decimal: item.quantity).doubleValue, specifier: "%.1f")")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("Rate: \(Money.fmt(item.rate, code: Locale.current.currency?.identifier ?? "USD"))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        if item.isTaxExempt {
                            Text("Tax Exempt")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.green.opacity(0.1))
                                )
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(Money.fmt(item.total, code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Button(action: { showDetails.toggle() }) {
                        Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Expandable Details
            if showDetails {
                VStack(spacing: 12) {
                    Divider()
                    
                    // Description
                    ModernTextField(
                        title: "Description",
                        text: $item.description,
                        icon: "text.alignleft"
                    )
                    
                    // Quantity and Rate
                    HStack(spacing: 12) {
                        ModernTextField(
                            title: "Quantity",
                            text: Binding(
                                get: { String(format: "%.1f", NSDecimalNumber(decimal: item.quantity).doubleValue) },
                                set: { item.quantity = Decimal(string: $0) ?? 0 }
                            ),
                            icon: "number"
                        )
                        
                        ModernTextField(
                            title: "Rate",
                            text: Binding(
                                get: { String(format: "%.2f", NSDecimalNumber(decimal: item.rate).doubleValue) },
                                set: { item.rate = Decimal(string: $0) ?? 0 }
                            ),
                            icon: "dollarsign.circle"
                        )
                    }
                    
                    // Discount
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Discount")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Picker("Type", selection: $item.discountType) {
                                ForEach(DiscountType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 120)
                        }
                        
                        ModernTextField(
                            title: item.discountType == .percentage ? "Discount %" : "Discount Amount",
                            text: Binding(
                                get: { String(format: "%.2f", NSDecimalNumber(decimal: item.discount).doubleValue) },
                                set: { item.discount = Decimal(string: $0) ?? 0 }
                            ),
                            icon: "percent"
                        )
                    }
                    
                    // Tax Exempt Toggle
                    HStack {
                        Toggle("Tax Exempt", isOn: $item.isTaxExempt)
                            .font(.system(size: 14, weight: .medium))
                        
                        Spacer()
                    }
                    
                    // Delete Button
                    Button(action: onDelete) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Remove Item")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.1))
                        )
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    scheme == .dark ? 
                    Color(red: 0.12, green: 0.12, blue: 0.16) : 
                    Color.secondary.opacity(0.05)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            scheme == .dark ? 
                            Color.blue.opacity(0.2) : 
                            Color.secondary.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
        .animation(.easeInOut(duration: 0.3), value: showDetails)
    }
}

// MARK: - Tax Section

private struct TaxSection: View {
    @ObservedObject var vm: InvoiceWizardVM
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "percent")
                        .foregroundColor(.red)
                        .font(.title3)
                    Text("Tax")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Text("Add tax to taxable items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Tax Type")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Picker("Type", selection: $vm.taxType) {
                        ForEach(TaxType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 120)
                }
                
                ModernTextField(
                    title: vm.taxType == .percentage ? "Tax Rate %" : "Tax Amount",
                    text: Binding(
                        get: { String(format: "%.2f", NSDecimalNumber(decimal: vm.taxRate).doubleValue) },
                        set: { vm.taxRate = Decimal(string: $0) ?? 0 }
                    ),
                    icon: "percent"
                )
                
                // Debug: Always show tax calculation
                HStack {
                    Text("Tax Amount (Rate: \(NSDecimalNumber(decimal: vm.taxRate).doubleValue, specifier: "%.1f")%):")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(Money.fmt(vm.taxAmount, code: vm.currency))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.red)
                }
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - Discount Section

private struct DiscountSection: View {
    @ObservedObject var vm: InvoiceWizardVM
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "tag")
                        .foregroundColor(.green)
                        .font(.title3)
                    Text("Discount")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Text("Apply discount to the total amount")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Toggle("Enable Discount", isOn: $vm.isDiscountEnabled)
                        .font(.system(size: 14, weight: .semibold))
                    
                    Spacer()
                }
                
                if vm.isDiscountEnabled {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Discount Type")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Picker("Type", selection: $vm.discountType) {
                                ForEach(DiscountType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 120)
                        }
                        
                        ModernTextField(
                            title: vm.discountType == .percentage ? "Discount %" : "Discount Amount",
                            text: Binding(
                                get: { String(format: "%.2f", NSDecimalNumber(decimal: vm.discountValue).doubleValue) },
                                set: { vm.discountValue = Decimal(string: $0) ?? 0 }
                            ),
                            icon: "percent"
                        )
                        
                        // Debug: Always show discount calculation
                        HStack {
                            Text("Discount Amount (Enabled: \(vm.isDiscountEnabled ? "Yes" : "No"), Value: \(NSDecimalNumber(decimal: vm.discountValue).doubleValue, specifier: "%.1f")%):")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(Money.fmt(vm.calculatedDiscountAmount, code: vm.currency))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.green)
                        }
                        .padding(.top, 8)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: vm.isDiscountEnabled)
    }
}

// MARK: - Summary Section

private struct SummarySection: View {
    @ObservedObject var vm: InvoiceWizardVM
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calculator")
                        .foregroundColor(.blue)
                        .font(.title3)
                    Text("Invoice Summary")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Text("Final calculation breakdown")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                // Subtotal
                HStack {
                    Text("Subtotal")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(Money.fmt(vm.subtotal, code: vm.currency))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                // Tax (всегда показываем для отладки)
                HStack {
                    Text("Tax")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(Money.fmt(vm.taxAmount, code: vm.currency))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(vm.taxAmount > 0 ? .red : .secondary)
                }
                
                // Discount (всегда показываем для отладки)
                HStack {
                    Text("Discount")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("-\(Money.fmt(vm.calculatedDiscountAmount, code: vm.currency))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(vm.calculatedDiscountAmount > 0 ? .green : .secondary)
                }
                
                Divider()
                
                // Total
                HStack {
                    Text("Total")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(Money.fmt(vm.total, code: vm.currency))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Add Edit Item Sheet

struct AddEditItemSheet: View {
    private let existing: LineItem?
    var onSave: (LineItem) -> Void
    
    @State private var description = ""
    @State private var quantity: Decimal = 1
    @State private var rate: Decimal = 0
    @State private var discount: Decimal = 0
    @State private var discountType: DiscountType = .percentage
    @State private var isTaxExempt = false
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    
    init(existing: LineItem? = nil, onSave: @escaping (LineItem) -> Void) {
        self.existing = existing
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                Text(existing == nil ? "Add New Item" : "Edit Item")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            Text("Add a custom item to your invoice")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .modifier(CompanySetupCard())
                    
                    // Form
                    VStack(spacing: 16) {
                        ModernTextField(
                            title: "Description",
                            text: $description,
                            icon: "text.alignleft"
                        )
                        
                        HStack(spacing: 12) {
                            ModernTextField(
                                title: "Quantity",
                                text: Binding(
                                    get: { String(format: "%.1f", NSDecimalNumber(decimal: quantity).doubleValue) },
                                    set: { quantity = Decimal(string: $0) ?? 0 }
                                ),
                                icon: "number"
                            )
                            
                            ModernTextField(
                                title: "Rate",
                                text: Binding(
                                    get: { String(format: "%.2f", NSDecimalNumber(decimal: rate).doubleValue) },
                                    set: { rate = Decimal(string: $0) ?? 0 }
                                ),
                                icon: "dollarsign.circle"
                            )
                        }
                        
                        // Discount
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Discount")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Picker("Type", selection: $discountType) {
                                    ForEach(DiscountType.allCases, id: \.self) { type in
                                        Text(type.displayName).tag(type)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(width: 120)
                            }
                            
                            ModernTextField(
                                title: discountType == .percentage ? "Discount %" : "Discount Amount",
                                text: Binding(
                                    get: { String(format: "%.2f", NSDecimalNumber(decimal: discount).doubleValue) },
                                    set: { discount = Decimal(string: $0) ?? 0 }
                                ),
                                icon: "percent"
                            )
                        }
                        
                        // Tax Exempt
                        HStack {
                            Toggle("Tax Exempt", isOn: $isTaxExempt)
                                .font(.system(size: 14, weight: .medium))
                            
                            Spacer()
                        }
                    }
                    .modifier(CompanySetupCard())
                    
                    // Preview
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "eye")
                                .foregroundColor(.blue)
                                .font(.title3)
                            Text("Preview")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        
        VStack(spacing: 8) {
            HStack {
                                Text("Total:")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                
                Spacer()
                                
                                Text(Money.fmt(calculatedTotal, code: Locale.current.currency?.identifier ?? "USD"))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .modifier(CompanySetupCard())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let item = LineItem(
                            description: description,
                            quantity: quantity,
                            rate: rate,
                            discount: discount,
                            discountType: discountType,
                            isTaxExempt: isTaxExempt
                        )
                        onSave(item)
                        dismiss()
                    }
                    .disabled(description.isEmpty)
                }
            }
        }
        .onAppear {
            if let existing = existing {
                description = existing.description
                quantity = existing.quantity
                rate = existing.rate
                discount = existing.discount
                discountType = existing.discountType
                isTaxExempt = existing.isTaxExempt
            }
        }
    }
    
    private var calculatedTotal: Decimal {
        let subtotal = quantity * rate
        let discountAmount = discountType == .percentage ? subtotal * (discount / 100) : discount
        return max(0, subtotal - discountAmount)
    }
}

struct DecimalField: View {
    let title: String
    @Binding var value: Decimal
    var body: some View {
        TextField(
            title,
            text: Binding(
                get: { NSDecimalNumber(decimal: value).stringValue },
                set: { value = Decimal(string: $0.replacingOccurrences(of: ",", with: ".")) ?? value }
            )
        )
        .keyboardType(.decimalPad)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
    }
}


// MARK: - Custom Payment Components

struct PaymentChoiceCard: View {
    let choice: InvoiceWizardVM.PaymentChoice
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: choice.iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.blue : Color.blue.opacity(0.1))
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(choice.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(choice.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "circle")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? 
                          LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing) :
                          LinearGradient(
                              colors: [scheme == .dark ? Color(red: 0.12, green: 0.12, blue: 0.16) : Color.secondary.opacity(0.05)], 
                              startPoint: .leading, 
                              endPoint: .trailing
                          )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.clear : 
                                (scheme == .dark ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.2)),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? Color.blue.opacity(0.3) : Color.clear,
                radius: 8,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SavedMethodCard: View {
    let method: PaymentMethod
    let isSelected: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    
    @Environment(\.colorScheme) private var scheme
    
    private var backgroundColor: Color {
        if isSelected {
            return scheme == .dark ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1)
        } else {
            return scheme == .dark ? Color(red: 0.12, green: 0.12, blue: 0.16) : Color.secondary.opacity(0.05)
        }
    }
    
    private var strokeColor: Color {
        if isSelected {
            return scheme == .dark ? Color.blue.opacity(0.5) : Color.blue.opacity(0.3)
        } else {
            return scheme == .dark ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.1)
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection button
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Method info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: method.type.iconName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Text(method.type.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Text(method.type.subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(strokeColor, lineWidth: 1)
                )
        )
    }
}

// MARK: - PaymentChoice Extensions

extension InvoiceWizardVM.PaymentChoice {
    var iconName: String {
        switch self {
        case .none: return "xmark.circle"
        case .saved: return "bookmark.circle"
        case .custom: return "pencil.circle"
        }
    }
    
    var description: String {
        switch self {
        case .none: return "Don't include payment information"
        case .saved: return "Use your saved payment methods"
        case .custom: return "Add custom payment methods for this invoice"
        }
    }
}
