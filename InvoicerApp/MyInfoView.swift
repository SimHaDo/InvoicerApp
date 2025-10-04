//
//  MyInfoView.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/29/25.
//

import SwiftUI
import PhotosUI

// MARK: - FloatingElement

private struct FloatingElement: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var opacity: Double
    var scale: Double
    var rotation: Double
}

struct MyInfoView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.colorScheme) private var scheme

    // локальный editable слепок компании
    @State private var editingCompany: Company = .init()
    @State private var isEditingCompany = false
    @State private var showAddEditMethod = false
    @State private var editingMethod: PaymentMethod? = nil
    @State private var photoItem: PhotosPickerItem?
    
    @State private var showContent = false
    @State private var pulseAnimation = false
    @State private var shimmerOffset: CGFloat = -1
    @State private var floatingElements: [FloatingElement] = []

    var body: some View {
        ZStack {
            // Анимированный фон
            backgroundView()
            
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
                VStack(alignment: .leading, spacing: 24) {
                    // Header с анимациями
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("My Info")
                                .font(.system(size: 32, weight: .black))
                                .foregroundColor(.primary)
                                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                                .offset(y: showContent ? 0 : -20)
                                .opacity(showContent ? 1 : 0)
                                .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1), value: showContent)
                            
                            Text("Manage your company details")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.secondary)
                                .offset(y: showContent ? 0 : -15)
                                .opacity(showContent ? 1 : 0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)
                        }
                        Spacer()
                    }
                    
                    // Logo Section
                    LogoSection()
                        .scaleEffect(showContent ? 1.0 : 0.9)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)
                    
                    // Company Section
                    CompanySection()
                        .scaleEffect(showContent ? 1.0 : 0.9)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: showContent)
                    
                    // Payment Methods Section
                    PaymentMethodsSection()
                        .scaleEffect(showContent ? 1.0 : 0.9)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: showContent)
                    
                    // Additional Notes Section
                    AdditionalNotesSection()
                        .scaleEffect(showContent ? 1.0 : 0.9)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: showContent)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let c = app.company {
                editingCompany = c
                isEditingCompany = false
            } else {
                editingCompany = Company()
                isEditingCompany = true
            }
            showContent = true
            pulseAnimation = true
            startShimmerAnimation()
            createFloatingElements()
        }
        .sheet(isPresented: $showAddEditMethod) {
            AddEditPaymentMethodSheet { new in
                app.paymentMethods.append(new)
                app.savePaymentMethods()
            }
        }
        .sheet(item: $editingMethod) { m in
            AddEditPaymentMethodSheet(existing: m) { updated in
                if let idx = app.paymentMethods.firstIndex(where: { $0.id == m.id }) {
                    app.paymentMethods[idx] = updated
                    app.savePaymentMethods()
                }
            }
        }
    }
    
    // MARK: - Background View
    
    private func backgroundView() -> some View {
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

// MARK: - Section Components

private struct LogoSection: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.colorScheme) private var scheme
    @State private var photoItem: PhotosPickerItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "photo.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Company Logo")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Add or change your logo")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                // Logo preview
                if let img = app.logoImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(scheme == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(.secondary)
                        )
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 14, weight: .medium))
                            Text(app.logoImage == nil ? "Add Logo" : "Change Logo")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(scheme == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.primary)
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
                        Button(role: .destructive) {
                            app.logoData = nil
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Remove Logo")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(.red)
                        }
                    }
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
}

private struct CompanySection: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.colorScheme) private var scheme
    @State private var editingCompany: Company = .init()
    @State private var isEditingCompany = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "building.2.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Company Details")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Your business information")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            if let c = app.company, !isEditingCompany {
                CompanySummary(company: c)
                
                Button {
                    startEditingCompany(c)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                        Text("Edit Company")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(scheme == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.primary)
                }
            } else {
                CompanyEditor(company: $editingCompany)
                
                HStack(spacing: 12) {
                    Button {
                        isEditingCompany = false
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                            Text("Cancel")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(scheme == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.primary)
                    }
                    
                    Button {
                        app.company = editingCompany
                        isEditingCompany = false
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .medium))
                            Text("Save")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.primary)
                                .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
                        )
                        .foregroundColor(scheme == .light ? .white : .black)
                    }
                    .disabled(editingCompany.name.trimmingCharacters(in: .whitespaces).isEmpty)
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
        .onAppear {
            if let c = app.company {
                editingCompany = c
                isEditingCompany = false
            } else {
                editingCompany = Company()
                isEditingCompany = true
            }
        }
    }
    
    private func startEditingCompany(_ c: Company) {
        editingCompany = c
        isEditingCompany = true
    }
}

private struct PaymentMethodsSection: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.colorScheme) private var scheme
    @State private var showAddEditMethod = false
    @State private var editingMethod: PaymentMethod? = nil
    
    private var paymentMethodsContent: some View {
        Group {
            if app.paymentMethods.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "creditcard")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Text("No payment methods yet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Text("Add your first payment method to get started")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(app.paymentMethods) { method in
                        PaymentMethodRow(method: method, onTap: { editingMethod = method })
                    }
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "creditcard.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payment Methods")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Saved payment options")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            paymentMethodsContent
            
            Button {
                showAddEditMethod = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                    Text("Add Payment Method")
                        .font(.system(size: 14, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primary)
                        .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
                )
                .foregroundColor(scheme == .light ? .white : .black)
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
        .sheet(isPresented: $showAddEditMethod) {
            AddEditPaymentMethodSheet { new in
                app.paymentMethods.append(new)
                app.savePaymentMethods()
            }
        }
        .sheet(item: $editingMethod) { m in
            AddEditPaymentMethodSheet(existing: m) { updated in
                if let idx = app.paymentMethods.firstIndex(where: { $0.id == m.id }) {
                    app.paymentMethods[idx] = updated
                    app.savePaymentMethods()
                }
            }
        }
    }
}

private struct AdditionalNotesSection: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "note.text")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Additional Notes")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Notes shown on invoices")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            TextField(
                "Notes shown on invoice (optional)",
                text: Binding(
                    get: { app.settings.additionalNotes ?? "" },
                    set: { newVal in
                        app.settings.additionalNotes =
                            newVal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newVal
                        app.saveSettings()
                    }
                ),
                axis: .vertical
            )
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.primary)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            )
            .lineLimit(3...6)
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
}

// MARK: - PaymentMethodRow

private struct PaymentMethodRow: View {
    let method: PaymentMethod
    let onTap: () -> Void
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: method.type.iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(method.type.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(method.type.subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Company subviews

private struct CompanySummary: View {
    let company: Company
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(company.name)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                if !company.email.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                        Text(company.email)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                
                if !company.phone.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "phone")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                        Text(company.phone)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                
                if !company.address.oneLine.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                        Text(company.address.oneLine)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let site = company.website, !site.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                        Text(site)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

private struct CompanyEditor: View {
    @Binding var company: Company
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Company name", text: $company.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                    )
                
                TextField("Email", text: $company.email)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                    )
                
                TextField("Phone", text: $company.phone)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .keyboardType(.phonePad)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                    )
                
                TextField("Website (optional)", text: Binding(
                    get: { company.website ?? "" },
                    set: { company.website = $0.isEmpty ? nil : $0 }
                ))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Address")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                TextField("Line 1", text: $company.address.line1)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                    )
                
                TextField("Line 2", text: $company.address.line2)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                    )
                
                HStack(spacing: 12) {
                    TextField("City", text: $company.address.city)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                )
                        )
                    
                    TextField("State", text: $company.address.state)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                )
                        )
                }
                
                HStack(spacing: 12) {
                    TextField("ZIP", text: $company.address.zip)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                )
                        )
                    
                    TextField("Country", text: $company.address.country)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                )
                        )
                }
            }
        }
    }
}