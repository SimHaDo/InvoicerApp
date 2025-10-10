//
//  ColorSchemePickerView.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/29/25.
//

import SwiftUI

struct ColorSchemePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    
    let selectedTemplate: InvoiceTemplateDescriptor
    let onColorSelected: (TemplateTheme) -> Void
    let onClose: (() -> Void)?
    
    init(selectedTemplate: InvoiceTemplateDescriptor, onColorSelected: @escaping (TemplateTheme) -> Void, onClose: (() -> Void)? = nil) {
        self.selectedTemplate = selectedTemplate
        self.onColorSelected = onColorSelected
        self.onClose = onClose
    }
    
    @State private var showContent = false
    @State private var pulseAnimation = false
    @State private var shimmerOffset: CGFloat = -1
    @State private var floatingElements: [FloatingElement] = []
    @State private var selectedTheme: TemplateTheme?
    
    private let themes = TemplateCatalog.themes
    
    var body: some View {
        ZStack {
            // Анимированный фон
            backgroundView
            
            // Плавающие элементы
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
            
            VStack(spacing: 0) {
                // Header с информацией о темплейте
                templateHeader
                    .offset(y: showContent ? 0 : -20)
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1), value: showContent)
                
                // Preview секция
                previewSection
                    .offset(y: showContent ? 0 : -15)
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)
                
                // Color schemes grid
                colorSchemesGrid
                    .offset(y: showContent ? 0 : 20)
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)
            }
        }
        .navigationTitle("Choose Color Scheme")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: { 
                        // Полностью очищаем стэк и закрываем флоу
                        onClose?()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Next") {
                        if let theme = selectedTheme {
                            onColorSelected(theme)
                        }
                    }
                    .disabled(selectedTheme == nil)
                }
            }
        }
        .onAppear {
            showContent = true
            pulseAnimation = true
            startShimmerAnimation()
            createFloatingElements()
        }
    }
    
    // MARK: - Template Header
    
    @ViewBuilder private var templateHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Template Icon
                Image(systemName: selectedTemplate.previewImage)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.primary.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(selectedTemplate.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(selectedTemplate.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Text(selectedTemplate.category.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.1))
                            )
                            .foregroundColor(.blue)
                        
                        if selectedTemplate.isPremium {
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
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }
    
    // MARK: - Preview Section
    
    @ViewBuilder private var previewSection: some View {
        VStack(spacing: 16) {
            Text("Preview")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            // Live preview of template with selected color
            if let theme = selectedTheme {
                TemplatePreviewCard(template: selectedTemplate, theme: theme)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.primary.opacity(0.05))
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "paintpalette")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("Select a color scheme to see preview")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    )
                    .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Color Schemes Grid
    
    private var colorSchemesGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                ForEach(themes, id: \.name) { theme in
                    ColorSchemeCard(theme: theme, isSelected: selectedTheme?.name == theme.name) {
                        selectedTheme = theme
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
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
                        colors: [
                            Color(red: 0.05, green: 0.05, blue: 0.08), 
                            Color(red: 0.08, green: 0.08, blue: 0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Радиальный градиент
                    RadialGradient(
                        colors: [Color.blue.opacity(0.12), .clear],
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
                            .fill(Color.blue.opacity(0.1))
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

// MARK: - Color Scheme Card

private struct ColorSchemeCard: View {
    let theme: TemplateTheme
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Color preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(theme.primary),
                                    Color(theme.secondary)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 80)
                    
                    // Color name overlay
                    VStack {
                        Spacer()
                        Text(theme.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.3))
                            )
                    }
                    .padding(8)
                }
                
                // Color details
                VStack(spacing: 4) {
                    Text(theme.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(theme.primary))
                            .frame(width: 12, height: 12)
                        
                        Circle()
                            .fill(Color(theme.secondary))
                            .frame(width: 12, height: 12)
                        
                        Circle()
                            .fill(Color(theme.accent))
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        scheme == .dark ? 
                        Color(red: 0.12, green: 0.12, blue: 0.16) : 
                        Color.primary.opacity(0.02)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.blue : 
                                (scheme == .dark ? Color.blue.opacity(0.2) : Color.primary.opacity(0.1)),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Template Preview Card

private struct TemplatePreviewCard: View {
    let template: InvoiceTemplateDescriptor
    let theme: TemplateTheme
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        let primary = Color(theme.primary)
        let secondary = Color(theme.secondary)
        
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    scheme == .dark ? 
                    Color(red: 0.12, green: 0.12, blue: 0.16) : 
                    Color(.secondarySystemBackground).opacity(0.6)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            scheme == .dark ? 
                            Color.blue.opacity(0.2) : 
                            Color.clear, 
                            lineWidth: 1
                        )
                )

            VStack(spacing: 8) {
                // Header with gradient based on design
                headerSection(primary: primary, secondary: secondary)
                
                // Company info section
                companyInfoSection
                
                // Items table with style-specific design
                itemsTableSection(primary: primary)
                
                // Total section
                totalSection
                
                Spacer(minLength: 2)
            }
        }
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
        switch template.design {
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
        switch template.design {
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

// MARK: - FloatingElement

private struct FloatingElement: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var opacity: Double
    var scale: Double
    var rotation: Double
}
