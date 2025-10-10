//
//  DataActionSheets.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/29/25.
//

import SwiftUI

// MARK: - Export Confirmation Sheet

struct ExportConfirmationView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.colorScheme) private var scheme
    
    @StateObject private var dataManager = DataManager.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isReady = false
    
    // Export options
    @State private var selectedFormat: ExportFormat = .json
    @State private var includeCustomers = true
    @State private var includeInvoices = true
    @State private var includeProducts = true
    @State private var includePaymentMethods = true
    @State private var includeCompanyInfo = true
    @State private var includeSettings = true
    
    var body: some View {
        ZStack {
            // Background
            backgroundView()
            
            if isReady {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 6) {
                                Text("Export Data")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("Choose what data to export and in which format")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.top, 16)
                        
                        // Export Options
                        VStack(spacing: 16) {
                            // Format Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Export Format")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 12) {
                                    ForEach(ExportFormat.allCases, id: \.self) { format in
                                        Button {
                                            selectedFormat = format
                                        } label: {
                                            Text(format.rawValue)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(selectedFormat == format ? (scheme == .light ? .white : .black) : .primary)
                                                .frame(minWidth: 60)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(selectedFormat == format ? Color.primary : Color.clear)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 10)
                                                                .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                                                        )
                                                )
                                        }
                                    }
                                }
                            }
                            
                            // Data Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Include Data")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                VStack(spacing: 8) {
                                    DataToggleRow(title: "Customers", count: app.customers.count, isOn: $includeCustomers)
                                    DataToggleRow(title: "Invoices", count: app.invoices.count, isOn: $includeInvoices)
                                    DataToggleRow(title: "Products", count: app.products.count, isOn: $includeProducts)
                                    DataToggleRow(title: "Payment Methods", count: app.paymentMethods.count, isOn: $includePaymentMethods)
                                    DataToggleRow(title: "Company Info", count: app.company != nil ? 1 : 0, isOn: $includeCompanyInfo)
                                    DataToggleRow(title: "Settings", count: 1, isOn: $includeSettings)
                                }
                            }
                            
                            if dataManager.isExporting {
                                ExportProgressView()
                            }
                        }
                        
                                // Action Buttons
                                VStack(spacing: 12) {
                                    if dataManager.isExporting {
                                Button {
                                    // Cancel export
                                    dataManager.isExporting = false
                                    dataManager.exportProgress = 0.0
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Cancel Export")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
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
                                Button {
                                    Task {
                                        // Создаем опции экспорта
                                        let exportOptions = ExportOptions(
                                            format: selectedFormat,
                                            includeCustomers: includeCustomers,
                                            includeInvoices: includeInvoices,
                                            includeProducts: includeProducts,
                                            includePaymentMethods: includePaymentMethods,
                                            includeCompanyInfo: includeCompanyInfo,
                                            includeSettings: includeSettings
                                        )
                                        
                                        // Создаем новый DataManager для каждого экспорта
                                        let freshDataManager = DataManager()
                                        
                                        if let url = await freshDataManager.exportAllData(appState: app, options: exportOptions) {
                                            // Увеличиваем задержку для правильной обработки файла системой
                                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 секунда
                                            
                                            // Проверяем, что файл все еще существует
                                            let fileExists = FileManager.default.fileExists(atPath: url.path)
                                            guard fileExists else {
                                                await MainActor.run {
                                                    alertMessage = "File was not created properly. Please try again."
                                                    showingAlert = true
                                                }
                                                return
                                            }
                                            
                                            // Показываем UIActivityViewController напрямую
                                            await MainActor.run {
                                                let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                                                
                                                // Находим root view controller
                                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                                   let window = windowScene.windows.first,
                                                   let rootVC = window.rootViewController {
                                                    
                                                    // Если rootVC - это UINavigationController, берем topViewController
                                                    let presentingVC = (rootVC as? UINavigationController)?.topViewController ?? rootVC
                                                    
                                                    // Показываем activityVC
                                                    presentingVC.present(activityVC, animated: true)
                                                }
                                            }
                                        } else {
                                            await MainActor.run {
                                                alertMessage = "Failed to export data. Please try again."
                                                showingAlert = true
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Export Data")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.primary)
                                            .shadow(color: Color.black.opacity(0.2), radius: 6, y: 3)
                                    )
                                    .foregroundColor(scheme == .light ? .white : .black)
                                }
                                .disabled(dataManager.isExporting)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 20)
                }
            } else {
                // Loading state
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.8)
                    
                    Text("Preparing export...")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary.opacity(0.7))
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Сброс всех состояний при открытии
            isReady = false
            showingAlert = false
            alertMessage = ""
            
            // Debug: Print AppState data
            print("ExportConfirmationView AppState Debug:")
            print("- Customers: \(app.customers.count)")
            print("- Products: \(app.products.count)")
            print("- Invoices: \(app.invoices.count)")
            print("- Payment Methods: \(app.paymentMethods.count)")
            print("- Company: \(app.company?.name ?? "nil")")
            
            // Задержка для правильной инициализации EnvironmentObject
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isReady = true
            }
        }
        .alert("Export Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func backgroundView() -> some View {
        Group {
            if scheme == .light {
                LinearGradient(
                    colors: [Color.white, Color(white: 0.97)],
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

// MARK: - Reset Confirmation Sheet

struct ResetConfirmationSheet: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    
    @StateObject private var dataManager = DataManager.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isConfirmed = false
    @State private var confirmationText = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundView()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 64, weight: .medium))
                            .foregroundColor(.red)
                        
                        VStack(spacing: 8) {
                            Text("Reset All Data")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("This will permanently delete all your data")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // Warning
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("This action cannot be undone")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text("All customers, invoices, products, and settings will be permanently deleted.")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary.opacity(0.7))
                            }
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                        )
                        
                        DataSummaryCard()
                    }
                    
                    // Confirmation
                    VStack(spacing: 12) {
                        Text("Type 'DELETE' to confirm")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        TextField("Type DELETE here", text: $confirmationText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(confirmationText.uppercased() == "DELETE" ? Color.green : Color.primary.opacity(0.1), lineWidth: 1)
                                    )
                            )
                            .onChange(of: confirmationText) { newValue in
                                isConfirmed = newValue.uppercased() == "DELETE"
                            }
                        
                        if isConfirmed {
                            Button {
                                Task {
                                    _ = await dataManager.resetAllData(appState: app)
                                    dismiss()
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Confirm Reset")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red)
                                        .shadow(color: Color.black.opacity(0.2), radius: 6, y: 3)
                                )
                                .foregroundColor(.white)
                            }
                        }
                    }
                    
                    // Cancel Button
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary.opacity(0.7))
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("Reset Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func backgroundView() -> some View {
        Group {
            if scheme == .light {
                LinearGradient(
                    colors: [Color.white, Color(white: 0.97)],
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

// MARK: - Data Summary Card

private struct DataSummaryCard: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("Data Summary")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                DataRow(icon: "person.2", title: "Customers", count: app.customers.count)
                DataRow(icon: "doc.text", title: "Invoices", count: app.invoices.count)
                DataRow(icon: "cube.box", title: "Products", count: app.products.count)
                DataRow(icon: "creditcard", title: "Payment Methods", count: app.paymentMethods.count)
                
                if app.company != nil {
                    DataRow(icon: "building.2", title: "Company Info", count: 1)
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

// MARK: - Data Row

private struct DataRow: View {
    let icon: String
    let title: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary.opacity(0.7))
        }
    }
}

// MARK: - Export Progress View

private struct ExportProgressView: View {
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ProgressView(value: dataManager.exportProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .scaleEffect(y: 2)
                
                Text("\(Int(dataManager.exportProgress * 100))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Text("Preparing your data for export...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary.opacity(0.7))
        }
        .padding(16)
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

// MARK: - Data Toggle Row

private struct DataToggleRow: View {
    let title: String
    let count: Int
    @Binding var isOn: Bool
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("\(count) items")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary.opacity(0.6))
            }
            
            Spacer()
            
            // Count badge
            Text("\(count)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(scheme == .light ? .white : .black)
                .frame(minWidth: 28, minHeight: 28)
                .background(
                    Circle()
                        .fill(Color.primary)
                )
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .primary))
                .scaleEffect(0.9)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(scheme == .light ? Color.black.opacity(0.02) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}