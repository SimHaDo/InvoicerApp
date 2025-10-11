//
//  InvoiceCreationFlow.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 10/10/25.
//

import SwiftUI
import PhotosUI

// MARK: - Invoice Creation Flow

struct InvoiceCreationFlow: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var navigationPath = NavigationPath()
    @StateObject private var vm = InvoiceWizardVM()
    
    let onClose: (() -> Void)?
    
    init(onClose: (() -> Void)? = nil) {
        self.onClose = onClose
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            // Начальный экран
            Group {
                if app.company == nil {
                    // Если компания не настроена, начинаем с настройки компании
                    CompanySetupView()
                        .environmentObject(app)
                } else {
                    // Если компания настроена, начинаем с выбора шаблона
                    TemplateSelectionView(onClose: { 
                        // Закрываем флоу
                        onClose?()
                    }, navigationPath: $navigationPath)
                        .environmentObject(app)
                }
            }
                .navigationDestination(for: InvoiceCreationStep.self) { step in
                    switch step {
                    case .templateSelection:
                        TemplateSelectionView(onClose: { 
                            // Закрываем флоу
                            onClose?()
                        }, navigationPath: $navigationPath)
                            .environmentObject(app)
                            
                    case .colorScheme(let template):
                        ColorSchemePickerView(
                            selectedTemplate: template,
                            onColorSelected: { selectedTheme in
                                print("🎨 Color selected: \(selectedTheme.name)")
                                let completeTemplate = CompleteInvoiceTemplate(template: template, theme: selectedTheme)
                                app.selectedTemplate = completeTemplate
                                print("📄 Template set: \(completeTemplate.name) with theme: \(completeTemplate.theme.name)")
                                // Переходим к первому шагу создания инвойса
                                navigationPath.append(InvoiceCreationStep.companyInfo)
                                print("🚀 Navigating to company info...")
                            },
                            onClose: {
                                // Закрываем флоу
                                onClose?()
                            }
                        )
                        
                    case .companyInfo:
                        InvoiceStepView(vm: vm, step: 1, navigationPath: $navigationPath, onClose: onClose)
                            .environmentObject(app)
                        
                    case .clientInfo:
                        InvoiceStepView(vm: vm, step: 2, navigationPath: $navigationPath, onClose: onClose)
                            .environmentObject(app)
                        
                    case .paymentDetails:
                        InvoiceStepView(vm: vm, step: 3, navigationPath: $navigationPath, onClose: onClose)
                            .environmentObject(app)
                        
                    case .itemsPricing:
                        InvoiceStepView(vm: vm, step: 4, navigationPath: $navigationPath, onClose: onClose)
                            .environmentObject(app)
                    }
                }
            .navigationTitle("Create Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .onAppear {
                configureFromAppState()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // Показываем кнопку Back только если есть элементы в навигационном стэке
                    if navigationPath.count > 0 {
                        Button("Back") {
                            navigationPath.removeLast()
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { 
                        // Закрываем флоу
                        onClose?()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onChange(of: app.company) { company in
                // Если компания была настроена, переходим к выбору шаблона
                if company != nil {
                    navigationPath.append(InvoiceCreationStep.templateSelection)
                }
            }
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
        if vm.items.isEmpty, let pre = app.preselectedItems {
            vm.items = pre
            app.preselectedItems = nil
            if vm.step < 4 { vm.step = 4 }
            jumped = true
        }
        if !jumped, vm.customer != nil, vm.step < 2 {
            vm.step = 2
        }
    }
}

// MARK: - Invoice Creation Steps

enum InvoiceCreationStep: Hashable {
    case templateSelection
    case colorScheme(InvoiceTemplateDescriptor)
    case companyInfo
    case clientInfo
    case paymentDetails
    case itemsPricing
}

// MARK: - Template Selection View

struct TemplateSelectionView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.colorScheme) private var scheme
    @ObservedObject private var permissionManager = PermissionManager.shared
    
    let onClose: (() -> Void)?
    let navigationPath: Binding<NavigationPath>
    
    init(onClose: (() -> Void)? = nil, navigationPath: Binding<NavigationPath>) {
        self.onClose = onClose
        self.navigationPath = navigationPath
    }
    
    @State private var photoItem: PhotosPickerItem?
    @State private var showLogoEditAlert = false
    @State private var showPhotosPicker = false
    @State private var showFilePicker = false
    @State private var showPermissionAlert = false
    @State private var permissionType: PermissionType = .photoLibrary
    @State private var selectedCategories: Set<TemplateCategory> = []
    @State private var selectedDesigns: Set<TemplateDesign> = []
    @State private var searchText = ""
    @State private var showContent = false
    @State private var pulseAnimation = false
    @State private var shimmerOffset: CGFloat = -1
    @State private var floatingElements: [FloatingElement] = []
    @State private var showPaywall = false
    
    private let templates = TemplateCatalog.all
    
    var body: some View {
        ZStack {
            backgroundView
            floatingElementsView
            contentView
        }
        .navigationTitle("Choose Template")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            showContent = true
            pulseAnimation = true
            startShimmerAnimation()
            createFloatingElements()
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $photoItem, matching: .images)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert("Permission Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This app needs access to your photo library to add logos to invoices.")
        }
        .onChange(of: photoItem) { newItem in
            handlePhotoSelection(newItem)
        }
    }
    
    var floatingElementsView: some View {
        ForEach(floatingElements) { element in
            Circle()
                .fill(
                    scheme == .dark ? 
                    Color.blue.opacity(0.08) : 
                    Color.primary.opacity(0.05)
                )
                .frame(width: 40, height: 40)
                .scaleEffect(element.scale)
                .opacity(element.opacity)
                .rotationEffect(.degrees(element.rotation))
                .position(x: element.x, y: element.y)
                .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: element.scale)
        }
    }
    
    var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerLogo
                    .offset(y: showContent ? 0 : -20)
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1), value: showContent)
                
                searchAndFilters
                    .offset(y: showContent ? 0 : -15)
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)
                
                templatesGrid
                    .offset(y: showContent ? 0 : 20)
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Subviews
    
    var backgroundView: some View {
        LinearGradient(
            colors: [
                scheme == .dark ? Color(red: 0.05, green: 0.05, blue: 0.08) : Color.white,
                scheme == .dark ? Color(red: 0.08, green: 0.08, blue: 0.12) : Color.gray.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    var headerLogo: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Invoice Templates")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Choose a template for your invoice")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .if(scheme == .dark) { view in
                    view.colorInvert()
                }
                .shadow(
                    color: scheme == .dark ? UI.darkAccent.opacity(0.4) : .black.opacity(0.2), 
                    radius: 8, 
                    y: 4
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            scheme == .dark ? UI.darkAccent.opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                )
        }
        .padding(.horizontal, isLargeScreen ? 40 : 20)
    }
    
    var searchAndFilters: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search templates...", text: $searchText)
                    .autocorrectionDisabled()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        scheme == .dark ? 
                        Color(red: 0.12, green: 0.12, blue: 0.16) : 
                        Color(.systemGray6)
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
            
            // Category filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availableCategories, id: \.self) { category in
                        ModernFilterChip(
                            title: category.rawValue,
                            icon: "tag.fill",
                            isSelected: selectedCategories.contains(category),
                            action: {
                                if selectedCategories.contains(category) {
                                    selectedCategories.remove(category)
                                } else {
                                    selectedCategories.insert(category)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, isLargeScreen ? 40 : 20)
            }
        }
        .padding(.horizontal, isLargeScreen ? 40 : 20)
    }
    
    var templatesGrid: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: isLargeScreen ? 300 : 280), spacing: 16)
        ], spacing: 16) {
            ForEach(filteredTemplates, id: \.id) { template in
                TemplateCard(descriptor: template) {
                    // Переходим к выбору цветовой схемы через append
                    print("🎨 Template selected: \(template.name)")
                    navigationPath.wrappedValue.append(InvoiceCreationStep.colorScheme(template))
                    print("🚀 Navigating to color scheme...")
                }
            }
        }
        .padding(.horizontal, isLargeScreen ? 40 : 20)
    }
    
    // MARK: - Helper Methods
    
    func startShimmerAnimation() {
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            shimmerOffset = 1
        }
    }
    
    func createFloatingElements() {
        floatingElements = (0..<8).map { _ in
            FloatingElement(
                x: Double.random(in: 50...350),
                y: Double.random(in: 100...700),
                opacity: Double.random(in: 0.1...0.3),
                scale: Double.random(in: 0.8...1.2),
                rotation: Double.random(in: 0...360)
            )
        }
    }
    
    func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            loadImageFromFile(url)
        case .failure(let error):
            print("File selection error: \(error)")
        }
    }
    
    func loadImageFromFile(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            if UIImage(data: data) != nil {
                Task { @MainActor in
                    app.logoData = data
                }
            }
        } catch {
            print("Error loading image: \(error)")
        }
    }
    
    func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    app.logoData = data
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var isLargeScreen: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || ProcessInfo.processInfo.isiOSAppOnMac
    }
    
    // Only show categories that have templates
    var availableCategories: [TemplateCategory] {
        let categoriesWithTemplates = Set(templates.map { $0.category })
        return TemplateCategory.allCases.filter { categoriesWithTemplates.contains($0) }
    }
    
    var filteredTemplates: [InvoiceTemplateDescriptor] {
        var filtered = templates
        
        if !selectedCategories.isEmpty {
            filtered = filtered.filter { selectedCategories.contains($0.category) }
        }
        
        if !selectedDesigns.isEmpty {
            filtered = filtered.filter { selectedDesigns.contains($0.design) }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText) ||
                $0.design.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
}


// MARK: - Invoice Step View

struct InvoiceStepView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: InvoiceWizardVM
    
    let step: Int
    let navigationPath: Binding<NavigationPath>
    let onClose: (() -> Void)?
    
    // Для ShareSheet
    @State private var shareURL: URL?
    @State private var showShare = false
    @State private var shouldDismissAfterShare = false
    
    var body: some View {
        VStack(spacing: 0) {
            StepHeader(step: vm.step)
            stepContent
        }
        .navigationTitle("Create Invoice")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { 
                    // Закрываем флоу
                    onClose?()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            vm.step = step
        }
        .sheet(isPresented: $showShare) {
            if let url = shareURL {
                ShareSheet(items: [url])
                    .onDisappear {
                        if shouldDismissAfterShare {
                            // Закрываем флоу
                            onClose?()
                        }
                    }
            }
        }
    }
    
    @ViewBuilder private var stepContent: some View {
        switch step {
        case 1:
            StepCompanyInfoView(vm: vm, next: { 
                print("🚀 Moving to client info...")
                navigationPath.wrappedValue.append(InvoiceCreationStep.clientInfo)
            }, prev: {
                print("🚀 Moving back to template selection...")
                navigationPath.wrappedValue.removeLast()
            })
        case 2:
            StepClientInfoView(vm: vm, next: { 
                print("🚀 Moving to payment details...")
                navigationPath.wrappedValue.append(InvoiceCreationStep.paymentDetails)
            }, prev: { 
                print("🚀 Moving back to company info...")
                navigationPath.wrappedValue.removeLast()
            })
        case 3:
            StepPaymentDetailsView(vm: vm, prev: { 
                print("🚀 Moving back to client info...")
                navigationPath.wrappedValue.removeLast()
            }, next: { 
                print("🚀 Moving to items pricing...")
                navigationPath.wrappedValue.append(InvoiceCreationStep.itemsPricing)
            })
        case 4:
            StepItemsPricingView(vm: vm, prev: { 
                print("🚀 Moving back to payment details...")
                navigationPath.wrappedValue.removeLast()
            }, onSaved: {
                print("✅ Generating PDF and showing ShareSheet...")
                saveInvoice()
            })
        default:
            EmptyView()
        }
    }
    
    
    private func saveInvoice() {
        print("🔍 Starting saveInvoice...")
        print("🔍 Company: \(app.company?.name ?? "nil")")
        print("🔍 Customer: \(vm.customer?.name ?? "nil")")
        print("🔍 Items count: \(vm.items.count)")
        print("🔍 Selected template: \(app.selectedTemplate.name)")
        
        guard let company = app.company,
              let customer = vm.customer,
              !vm.items.isEmpty
        else { 
            print("❌ Guard failed - missing required data")
            return 
        }

        print("✅ All required data present, creating invoice...")

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

        print("✅ Invoice created, adding to app.invoices...")
        app.invoices.append(invoice)

        print("🔄 Starting PDF generation...")
        do {
            let url = try PDFService.shared.generatePDF(
                invoice: invoice,
                company: company,
                customer: customer,
                currencyCode: vm.currency,
                template: app.selectedTemplate,
                logo: vm.includeLogo ? app.logoImage : nil
            )
            print("✅ PDF generated successfully at: \(url)")
            shareURL = url
            shouldDismissAfterShare = true
            showShare = true
            print("✅ ShareSheet should now be visible")
        } catch {
            print("❌ PDF generation error:", error)
            // если что-то пошло не так — просто остаёмся в визарде
        }
    }
    
    private func resolvedPaymentMethods() -> [PaymentMethod] {
        switch vm.paymentChoice {
        case .saved:
            return app.paymentMethods.filter { vm.selectedSaved.contains($0.id) }
        case .custom:
            return vm.customMethods
        case .none:
            return []
        }
    }
}

// MARK: - FloatingElement

private struct FloatingElement: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var opacity: Double
    var scale: Double
    var rotation: Double
}
