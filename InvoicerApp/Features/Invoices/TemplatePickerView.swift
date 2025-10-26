//
//  TemplatePickerView.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/29/25.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct TemplatePickerView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @ObservedObject private var permissionManager = PermissionManager.shared

    let onSelect: (CompleteInvoiceTemplate) -> Void
    init(onSelect: @escaping (CompleteInvoiceTemplate) -> Void = { _ in }) {
        self.onSelect = onSelect
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
    @State private var navigationPath = NavigationPath()
    @State private var selectedTemplateForColor: InvoiceTemplateDescriptor?
    
    private let templates = TemplateCatalog.all
    
    private var isLargeScreen: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || ProcessInfo.processInfo.isiOSAppOnMac
    }
    
    // Only show categories that have templates
    private var availableCategories: [TemplateCategory] {
        let categoriesWithTemplates = Set(templates.map { $0.category })
        return TemplateCategory.allCases.filter { categoriesWithTemplates.contains($0) }
    }
    
    private var filteredTemplates: [InvoiceTemplateDescriptor] {
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
    
    private var iPadLayout: some View {
        NavigationStack(path: $navigationPath) {
            contentView
                .navigationTitle("Choose Template")
                .navigationBarTitleDisplayMode(.large)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        // Show Back button only if there are elements in navigation stack
                        if navigationPath.count > 0 {
                            Button("Back") {
                                navigationPath.removeLast()
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { 
                            // Completely clear stack and close flow
                            navigationPath = NavigationPath()
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .navigationDestination(for: InvoiceTemplateDescriptor.self) { template in
                    ColorSchemePickerView(
                        selectedTemplate: template,
                        onColorSelected: { selectedTheme in
                            let completeTemplate = CompleteInvoiceTemplate(template: template, theme: selectedTheme)
                            app.selectedTemplate = completeTemplate
                            onSelect(completeTemplate)
                        },
                        onClose: {
                            // Completely clear stack and close flow
                            navigationPath = NavigationPath()
                            dismiss()
                        }
                    )
                }
        }
    }
    
    private var iPhoneLayout: some View {
        NavigationStack(path: $navigationPath) {
            contentView
                .navigationTitle("Choose Template")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        // Show Back button only if there are elements in navigation stack
                        if navigationPath.count > 0 {
                            Button("Back") {
                                navigationPath.removeLast()
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { 
                            // Completely clear stack and close flow
                            navigationPath = NavigationPath()
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .navigationDestination(for: InvoiceTemplateDescriptor.self) { template in
                    ColorSchemePickerView(
                        selectedTemplate: template,
                        onColorSelected: { selectedTheme in
                            let completeTemplate = CompleteInvoiceTemplate(template: template, theme: selectedTheme)
                            app.selectedTemplate = completeTemplate
                            onSelect(completeTemplate)
                        },
                        onClose: {
                            // Completely clear stack and close flow
                            navigationPath = NavigationPath()
                            dismiss()
                        }
                    )
                }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > 768 {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .sheet(isPresented: $showPaywall) {
            // PaywallScreen would go here
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $photoItem, matching: .images)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.image, .jpeg, .png, .gif, .bmp, .tiff],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                do {
                    let data = try Data(contentsOf: url)
                    app.logoData = data // This will automatically save only one logo
                } catch {
                    print("Error loading file: \(error)")
                }
            case .failure(let error):
                print("File picker error: \(error)")
            }
        }
        .onChange(of: photoItem) { new in
            guard let new else { return }
            Task {
                if let data = try? await new.loadTransferable(type: Data.self) {
                    app.logoData = data
                }
            }
        }
        .overlay(
            // Custom Logo Edit Alert
            Group {
                if showLogoEditAlert {
                    CustomLogoEditAlert(
                        isPresented: $showLogoEditAlert,
                        onRemove: { 
                            app.logoData = nil
                            showLogoEditAlert = false
                        },
                        onChange: {
                            showLogoEditAlert = false
                            requestPhotoPermission()
                        },
                        onFileSelect: {
                            showLogoEditAlert = false
                            // File picker doesn't need permission
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showFilePicker = true
                            }
                        }
                    )
                }
            }
        )
        .overlay(
            // Permission Alert
            Group {
                if showPermissionAlert {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea(.all)
                            .onTapGesture {
                                showPermissionAlert = false
                            }
                        
                        PermissionAlert(
                            permissionType: permissionType,
                            isPresented: $showPermissionAlert,
                            onSettings: {
                                permissionManager.openAppSettings()
                            },
                            onCancel: {
                                showPermissionAlert = false
                            }
                        )
                    }
                    .zIndex(1002)
                }
            }
        )
        .onAppear {
            // Set showContent only once on first appearance
            if !showContent {
                showContent = true
            }
            pulseAnimation = true
            startShimmerAnimation()
            createFloatingElements()
        }
    }
    
    private var contentView: some View {
        ZStack {
            // Animated background
            backgroundView
            
            // Floating elements
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
            
            VStack(spacing: 0) {
                // Header with logo
                headerLogo
                
                // Search and Filters
                searchAndFilters
                
                // Templates Grid
                templatesGrid
            }
        }
    }
    
    // MARK: - Header Logo
    
    @ViewBuilder private var headerLogo: some View {
        VStack(spacing: 8) {
        HStack(spacing: 12) {
            if let img = app.logoImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .if(scheme == .dark) { view in
                        view.colorInvert()
                    }
                    .shadow(
                        color: scheme == .dark ? UI.darkAccent.opacity(0.4) : .black.opacity(0.2), 
                        radius: 8, 
                        y: 4
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                scheme == .dark ? UI.darkAccent.opacity(0.3) : Color.clear,
                                lineWidth: 1
                            )
                    )
            } else {
                    RoundedRectangle(cornerRadius: 12).fill(
                        scheme == .dark ? 
                        Color(red: 0.12, green: 0.12, blue: 0.16) : 
                        Color.secondary.opacity(0.08)
                    )
                    .overlay(
                        VStack(spacing: 4) {
                            Image(systemName: "building.2")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(
                                    scheme == .dark ? 
                                    Color.blue.opacity(0.7) : 
                                    .secondary
                                )
                            Text("Logo")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(
                                    scheme == .dark ? 
                                    Color.blue.opacity(0.7) : 
                                    .secondary
                                )
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                scheme == .dark ? 
                                Color.white.opacity(0.4) : 
                                Color.clear,
                                lineWidth: 2
                            )
                    )
                    .frame(width: 56, height: 56)
            }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Company Logo")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Add your logo to personalize invoices")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Modern Edit Button
                Button(action: { showLogoEditAlert = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Edit")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black)
                            
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.1), Color.clear, Color.white.opacity(0.1)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(x: showLogoEditAlert ? 50 : -50)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: showLogoEditAlert)
                        }
                    )
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .scaleEffect(showLogoEditAlert ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showLogoEditAlert)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
        }
    }
    
    // MARK: - Search and Filters
    
    private var searchAndFilters: some View {
        VStack(spacing: 6) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(scheme == .dark ? UI.darkSecondaryText : .secondary)
                    
                    TextField("Search templates...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(scheme == .dark ? UI.darkText : .primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(scheme == .dark ? UI.darkSecondaryBackground : Color.primary.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(scheme == .dark ? UI.darkStroke : Color.primary.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal, isLargeScreen ? 40 : 20)
            
                // Reset Button
                if !selectedCategories.isEmpty || !selectedDesigns.isEmpty {
                    HStack {
                        Button(action: resetFilters) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12, weight: .medium))
                                Text("Reset Filters")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                            .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, isLargeScreen ? 40 : 20)
                }
            
                // Combined Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // All Categories Filter
                        ModernFilterChip(
                            title: "All",
                            icon: "star.fill",
                            isSelected: selectedCategories.isEmpty && selectedDesigns.isEmpty,
                            action: { 
                                selectedCategories.removeAll()
                                selectedDesigns.removeAll()
                            }
                        )
                        
                        // Category Filters
                        ForEach(availableCategories, id: \.self) { category in
                            ModernFilterChip(
                                title: category.displayName,
                                icon: categoryIcon(for: category),
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
                        
                        // Design Filters
                        ForEach(TemplateDesign.allCases, id: \.self) { design in
                            ModernFilterChip(
                                title: design.rawValue.capitalized,
                                icon: designIcon(for: design),
                                isSelected: selectedDesigns.contains(design),
                                action: { 
                                    if selectedDesigns.contains(design) {
                                        selectedDesigns.remove(design)
                                    } else {
                                        selectedDesigns.insert(design)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, isLargeScreen ? 20 : 16)
                }
        }
        .padding(.horizontal, isLargeScreen ? 20 : 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Templates Grid
    
    private var templatesGrid: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVGrid(columns: gridColumns(for: geometry.size.width), spacing: 12) {
                    ForEach(filteredTemplates) { template in
                        TemplateCard(descriptor: template) {
                            if template.isPremium && !app.isPremium {
                                showPaywall = true
                            } else {
                                navigationPath.append(template)
                            }
                        }
                    }
                }
                .padding(.horizontal, isLargeScreen ? 40 : 20)
                .padding(.bottom, 16)
            }
        }
    }
    
    private func gridColumns(for width: CGFloat) -> [GridItem] {
        if width > 1200 {
            // Large iPad - 4 columns
            return [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]
        } else if width > 768 {
            // iPad - 3 columns
            return [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]
        } else {
            // iPhone - 2 columns
            return [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ]
        }
    }
    
    // MARK: - Helper Functions
    
    private func resetFilters() {
        selectedCategories.removeAll()
        selectedDesigns.removeAll()
    }
    
    private func requestPhotoPermission() {
        Task {
            let status = await permissionManager.requestPhotoLibraryPermission()
            await MainActor.run {
                if status == .granted {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showPhotosPicker = true
                    }
                } else {
                    // If permission not granted, show alert with settings redirect
                    permissionType = .photoLibrary
                    showPermissionAlert = true
                }
            }
        }
    }
}

// MARK: - Template Card

struct TemplateCard: View {
    let descriptor: InvoiceTemplateDescriptor
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Template Preview
                ZStack {
                    TemplateCardPreview(descriptor: descriptor)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    scheme == .dark ? 
                                    Color.blue.opacity(0.2) : 
                                    Color.primary.opacity(0.1), 
                                    lineWidth: 1
                                )
                        )
                    
                    // Premium Badge
                    if descriptor.isPremium {
                        VStack {
                            HStack {
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 10, weight: .semibold))
                                    Text("Premium")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.yellow)
                                )
                                .foregroundColor(.black)
            }
            Spacer()
                        }
                        .padding(8)
                    }
                }
                
                // Template Info
                VStack(spacing: 4) {
                    Text(descriptor.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(descriptor.description)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    // Category and Style Badges
                    HStack(spacing: 6) {
                        Text(descriptor.category.rawValue)
                            .font(.system(size: 9, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue.opacity(0.1))
                            )
                            .foregroundColor(.blue)
                        
                        Text(descriptor.design.rawValue.capitalized)
                            .font(.system(size: 9, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.primary.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Filter Chip

// MARK: - Modern Filter Chip

struct ModernFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    @Environment(\.colorScheme) private var scheme
    
    // Get category-specific colors
    private var categoryColors: (primary: Color, secondary: Color, accent: Color) {
        switch title {
        case "Business":
            return (Color.blue, Color.blue.opacity(0.8), Color.blue.opacity(0.3))
        case "Creative":
            return (Color.purple, Color.purple.opacity(0.8), Color.purple.opacity(0.3))
        case "Technology":
            return (Color.green, Color.green.opacity(0.8), Color.green.opacity(0.3))
        case "All":
            return (Color.orange, Color.orange.opacity(0.8), Color.orange.opacity(0.3))
        default:
            return (Color.gray, Color.gray.opacity(0.8), Color.gray.opacity(0.3))
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                action()
            }
        }) {
            HStack(spacing: 8) {
                // Icon with background circle
                ZStack {
                    Circle()
                        .fill(
                            isSelected ? 
                            (scheme == .dark ? categoryColors.primary : .white) :
                            (scheme == .dark ? categoryColors.accent : categoryColors.primary.opacity(0.1))
                        )
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(
                            isSelected ? 
                            (scheme == .dark ? .white : categoryColors.primary) :
                            (scheme == .dark ? categoryColors.primary : categoryColors.primary)
                        )
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(
                        isSelected ? 
                        (scheme == .dark ? .white : .white) : 
                        (scheme == .dark ? .primary : .primary)
                    )
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    // Main background with gradient
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            isSelected ? 
                            (scheme == .dark ? 
                                AnyShapeStyle(LinearGradient(
                                    colors: [categoryColors.primary, categoryColors.secondary], 
                                    startPoint: .topLeading, 
                                    endPoint: .bottomTrailing
                                )) :
                                AnyShapeStyle(LinearGradient(
                                    colors: [categoryColors.primary, categoryColors.secondary], 
                                    startPoint: .topLeading, 
                                    endPoint: .bottomTrailing
                                ))
                            ) : 
                            (scheme == .dark ? 
                                AnyShapeStyle(LinearGradient(
                                    colors: [Color(red: 0.15, green: 0.15, blue: 0.20), Color(red: 0.12, green: 0.12, blue: 0.16)], 
                                    startPoint: .topLeading, 
                                    endPoint: .bottomTrailing
                                )) : 
                                AnyShapeStyle(LinearGradient(
                                    colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)], 
                                    startPoint: .topLeading, 
                                    endPoint: .bottomTrailing
                                ))
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(
                                    isSelected ? Color.clear : 
                                    (scheme == .dark ? categoryColors.primary.opacity(0.3) : categoryColors.primary.opacity(0.2)), 
                                    lineWidth: 1.5
                                )
                        )
                    
                    // Subtle inner glow for selected state
                    if isSelected {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.1), 
                                        Color.clear, 
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            )
            .scaleEffect(isSelected ? 1.08 : (isPressed ? 0.95 : 1.0))
            .shadow(
                color: isSelected ? 
                (scheme == .dark ? categoryColors.primary.opacity(0.4) : categoryColors.primary.opacity(0.3)) : 
                .clear,
                radius: isSelected ? 12 : 0,
                x: 0,
                y: isSelected ? 6 : 0
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Helper Functions

private func categoryIcon(for category: TemplateCategory) -> String {
    switch category {
    case .business: return "building.2.crop.circle.fill"
    case .creative: return "paintpalette.fill"
    case .tech: return "cpu.fill"
    }
}

private func designIcon(for design: TemplateDesign) -> String {
    switch design {
    case .modernClean: return "sparkles"
    case .professionalMinimal: return "minus.circle.fill"
    case .corporateFormal: return "building.2.fill"
    case .executiveLuxury: return "crown.fill"
    case .businessClassic: return "book.fill"
    case .enterpriseBold: return "building.fill"
    case .consultingElegant: return "hand.raised.fill"
    case .financialStructured: return "chart.bar.fill"
    case .legalTraditional: return "scale.3d"
    case .healthcareModern: return "cross.fill"
    case .realEstateWarm: return "house.fill"
    case .insuranceTrust: return "shield.fill"
    case .bankingSecure: return "lock.fill"
    case .accountingDetailed: return "doc.text.fill"
    case .consultingProfessional: return "person.fill"
    case .creativeVibrant: return "paintbrush.fill"
    case .artisticBold: return "paintpalette.fill"
    case .designStudio: return "pencil.and.outline"
    case .fashionElegant: return "tshirt.fill"
    case .photographyClean: return "camera.fill"
    case .techModern: return "laptopcomputer"
    default: return "doc.fill"
    }
}

// MARK: - Enhanced Template Card Preview

struct TemplateCardPreview: View {
    let descriptor: InvoiceTemplateDescriptor
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        // Use default colors for preview since theme will be selected later
        let primary = Color.blue
        let secondary = Color.blue.opacity(0.7)
        
        RoundedRectangle(cornerRadius: 12)
            .fill(
                scheme == .dark ? 
                Color(red: 0.12, green: 0.12, blue: 0.16) : 
                Color(.secondarySystemBackground).opacity(0.6)
            )
            .overlay(
                VStack(spacing: 6) {
                    // Template-specific preview based on design
                    switch descriptor.design {
                    case .geometricAbstract:
                        geometricAbstractPreview(primary: primary, secondary: secondary)
                    case .techModern:
                        techModernPreview(primary: primary, secondary: secondary)
                    case .vintageRetro:
                        vintageRetroPreview(primary: primary, secondary: secondary)
                    case .businessClassic:
                        businessClassicPreview(primary: primary, secondary: secondary)
                    case .modernClean:
                        minimalistCleanPreview(primary: primary, secondary: secondary)
                    case .creativeVibrant:
                        creativeArtisticPreview(primary: primary, secondary: secondary)
                    case .professionalMinimal:
                        minimalistCleanPreview(primary: primary, secondary: secondary)
                    case .corporateFormal:
                        businessClassicPreview(primary: primary, secondary: secondary)
                    case .executiveLuxury:
                        businessClassicPreview(primary: primary, secondary: secondary)
                    case .enterpriseBold:
                        techModernPreview(primary: primary, secondary: secondary)
                    case .consultingElegant:
                        businessClassicPreview(primary: primary, secondary: secondary)
                    case .financialStructured:
                        businessClassicPreview(primary: primary, secondary: secondary)
                    case .legalTraditional:
                        businessClassicPreview(primary: primary, secondary: secondary)
                    case .healthcareModern:
                        minimalistCleanPreview(primary: primary, secondary: secondary)
                    case .realEstateWarm:
                        vintageRetroPreview(primary: primary, secondary: secondary)
                    case .insuranceTrust:
                        businessClassicPreview(primary: primary, secondary: secondary)
                    case .bankingSecure:
                        businessClassicPreview(primary: primary, secondary: secondary)
                    case .accountingDetailed:
                        businessClassicPreview(primary: primary, secondary: secondary)
                    case .consultingProfessional:
                        businessClassicPreview(primary: primary, secondary: secondary)
                    case .artisticBold:
                        creativeArtisticPreview(primary: primary, secondary: secondary)
                    case .designStudio:
                        creativeArtisticPreview(primary: primary, secondary: secondary)
                    case .fashionElegant:
                        creativeArtisticPreview(primary: primary, secondary: secondary)
                    case .photographyClean:
                        minimalistCleanPreview(primary: primary, secondary: secondary)
                    }
                    
                    Spacer(minLength: 2)
                }
                .padding(8)
            )
    }
    
    // MARK: - Template-Specific Previews
    
    @ViewBuilder
    private func geometricAbstractPreview(primary: Color, secondary: Color) -> some View {
        VStack(spacing: 4) {
            // Geometric header with triangles and shapes
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 3) {
                        Triangle()
                            .fill(primary)
                            .frame(width: 8, height: 8)
                        Triangle()
                            .fill(secondary)
                            .frame(width: 6, height: 6)
                        Triangle()
                            .fill(primary.opacity(0.7))
                            .frame(width: 7, height: 7)
                    }
                    Rect(.label, w: 45, h: 6)
                }
                Spacer()
                Circle()
                    .fill(primary.opacity(0.3))
                    .frame(width: 20, height: 20)
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
            
            // Company info with geometric elements
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Rect(.label, w: 60, h: 6)
                    Rect(.secondaryLabel, w: 40, h: 4)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Rect(.secondaryLabel, w: 50, h: 4)
                    Rect(.secondaryLabel, w: 45, h: 4)
                }
            }
            .padding(.horizontal, 8)
            
            // Items with geometric table
            VStack(spacing: 2) {
                HStack {
                    Rect(.label, w: 70, h: 5)
                    Spacer()
                    Rect(.label, w: 20, h: 5)
                    Rect(.label, w: 25, h: 5)
                }
                .padding(.horizontal, 6)
                .background(primary.opacity(0.1))
                .cornerRadius(3)
                
                ForEach(0..<2) { _ in
                    HStack {
                        Rect(.label, w: 65, h: 4)
                        Spacer()
                        Rect(.label, w: 18, h: 4)
                        Rect(.label, w: 22, h: 4)
                    }
                    .padding(.horizontal, 6)
                }
            }
            
            // Total with geometric accent
            HStack {
                Spacer()
                HStack(spacing: 3) {
                    Triangle()
                        .fill(primary)
                        .frame(width: 6, height: 6)
                    Rect(.label, w: 35, h: 6)
                }
            }
            .padding(.horizontal, 8)
        }
    }
    
    @ViewBuilder
    private func techModernPreview(primary: Color, secondary: Color) -> some View {
        VStack(spacing: 4) {
            // Modern tech header with gradients
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(colors: [primary, secondary], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 50, height: 8)
                    Rect(.label, w: 40, h: 5)
                }
                Spacer()
                RoundedRectangle(cornerRadius: 8)
                    .fill(primary.opacity(0.2))
                    .frame(width: 16, height: 16)
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
            
            // Clean company info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Rect(.label, w: 55, h: 5)
                    Rect(.secondaryLabel, w: 35, h: 4)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Rect(.secondaryLabel, w: 45, h: 4)
                    Rect(.secondaryLabel, w: 40, h: 4)
                }
            }
            .padding(.horizontal, 8)
            
            // Modern table design
            VStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(primary.opacity(0.15))
                    .frame(height: 6)
                    .overlay(
                        HStack {
                            Rect(.label, w: 60, h: 4)
                            Spacer()
                            Rect(.label, w: 18, h: 4)
                            Rect(.label, w: 22, h: 4)
                        }
                        .padding(.horizontal, 6)
                    )
                
                ForEach(0..<2) { _ in
                    HStack {
                        Rect(.label, w: 55, h: 4)
                        Spacer()
                        Rect(.label, w: 16, h: 4)
                        Rect(.label, w: 20, h: 4)
                    }
                    .padding(.horizontal, 6)
                }
            }
            
            // Modern total
            HStack {
                Spacer()
                Rect(.label, w: 30, h: 5)
            }
            .padding(.horizontal, 8)
        }
    }
    
    @ViewBuilder
    private func vintageRetroPreview(primary: Color, secondary: Color) -> some View {
        VStack(spacing: 4) {
            // Vintage header with decorative elements
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 2) {
                        Circle()
                            .fill(primary)
                            .frame(width: 6, height: 6)
                        Circle()
                            .fill(secondary)
                            .frame(width: 4, height: 4)
                        Circle()
                            .fill(primary.opacity(0.7))
                            .frame(width: 5, height: 5)
                    }
                    Rect(.label, w: 45, h: 6)
                }
                Spacer()
                RoundedRectangle(cornerRadius: 1)
                    .fill(primary.opacity(0.3))
                    .frame(width: 18, height: 12)
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
            
            // Vintage company info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Rect(.label, w: 50, h: 5)
                    Rect(.secondaryLabel, w: 35, h: 4)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Rect(.secondaryLabel, w: 40, h: 4)
                    Rect(.secondaryLabel, w: 35, h: 4)
                }
            }
            .padding(.horizontal, 8)
            
            // Vintage table with borders
            VStack(spacing: 1) {
                HStack {
                    Rect(.label, w: 60, h: 5)
                    Spacer()
                    Rect(.label, w: 20, h: 5)
                    Rect(.label, w: 25, h: 5)
                }
                .padding(.horizontal, 6)
                .background(primary.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 1)
                        .stroke(primary.opacity(0.3), lineWidth: 1)
                )
                
                ForEach(0..<2) { _ in
                    HStack {
                        Rect(.label, w: 55, h: 4)
                        Spacer()
                        Rect(.label, w: 18, h: 4)
                        Rect(.label, w: 22, h: 4)
                    }
                    .padding(.horizontal, 6)
                }
            }
            
            // Vintage total
            HStack {
                Spacer()
                Rect(.label, w: 35, h: 5)
            }
            .padding(.horizontal, 8)
        }
    }
    
    @ViewBuilder
    private func businessClassicPreview(primary: Color, secondary: Color) -> some View {
        VStack(spacing: 4) {
            // Classic business header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Rect(.label, w: 50, h: 6)
                    Rect(.secondaryLabel, w: 35, h: 4)
                }
                Spacer()
                RoundedRectangle(cornerRadius: 2)
                    .fill(primary.opacity(0.2))
                    .frame(width: 20, height: 14)
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
            
            // Professional company info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Rect(.label, w: 55, h: 5)
                    Rect(.secondaryLabel, w: 40, h: 4)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Rect(.secondaryLabel, w: 45, h: 4)
                    Rect(.secondaryLabel, w: 40, h: 4)
                }
            }
            .padding(.horizontal, 8)
            
            // Classic table design
            VStack(spacing: 2) {
                HStack {
                    Rect(.label, w: 65, h: 5)
                    Spacer()
                    Rect(.label, w: 20, h: 5)
                    Rect(.label, w: 25, h: 5)
                }
                .padding(.horizontal, 6)
                .background(primary.opacity(0.1))
                
                ForEach(0..<2) { _ in
                    HStack {
                        Rect(.label, w: 60, h: 4)
                        Spacer()
                        Rect(.label, w: 18, h: 4)
                        Rect(.label, w: 22, h: 4)
                    }
                    .padding(.horizontal, 6)
                }
            }
            
            // Classic total
            HStack {
                Spacer()
                Rect(.label, w: 40, h: 5)
            }
            .padding(.horizontal, 8)
        }
    }
    
    @ViewBuilder
    private func minimalistCleanPreview(primary: Color, secondary: Color) -> some View {
        VStack(spacing: 3) {
            // Minimalist header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Rect(.label, w: 45, h: 6)
                    Rect(.secondaryLabel, w: 30, h: 4)
                }
                Spacer()
                Circle()
                    .fill(primary.opacity(0.2))
                    .frame(width: 12, height: 12)
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
            
            // Clean company info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Rect(.label, w: 50, h: 5)
                    Rect(.secondaryLabel, w: 35, h: 4)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Rect(.secondaryLabel, w: 40, h: 4)
                    Rect(.secondaryLabel, w: 35, h: 4)
                }
            }
            .padding(.horizontal, 8)
            
            // Minimalist table
            VStack(spacing: 1) {
                HStack {
                    Rect(.label, w: 60, h: 4)
                    Spacer()
                    Rect(.label, w: 18, h: 4)
                    Rect(.label, w: 22, h: 4)
                }
                .padding(.horizontal, 6)
                .background(primary.opacity(0.05))
                
                ForEach(0..<2) { _ in
                    HStack {
                        Rect(.label, w: 55, h: 3)
                        Spacer()
                        Rect(.label, w: 16, h: 3)
                        Rect(.label, w: 20, h: 3)
                    }
                    .padding(.horizontal, 6)
                }
            }
            
            // Minimalist total
            HStack {
                Spacer()
                Rect(.label, w: 30, h: 4)
            }
            .padding(.horizontal, 8)
        }
    }
    
    @ViewBuilder
    private func creativeArtisticPreview(primary: Color, secondary: Color) -> some View {
        VStack(spacing: 4) {
            // Creative header with artistic elements
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 2) {
                        Star()
                            .fill(primary)
                            .frame(width: 8, height: 8)
                        Star()
                            .fill(secondary)
                            .frame(width: 6, height: 6)
                        Star()
                            .fill(primary.opacity(0.7))
                            .frame(width: 7, height: 7)
                    }
                    Rect(.label, w: 45, h: 6)
                }
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(colors: [primary, secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 16, height: 16)
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
            
            // Artistic company info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Rect(.label, w: 50, h: 5)
                    Rect(.secondaryLabel, w: 35, h: 4)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Rect(.secondaryLabel, w: 40, h: 4)
                    Rect(.secondaryLabel, w: 35, h: 4)
                }
            }
            .padding(.horizontal, 8)
            
            // Creative table design
            VStack(spacing: 2) {
                HStack {
                    Rect(.label, w: 60, h: 5)
                    Spacer()
                    Rect(.label, w: 20, h: 5)
                    Rect(.label, w: 25, h: 5)
                }
                .padding(.horizontal, 6)
                .background(
                    LinearGradient(colors: [primary.opacity(0.1), secondary.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(2)
                
                ForEach(0..<2) { _ in
                    HStack {
                        Rect(.label, w: 55, h: 4)
                        Spacer()
                        Rect(.label, w: 18, h: 4)
                        Rect(.label, w: 22, h: 4)
                    }
                    .padding(.horizontal, 6)
                }
            }
            
            // Creative total
            HStack {
                Spacer()
                HStack(spacing: 2) {
                    Star()
                        .fill(primary)
                        .frame(width: 4, height: 4)
                    Rect(.label, w: 30, h: 5)
                }
            }
            .padding(.horizontal, 8)
        }
    }
    
    private func headerGradient(primary: Color, secondary: Color) -> LinearGradient {
        switch descriptor.design {
        case .geometricAbstract, .techModern:
            return LinearGradient(
                colors: [primary, secondary, primary],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .vintageRetro, .businessClassic:
            return LinearGradient(
                colors: [secondary, primary],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .corporateFormal:
            return LinearGradient(
                colors: [primary, secondary, primary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [primary, secondary],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    private func tableHeaderGradient(primary: Color) -> LinearGradient {
        switch descriptor.design {
        case .geometricAbstract:
            return LinearGradient(
                colors: [primary.opacity(0.2), primary.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .techModern:
            return LinearGradient(
                colors: [primary.opacity(0.3), primary.opacity(0.1), primary.opacity(0.3)],
                startPoint: .leading,
                endPoint: .trailing
            )
        default:
            return LinearGradient(
                colors: [primary.opacity(0.12)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    private func Rect(_ uiColor: UIColor, w: CGFloat, h: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color(uiColor).opacity(0.85))
            .frame(width: w, height: h)
    }
}

// MARK: - Background View

extension TemplatePickerView {
    private var backgroundView: some View {
        Group {
            if scheme == .light {
                ZStack {
                    // Main gradient
                    LinearGradient(
                        colors: [Color.white, Color(white: 0.97), Color(white: 0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Radial gradient with animation
                    RadialGradient(
                        colors: [Color.white, Color(white: 0.96), .clear],
                        center: .topLeading,
                        startRadius: 24,
                        endRadius: 520
                    )
                    .blendMode(.screen)
                    
                    // Animated shimmer effect
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: shimmerOffset * 400)
                    .blendMode(.overlay)
                    
                    // Floating light spots
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
                    // Main gradient для темной темы
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
                    
                    // Animated shimmer effect для темной темы
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.1), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: shimmerOffset * 400)
                    .blendMode(.overlay)
                    
                    // Floating light spots для темной темы
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

// MARK: - Custom Logo Edit Alert

struct CustomLogoEditAlert: View {
    @Binding var isPresented: Bool
    let onRemove: () -> Void
    let onChange: () -> Void
    let onFileSelect: () -> Void
    
    @State private var dragOffset = CGSize.zero
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea(.all)
                .onTapGesture {
                    dismissAlert()
                }
                .opacity(opacity)
            
            // Alert content
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "photo.circle.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.black)
                    
                    Text("Edit Logo")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Choose an action for your logo")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                
                // Divider
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 1)
                
                // Action buttons
                VStack(spacing: 0) {
                    // Change Logo button (Photos)
                    Button(action: {
                        onChange()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "photo")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                            
                            Text("Choose from Photos")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 1)
                        .padding(.horizontal, 24)
                    
                    // Choose from Files button
                    Button(action: {
                        onFileSelect()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "folder")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.green)
                            
                            Text("Choose from Files")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 1)
                        .padding(.horizontal, 24)
                    
                    // Remove Logo button
                    Button(action: {
                        onRemove()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.red)
                            
                            Text("Remove Logo")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 1)
                        .padding(.horizontal, 24)
                    
                    // Cancel button
                    Button(action: {
                        dismissAlert()
                    }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .frame(maxWidth: 320)
            .scaleEffect(scale)
            .offset(dragOffset)
            .opacity(opacity)
            .zIndex(1000)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        if abs(value.translation.height) > 100 {
                            dismissAlert()
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                dragOffset = .zero
                            }
                        }
                    }
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
    
    private func dismissAlert() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            scale = 0.8
            opacity = 0
            dragOffset = .zero
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Custom Shapes for Template Previews

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Star: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        for i in 0..<5 {
            let angle = Double(i) * 4 * Double.pi / 5 - Double.pi / 2
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}
