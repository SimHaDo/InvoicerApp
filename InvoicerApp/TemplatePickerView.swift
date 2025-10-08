//
//  TemplatePickerView.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/29/25.
//

import SwiftUI
import PhotosUI

struct TemplatePickerView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    let onSelect: (CompleteInvoiceTemplate) -> Void
    init(onSelect: @escaping (CompleteInvoiceTemplate) -> Void = { _ in }) {
        self.onSelect = onSelect
    }

    @State private var photoItem: PhotosPickerItem?
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

    var body: some View {
        NavigationStack(path: $navigationPath) {
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
                
                VStack(spacing: 0) {
                    // Header с логотипом
                headerLogo
                        .offset(y: showContent ? 0 : -20)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1), value: showContent)
                    
                    // Search and Filters
                    searchAndFilters
                        .offset(y: showContent ? 0 : -15)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)
                    
                    // Templates Grid
                    templatesGrid
                        .offset(y: showContent ? 0 : 20)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)
                }
            }
            .navigationTitle("Invoice Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { 
                    Button("Done") { dismiss() } 
                }
            }
            .navigationDestination(for: InvoiceTemplateDescriptor.self) { template in
                ColorSchemePickerView(selectedTemplate: template) { selectedTheme in
                    // Create a complete template with design and theme
                    let completeTemplate = CompleteInvoiceTemplate(template: template, theme: selectedTheme)
                    
                    // Store the selected template in AppState
                    app.selectedTemplate = completeTemplate
                    onSelect(completeTemplate)
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            // PaywallScreen would go here
        }
        .onAppear {
            showContent = true
            pulseAnimation = true
            startShimmerAnimation()
            createFloatingElements()
        }
    }
    
    // MARK: - Header Logo
    
    @ViewBuilder private var headerLogo: some View {
        VStack(spacing: 16) {
        HStack(spacing: 12) {
            if let img = app.logoImage {
                Image(uiImage: img).resizable().scaledToFit()
                    .frame(width: 56, height: 56)
                    .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                    RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08))
                        .overlay(
                            VStack(spacing: 4) {
                                Image(systemName: "building.2")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(.secondary)
                                Text("Logo")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
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
                
                VStack(spacing: 8) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                        HStack(spacing: 6) {
                            Image(systemName: "photo")
                                .font(.system(size: 14, weight: .medium))
                            Text("Add Logo")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.primary)
                        )
                        .foregroundColor(.white)
            }
            .onChange(of: photoItem) { new in
                guard let new else { return }
                Task {
                    if let data = try? await new.loadTransferable(type: Data.self) {
                        app.logoData = data
                    }
                }
            }

            if app.logoData != nil {
                Button(role: .destructive) { app.logoData = nil } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.system(size: 12, weight: .medium))
                                Text("Remove")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.1))
                            )
                            .foregroundColor(.red)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }
    
    // MARK: - Search and Filters
    
    private var searchAndFilters: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("Search templates...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 16, weight: .regular))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
            
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
                .padding(.horizontal, 20)
            }
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "All",
                        isSelected: selectedCategories.isEmpty,
                        action: { selectedCategories.removeAll() }
                    )
                    
                    ForEach(TemplateCategory.allCases, id: \.self) { category in
                        FilterChip(
                            title: category.rawValue,
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
                .padding(.horizontal, 20)
            }
            
            // Design Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TemplateDesign.allCases, id: \.self) { design in
                        FilterChip(
                            title: design.rawValue.capitalized,
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
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Templates Grid
    
    private var templatesGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
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
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Helper Functions
    
    private func resetFilters() {
        selectedCategories.removeAll()
        selectedDesigns.removeAll()
    }
}

// MARK: - Template Card

private struct TemplateCard: View {
    let descriptor: InvoiceTemplateDescriptor
    let onTap: () -> Void
    
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
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
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

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.primary : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                        )
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

// MARK: - Enhanced Template Card Preview

struct TemplateCardPreview: View {
    let descriptor: InvoiceTemplateDescriptor
    
    var body: some View {
        // Use default colors for preview since theme will be selected later
        let primary = Color.blue
        let secondary = Color.blue.opacity(0.7)
        
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.secondarySystemBackground).opacity(0.6))
            .overlay(
                VStack(spacing: 8) {
                    // Header with gradient based on style
                    headerSection(primary: primary, secondary: secondary)
                    
                    // Company info section
                    companyInfoSection
                    
                    // Items table with style-specific design
                    itemsTableSection(primary: primary)
                    
                    // Total section
                    totalSection
                    
                    Spacer(minLength: 2)
                }
                .padding(8)
            )
    }
    
    @ViewBuilder
    private func headerSection(primary: Color, secondary: Color) -> some View {
                HStack {
                    RoundedRectangle(cornerRadius: 6)
                .fill(headerGradient(primary: primary, secondary: secondary))
                        .frame(width: 60, height: 14)
                    Spacer()
                    RoundedRectangle(cornerRadius: 6)
                        .fill(primary.opacity(0.5))
                        .frame(width: 34, height: 14)
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)
    }

    @ViewBuilder
    private var companyInfoSection: some View {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Rect(.label, w: 80, h: 10)
                        Rect(.secondaryLabel, w: 60, h: 8)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Rect(.secondaryLabel, w: 70, h: 8)
                        Rect(.secondaryLabel, w: 70, h: 8)
                        Rect(.secondaryLabel, w: 70, h: 8)
                    }
                }
                .padding(.horizontal, 10)
    }

    @ViewBuilder
    private func itemsTableSection(primary: Color) -> some View {
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                .fill(tableHeaderGradient(primary: primary))
                        .frame(height: 14)
                        .padding(.horizontal, 8)
                    ForEach(0..<3) { _ in
                        HStack {
                            Rect(.label, w: 90, h: 8)
                            Spacer()
                            Rect(.label, w: 28, h: 8)
                            Rect(.label, w: 40, h: 8)
                            Rect(.label, w: 40, h: 8)
                        }
                        .padding(.horizontal, 8)
            }
                    }
                }

    @ViewBuilder
    private var totalSection: some View {
                HStack {
                    Spacer()
                    Rect(.label, w: 60, h: 10)
                }
                .padding(.horizontal, 10)
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
