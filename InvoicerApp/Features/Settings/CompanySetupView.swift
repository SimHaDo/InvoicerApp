//
//  CompanySetupView.swift
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

// Company Setup
struct CompanySetupView: View {
    @EnvironmentObject private var app: AppState

    @State private var company = Company()
    @Environment(\.colorScheme) private var scheme
    
    @State private var showContent = false
    @State private var pulseAnimation = false
    @State private var shimmerOffset: CGFloat = -1
    @State private var floatingElements: [FloatingElement] = []
    @State private var isEditing = false

    private var canSave: Bool {
        !company.name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !company.email.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
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
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header with animations
                        headerView
                        
                        // Company Information Card
                        companyInfoCard
                        
                        // Continue Button
                        continueButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            showContent = true
            pulseAnimation = true
            startShimmerAnimation()
            createFloatingElements()
            // if already saved - set for editing
            company = app.company ?? Company()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Company Setup")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.primary)
                        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                        .offset(y: showContent ? 0 : -20)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1), value: showContent)
                    
                    Text("Set up your business information")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                        .offset(y: showContent ? 0 : -15)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)
                }
                Spacer()
                
                Button(action: { isEditing.toggle() }) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.primary)
                }
                .scaleEffect(showContent ? 1.0 : 0.9)
                .opacity(showContent ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)
            }
        }
    }
    
    // MARK: - Company Info Card
    
    private var companyInfoCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "building.2")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Company Information")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Enter your business details")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Form Fields
            VStack(spacing: 16) {
                // Company Name
                CustomTextField(
                    title: "Company Name",
                    placeholder: "Your Company Name",
                    text: $company.name,
                    icon: "building.2"
                )
                
                // Email and Phone
                HStack(spacing: 12) {
                    CustomTextField(
                        title: "Email",
                        placeholder: "company@example.com",
                        text: $company.email,
                        icon: "envelope",
                        keyboardType: .emailAddress
                    )
                    
                    CustomTextField(
                        title: "Phone",
                        placeholder: "+1 (555) 123-4567",
                        text: $company.phone,
                        icon: "phone",
                        keyboardType: .phonePad
                    )
                }
                
                // Address
                CustomTextField(
                    title: "Address",
                    placeholder: "123 Business Street, City, State 12345",
                    text: $company.address.line1,
                    icon: "location"
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
        .offset(y: showContent ? 0 : 20)
        .opacity(showContent ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: showContent)
    }
    
    // MARK: - Continue Button
    
    private var continueButton: some View {
        Button {
            app.company = company
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                
                Text("Continue to Invoice Creation")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.primary)
                    .shadow(color: Color.black.opacity(0.2), radius: 12, y: 6)
            )
            .foregroundColor(scheme == .light ? .white : .black)
        }
        .disabled(!canSave)
        .opacity(canSave ? 1.0 : 0.6)
        .scaleEffect(showContent ? 1.0 : 0.9)
        .opacity(showContent ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: showContent)
    }
}

// MARK: - Background View

extension CompanySetupView {
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

// MARK: - Custom Text Field

private struct CustomTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 16)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textFieldStyle(PlainTextFieldStyle())
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
        }
    }
}