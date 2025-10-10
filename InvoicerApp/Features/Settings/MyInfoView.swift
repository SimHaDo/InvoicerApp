//
//  MyInfoView.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/29/25.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers


struct MyInfoView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.shouldDismissMyInfo) private var shouldDismissMyInfo

    // локальный editable слепок компании
    @State private var editingCompany: Company = .init()
    @State private var isEditingCompany = false
    @State private var showAddEditMethod = false
    @State private var editingMethod: PaymentMethod? = nil
    @State private var photoItem: PhotosPickerItem?
    
    @State private var showContent = false

    var body: some View {
        ZStack {
            // Анимированный фон
            backgroundView()
            
            
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
            if !showContent {
                showContent = true
            }
            // Обновляем разрешения при появлении view
            PermissionManager.shared.refreshPermissions()
        }
        .onDisappear {
            // Очищаем состояние при исчезновении view (переключение табов)
            // Особенно важно для iPad где NavigationSplitView может держать view в памяти
            showContent = false
            print("MyInfoView: onDisappear called, clearing state")
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // Обновляем разрешения когда приложение становится активным
                PermissionManager.shared.refreshPermissions()
            } else if newPhase == .background {
                // Очищаем состояние при переходе в фон
                showContent = false
            }
        }
        .onChange(of: shouldDismissMyInfo) { newValue in
            if newValue {
                // Принудительно очищаем состояние при переключении табов на iPad
                showContent = false
                print("MyInfoView: Received dismiss signal, clearing state")
            }
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
                LinearGradient(
                    colors: [Color.white, Color(white: 0.97), Color(white: 0.95)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [Color.black, Color.black.opacity(0.92)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
    }
    
}

// MARK: - Section Components

private struct LogoSection: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.colorScheme) private var scheme
    @ObservedObject private var permissionManager = PermissionManager.shared
    @State private var photoItem: PhotosPickerItem?
    @State private var showPhotosPicker = false
    @State private var showFilePicker = false
    @State private var isLoading = false
    @State private var showLogoEditAlert = false
    @State private var showPermissionAlert = false
    @State private var permissionType: PermissionType = .photoLibrary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            contentSection
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
            .photosPicker(isPresented: $showPhotosPicker, selection: $photoItem, matching: .images)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.image, .jpeg, .png, .gif, .bmp, .tiff],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .onChange(of: photoItem) { new in
            handlePhotoSelection(new)
        }
        .zIndex(showLogoEditAlert || showPermissionAlert ? 1000 : 0)
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
                    .zIndex(1001)
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
                                // Обновляем разрешения через 1 секунду после открытия настроек
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    permissionManager.refreshPermissions()
                                }
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
    }
    
    // MARK: - Computed Properties
    
    private var headerSection: some View {
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
    }
    
    private var contentSection: some View {
        HStack(spacing: 16) {
            logoPreview
            editButtonSection
        }
    }
    
    private var logoPreview: some View {
        Group {
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
        }
    }
    
    private var editButtonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                showLogoEditAlert = true
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                    }
                    Text(isLoading ? "Loading..." : (app.logoImage == nil ? "Add Logo" : "Edit Logo"))
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
            .disabled(isLoading)
        }
    }
    
    // MARK: - Helper Functions
    
    private func handlePhotoSelection(_ new: PhotosPickerItem?) {
        guard let new else { return }
        isLoading = true
        
        Task {
            do {
                if let data = try await new.loadTransferable(type: Data.self) {
                    // Устанавливаем новый логотип напрямую (AppState сам очистит старый)
                    await MainActor.run {
                        app.logoData = data
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("Error loading photo: \(error)")
                }
            }
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            isLoading = true
            
            Task {
                do {
                    // Start accessing the security-scoped resource
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if accessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    
                    let data = try Data(contentsOf: url)
                    
                    // Устанавливаем новый логотип напрямую (AppState сам очистит старый)
                    await MainActor.run {
                        app.logoData = data
                        isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        isLoading = false
                        print("Error loading file: \(error)")
                    }
                }
            }
        case .failure(let error):
            print("File picker error: \(error)")
        }
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
                    // Если разрешение не дано, показываем алерт с переходом в настройки
                    permissionType = .photoLibrary
                    showPermissionAlert = true
                }
            }
        }
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
                Image(systemName: "building.2")
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
