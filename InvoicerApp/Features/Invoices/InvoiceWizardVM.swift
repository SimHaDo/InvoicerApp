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
    @Published var selectedSaved: Set<UUID> = []              // выбранные из app.paymentMethods
    @Published var customMethods: [PaymentMethod] = []        // кастомные для этого инвойса
    @Published var paymentNotes: String = ""                  // дополнительные примечания (на инвойсе)
    @Published var includeLogo: Bool = true                   // включить логотип в инвойс

    var subtotal: Decimal { items.map { $0.total }.reduce(0, +) }
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
                // Нажимаем на "лейбл" – открываем выбор шаблона
                ToolbarItem(placement: .principal) {
                    Button { showTemplatePicker = true } label: {
                        Label(app.selectedTemplate.name, systemImage: "tag")
                            .labelStyle(.titleAndIcon)
                    }
                    .accessibilityIdentifier("TemplatePickerButton")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { save() } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .accessibilityIdentifier("SaveInvoiceButton")
                }
            }
            .fullScreenCover(isPresented: $showTemplatePicker) {
                TemplatePickerView { selected in
                    app.selectedTemplate = selected      // сохраняем выбор
                    showTemplatePicker = false           // закрываем ТОЛЬКО пикер
                }
            }
            .onAppear(perform: configureFromAppState)
            .sheet(isPresented: $showShare, onDismiss: {
                if shouldDismissAfterShare { dismiss() }
            }) {
                if let url = shareURL {
                    ShareSheet(activityItems: [url]) { _, _, _, _ in
                        // Пользователь закрыл контроллер шаринга
                        shouldDismissAfterShare = true
                    }
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
        // если пришли из кнопок "быстрого старта"
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

    // Собираем финальный список реквизитов на основе выбора на шаге
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

        // Применяем реквизиты и заметки, выбранные на шаге Payment Details
        invoice.paymentMethods = resolvedPaymentMethods()
        invoice.paymentNotes = vm.paymentNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : vm.paymentNotes

        app.invoices.append(invoice)

        do {
            let url = try PDFService.shared.generatePDF(
                invoice: invoice,
                company: company,
                customer: customer,
                currencyCode: vm.currency,
                template: app.selectedTemplate,
                logo: vm.includeLogo ? app.logoImage : nil
            )
            shareURL = url
            shouldDismissAfterShare = false
            showShare = true
        } catch {
            print("PDF generation error:", error)
            // если что-то пошло не так — просто остаёмся в визарде
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
                    .foregroundColor(.black)
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
                        .fill(Color.black)
                        .frame(width: geometry.size.width * (Double(step) / 4.0), height: 6)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
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
                        .fill(stepNumber <= step ? Color.black : Color.secondary.opacity(0.3))
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
                .fill(n <= step ? Color.black : Color.secondary.opacity(0.3))
                .frame(width: 20, height: 20)
                .shadow(color: n == step ? .black.opacity(0.2) : .clear, radius: 4, x: 0, y: 2)
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
        case 2: return "Client Details"
        case 3: return "Payment Methods"
        case 4: return "Invoice Items"
        default: return "Unknown Step"
        }
    }
    
    private var stepDescription: String {
        switch step {
        case 1: return "Set up your business details"
        case 2: return "Add client information"
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
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
    }
}

struct StepCompanyInfoView: View {
    @EnvironmentObject private var app: AppState
    @ObservedObject var vm: InvoiceWizardVM
    var next: () -> Void
    var prev: (() -> Void)?
    @State private var company = Company()

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
                                            .fill(Color.blue.opacity(0.1))
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
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
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
                                .fill(Color.secondary.opacity(0.1))
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
    }
}

// MARK: - Step 2: Client

struct StepClientInfoView: View {
    @EnvironmentObject private var app: AppState
    @ObservedObject var vm: InvoiceWizardVM
    var next: () -> Void
    var prev: () -> Void

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
                            Text("Select Customer")
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
                        .disabled(vm.customer == nil)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    private func initials(for name: String) -> String {
        name.split(separator: " ").compactMap { $0.first }.prefix(2).map(String.init).joined()
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
                // если мы в режиме saved — добавляем в сохранённые и сразу отмечаем выбранным
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

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Add Products/Services
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Add Products/Services", systemImage: "shippingbox")
                            Spacer()
                            Button("+ Add New") { /* TODO */ }
                        }

                        HStack(spacing: 8) {
                            TextField("Search products/services…", text: $search).fieldStyle()
                            Menu {
                                Picker("Category", selection: $category) {
                                    Text("All").tag("All")
                                    ForEach(Array(Set(app.products.map { $0.category })).sorted(), id: \.self) { c in
                                        Text(c).tag(c)
                                    }
                                }
                            } label: {
                                HStack { Text(category); Image(systemName: "chevron.down") }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1)))
                            }
                        }

                        ForEach(filteredProducts) { p in
                            WizardProductRow(p: p) { add(product: p) }
                        }
                    }
                    .padding(4)
                }

                // Invoice Items
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Invoice Items").font(.headline)
                            Spacer()
                            Button("+ Add Custom Item") { addCustom() }
                        }
                        ForEach(vm.items) { item in
                            ItemEditor(item: binding(for: item))
                        }
                        HStack {
                            Text("Subtotal")
                            Spacer()
                            Text(Money.fmt(vm.subtotal, code: vm.currency)).bold()
                        }
                    }
                    .padding(4)
                }

                HStack {
                    Button("Previous", action: prev).buttonStyle(.bordered)
                    Spacer()
                    Button("Generate", action: onSaved)
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.items.isEmpty)
                }
            }
            .padding()
        }
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
    private func addCustom() {
        vm.items.append(LineItem(description: "", quantity: 1, rate: 0))
    }

    private func binding(for item: LineItem) -> Binding<LineItem> {
        guard let idx = vm.items.firstIndex(where: { $0.id == item.id }) else {
            return .constant(item)
        }
        return $vm.items[idx]
    }
}

// MARK: - Local product row for wizard

private struct WizardProductRow: View {
    let p: Product
    let onAdd: () -> Void
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack { Text(p.name).bold(); Tag(text: p.category) }
                if !p.details.isEmpty {
                    Text(p.details).font(.caption).foregroundStyle(.secondary)
                }
                Text("\(Money.fmt(p.rate, code: Locale.current.currency?.identifier ?? "USD")) / hour")
                    .font(.caption)
            }
            Spacer()
            Button(action: onAdd) {
                HStack { Image(systemName: "cart.badge.plus"); Text("Add") }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.black))
                    .foregroundStyle(.white)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.15)))
    }
}

// MARK: - Details (read-only)

struct InvoiceDetailsView: View {
    let invoice: Invoice
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(invoice.company.name).font(.title2).bold()
                    Spacer()
                    StatusChip(status: invoice.status)
                }
                Text(invoice.customer.name).font(.headline)
                HStack {
                    Text("Issue:")
                    Text(Dates.display.string(from: invoice.issueDate))
                    Spacer()
                    Text("Due:")
                    Text(Dates.display.string(from: invoice.dueDate ?? invoice.issueDate))
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(invoice.items) { it in
                        HStack {
                            Text(it.description)
                            Spacer()
                            Text(Money.fmt(it.total, code: invoice.currency))
                        }
                        Divider()
                    }
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(Money.fmt(invoice.subtotal, code: invoice.currency)).bold()
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.secondary.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.12)))
            }
            .padding()
        }
        .navigationTitle("Invoice \(invoice.number)")
    }
}

// MARK: - Reusable UI

extension View {
    func fieldStyle() -> some View {
        self.padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
    }
}

struct ModernTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var textInputAutocapitalization: TextInputAutocapitalization = .sentences
    
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
                    .fill(Color.secondary.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                text.isEmpty ? Color.clear : Color.blue.opacity(0.3),
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
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.blue.opacity(0.3) : Color.clear,
                                lineWidth: 2
                            )
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

struct ItemEditor: View {
    @Binding var item: LineItem
    var body: some View {
        VStack(spacing: 8) {
            TextField("Description", text: $item.description).fieldStyle()
            HStack {
                DecimalField(title: "Quantity", value: $item.quantity)
                DecimalField(title: "Rate", value: $item.rate)
                Spacer()
                Text(Money.fmt(item.total, code: Locale.current.currency?.identifier ?? "USD")).bold()
            }
            .frame(height: 44)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.15)))
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

// MARK: - ShareSheet wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var completion: UIActivityViewController.CompletionWithItemsHandler? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        vc.completionWithItemsHandler = completion
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Custom Payment Components

struct PaymentChoiceCard: View {
    let choice: InvoiceWizardVM.PaymentChoice
    let isSelected: Bool
    let onTap: () -> Void
    
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
                          LinearGradient(colors: [Color.secondary.opacity(0.05)], startPoint: .leading, endPoint: .trailing)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.clear : Color.secondary.opacity(0.2),
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
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? Color.blue.opacity(0.3) : Color.secondary.opacity(0.1),
                            lineWidth: 1
                        )
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
