//
//  DataManager.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/29/25.
//

import Foundation
import SwiftUI
import CoreText

// MARK: - Export Format

enum ExportFormat: String, CaseIterable {
    case json = "JSON"
    case csv = "CSV"
    case pdf = "PDF"
    
    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        case .pdf: return "pdf"
        }
    }
    
    var mimeType: String {
        switch self {
        case .json: return "application/json"
        case .csv: return "text/csv"
        case .pdf: return "application/pdf"
        }
    }
}

// MARK: - Export Options

struct ExportOptions {
    let format: ExportFormat
    let includeCustomers: Bool
    let includeInvoices: Bool
    let includeProducts: Bool
    let includePaymentMethods: Bool
    let includeCompanyInfo: Bool
    let includeSettings: Bool
}

// MARK: - Data Export/Import Manager

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var isExporting = false
    @Published var isResetting = false
    @Published var exportProgress: Double = 0.0
    
    init() {}
    
    // MARK: - Export Functions
    
    func exportAllData(appState: AppState, options: ExportOptions) async -> URL? {
        await MainActor.run {
            isExporting = true
            exportProgress = 0.0
        }
        
        do {
            // Create export data structure based on options
            let exportData = await MainActor.run {
                let data = ExportData(
                    company: options.includeCompanyInfo ? appState.company : nil,
                    customers: options.includeCustomers ? appState.customers : [],
                    products: options.includeProducts ? appState.products : [],
                    invoices: options.includeInvoices ? appState.invoices : [],
                    paymentMethods: options.includePaymentMethods ? appState.paymentMethods : [],
                    settings: options.includeSettings ? appState.settings : AppSettings(),
                    logoData: options.includeCompanyInfo ? Storage.loadLogo() : nil,
                    exportDate: Date(),
                    appVersion: Bundle.main.appVersion
                )
                
                // Debug: Print export options and data counts
                print("Export Options Debug:")
                print("- Format: \(options.format)")
                print("- Include Customers: \(options.includeCustomers) -> \(data.customers.count)")
                print("- Include Products: \(options.includeProducts) -> \(data.products.count)")
                print("- Include Invoices: \(options.includeInvoices) -> \(data.invoices.count)")
                print("- Include Payment Methods: \(options.includePaymentMethods) -> \(data.paymentMethods.count)")
                print("- Include Company Info: \(options.includeCompanyInfo) -> \(data.company?.name ?? "nil")")
                
                return data
            }
            
            await MainActor.run {
                exportProgress = 0.3
            }
            
            // Generate file data based on format
            let fileData: Data
            switch options.format {
            case .json:
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .prettyPrinted
                fileData = try encoder.encode(exportData)
            case .csv:
                fileData = try generateCSV(from: exportData)
            case .pdf:
                fileData = try generatePDF(from: exportData)
            }
            
            await MainActor.run {
                exportProgress = 0.6
            }
            
            // Create file in cache directory with proper security attributes
            let fileName = "InvoicerApp_Export_\(DateFormatter.exportDateFormatter.string(from: Date())).\(options.format.fileExtension)"
            let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let tempURL = cacheURL.appendingPathComponent(fileName)
            
            // Remove file if it exists
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }
            
            // Write data with proper attributes
            try fileData.write(to: tempURL, options: [.atomic, .completeFileProtection])
            
            // Set proper file attributes for sharing
            let attributes: [FileAttributeKey: Any] = [
                .posixPermissions: 0o644,
                .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
            ]
            try FileManager.default.setAttributes(attributes, ofItemAtPath: tempURL.path)
            
            // Ensure file is properly saved and accessible
            let fileExists = FileManager.default.fileExists(atPath: tempURL.path)
            guard fileExists else {
                throw NSError(domain: "ExportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "File was not created successfully"])
            }
            
            // Verify file can be read
            let _ = try Data(contentsOf: tempURL)
            
            await MainActor.run {
                exportProgress = 1.0
                isExporting = false
            }
            
            return tempURL
            
        } catch {
            await MainActor.run {
                isExporting = false
                exportProgress = 0.0
            }
            print("Export failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Reset Functions
    
    func resetAllData(appState: AppState) async -> Bool {
        await MainActor.run {
            isResetting = true
        }
        
        do {
            // Reset all app data
            await MainActor.run {
                appState.company = nil
                appState.customers.removeAll()
                appState.products.removeAll()
                appState.invoices.removeAll()
                appState.paymentMethods.removeAll()
                appState.settings = AppSettings()
                appState.logoData = nil
                // Also remove logo from file system
                Storage.saveLogo(nil)
                
                // Data is automatically saved via didSet
            }
            
            await MainActor.run {
                isResetting = false
            }
            return true
            
        } catch {
            await MainActor.run {
                isResetting = false
            }
            print("Reset failed: \(error)")
            return false
        }
    }
    
    // MARK: - Import Functions
    
    func importData(from url: URL, appState: AppState) async -> Bool {
        do {
            let jsonData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let exportData = try decoder.decode(ExportData.self, from: jsonData)
            
            await MainActor.run {
                // Import data
                appState.company = exportData.company
                appState.customers = exportData.customers
                appState.products = exportData.products
                appState.invoices = exportData.invoices
                appState.paymentMethods = exportData.paymentMethods
                appState.settings = exportData.settings
                appState.logoData = exportData.logoData
                
                // Data is automatically saved via didSet
            }
            
            return true
            
        } catch {
            print("Import failed: \(error)")
            return false
        }
    }
    
    // MARK: - Format Generation Functions
    
    private func generateCSV(from exportData: ExportData) throws -> Data {
        var csvContent = ""
        
        // Add header
        csvContent += "Export Date,\(DateFormatter.exportDateFormatter.string(from: exportData.exportDate))\n"
        csvContent += "App Version,\(exportData.appVersion)\n\n"
        
        // Customers
        if !exportData.customers.isEmpty {
            csvContent += "CUSTOMERS\n"
            csvContent += "Name,Email,Phone,Address\n"
            for customer in exportData.customers {
                csvContent += "\"\(customer.name)\",\"\(customer.email)\",\"\(customer.phone)\",\"\(customer.address.oneLine)\"\n"
            }
            csvContent += "\n"
        } else {
            csvContent += "CUSTOMERS\n"
            csvContent += "Name,Email,Phone,Address\n"
            csvContent += "N/A,No customers found,N/A,N/A\n"
            csvContent += "\n"
        }
        
        // Products
        if !exportData.products.isEmpty {
            csvContent += "PRODUCTS\n"
            csvContent += "Name,Details,Rate,Category\n"
            for product in exportData.products {
                csvContent += "\"\(product.name)\",\"\(product.details)\",\(product.rate),\"\(product.category)\"\n"
            }
            csvContent += "\n"
        } else {
            csvContent += "PRODUCTS\n"
            csvContent += "Name,Details,Rate,Category\n"
            csvContent += "N/A,No products found,N/A,N/A\n"
            csvContent += "\n"
        }
        
        // Invoices
        if !exportData.invoices.isEmpty {
            csvContent += "INVOICES\n"
            csvContent += "Number,IssueDate,Customer,Total,Status\n"
            for invoice in exportData.invoices {
                csvContent += "\"\(invoice.number)\",\"\(DateFormatter.exportDateFormatter.string(from: invoice.issueDate))\",\"\(invoice.customer.name)\",\(invoice.subtotal),\"\(invoice.status.rawValue)\"\n"
            }
            csvContent += "\n"
        } else {
            csvContent += "INVOICES\n"
            csvContent += "Number,IssueDate,Customer,Total,Status\n"
            csvContent += "N/A,N/A,No invoices found,N/A,N/A\n"
            csvContent += "\n"
        }
        
        // Payment Methods
        if !exportData.paymentMethods.isEmpty {
            csvContent += "PAYMENT METHODS\n"
            csvContent += "Type\n"
            for method in exportData.paymentMethods {
                csvContent += "\"\(method.type)\"\n"
            }
            csvContent += "\n"
        } else {
            csvContent += "PAYMENT METHODS\n"
            csvContent += "Type\n"
            csvContent += "N/A - No payment methods found\n"
            csvContent += "\n"
        }
        
        // Company Info
        if let company = exportData.company {
            csvContent += "COMPANY INFO\n"
            csvContent += "Name,Email,Address,Phone\n"
            csvContent += "\"\(company.name)\",\"\(company.email)\",\"\(company.address.oneLine)\",\"\(company.phone)\"\n"
        } else {
            csvContent += "COMPANY INFO\n"
            csvContent += "Name,Email,Address,Phone\n"
            csvContent += "N/A,No company information found,N/A,N/A\n"
        }
        
        return csvContent.data(using: .utf8) ?? Data()
    }
    
    private func generatePDF(from exportData: ExportData) throws -> Data {
        print("PDF Generation Debug:")
        print("- Customers: \(exportData.customers.count)")
        print("- Products: \(exportData.products.count)")
        print("- Invoices: \(exportData.invoices.count)")
        print("- Payment Methods: \(exportData.paymentMethods.count)")
        print("- Company: \(exportData.company?.name ?? "nil")")
        
        // Create a simple text-based PDF using UIGraphicsImageRenderer
        let pageSize = CGSize(width: 612, height: 792)
        let renderer = UIGraphicsImageRenderer(size: pageSize)
        
        let image = renderer.image { context in
            // Fill background with white
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: pageSize))
            
            // Set up fonts
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let headerFont = UIFont.boldSystemFont(ofSize: 18)
            let bodyFont = UIFont.systemFont(ofSize: 12)
            
            var currentY: CGFloat = 50
            
            // Draw title
            let titleText = "INVOICERAPP EXPORT REPORT"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            let titleSize = titleText.size(withAttributes: titleAttributes)
            titleText.draw(at: CGPoint(x: (pageSize.width - titleSize.width) / 2, y: currentY), withAttributes: titleAttributes)
            currentY += 50
            
            // Draw export info
            let exportDateText = "Export Date: \(DateFormatter.exportDateFormatter.string(from: exportData.exportDate))"
            let appVersionText = "App Version: \(exportData.appVersion)"
            
            let infoAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: UIColor.darkGray
            ]
            
            exportDateText.draw(at: CGPoint(x: 50, y: currentY), withAttributes: infoAttributes)
            currentY += 25
            appVersionText.draw(at: CGPoint(x: 50, y: currentY), withAttributes: infoAttributes)
            currentY += 40
            
            // Draw summary
            let summaryText = "SUMMARY"
            let summaryAttributes: [NSAttributedString.Key: Any] = [
                .font: headerFont,
                .foregroundColor: UIColor.black
            ]
            summaryText.draw(at: CGPoint(x: 50, y: currentY), withAttributes: summaryAttributes)
            currentY += 30
            
            let summaryItems = [
                "• Customers: \(exportData.customers.count)",
                "• Products: \(exportData.products.count)",
                "• Invoices: \(exportData.invoices.count)",
                "• Payment Methods: \(exportData.paymentMethods.count)"
            ]
            
            for item in summaryItems {
                item.draw(at: CGPoint(x: 70, y: currentY), withAttributes: infoAttributes)
                currentY += 20
            }
            currentY += 20
            
            // Draw customers section
            if !exportData.customers.isEmpty {
                currentY = drawSimpleSectionInContext(title: "CUSTOMERS", items: exportData.customers.map { "• \($0.name) - \($0.email)" }, currentY: currentY, headerFont: headerFont, bodyFont: bodyFont)
            } else {
                currentY = drawSimpleSectionInContext(title: "CUSTOMERS", items: ["• N/A - No customers found"], currentY: currentY, headerFont: headerFont, bodyFont: bodyFont)
            }
            
            // Draw products section
            if !exportData.products.isEmpty {
                currentY = drawSimpleSectionInContext(title: "PRODUCTS", items: exportData.products.map { "• \($0.name) - \($0.rate) (\($0.category))" }, currentY: currentY, headerFont: headerFont, bodyFont: bodyFont)
            } else {
                currentY = drawSimpleSectionInContext(title: "PRODUCTS", items: ["• N/A - No products found"], currentY: currentY, headerFont: headerFont, bodyFont: bodyFont)
            }
            
            // Draw invoices section
            if !exportData.invoices.isEmpty {
                currentY = drawSimpleSectionInContext(title: "INVOICES", items: exportData.invoices.map { "• \($0.number) - \($0.customer.name) - \($0.subtotal) (\($0.status.rawValue))" }, currentY: currentY, headerFont: headerFont, bodyFont: bodyFont)
            } else {
                currentY = drawSimpleSectionInContext(title: "INVOICES", items: ["• N/A - No invoices found"], currentY: currentY, headerFont: headerFont, bodyFont: bodyFont)
            }
            
            // Draw payment methods section
            if !exportData.paymentMethods.isEmpty {
                currentY = drawSimpleSectionInContext(title: "PAYMENT METHODS", items: exportData.paymentMethods.map { "• \($0.type)" }, currentY: currentY, headerFont: headerFont, bodyFont: bodyFont)
            } else {
                currentY = drawSimpleSectionInContext(title: "PAYMENT METHODS", items: ["• N/A - No payment methods found"], currentY: currentY, headerFont: headerFont, bodyFont: bodyFont)
            }
            
            // Draw company info
            if let company = exportData.company {
                let companyItems = [
                    "• Name: \(company.name)",
                    "• Email: \(company.email)",
                    "• Address: \(company.address.oneLine)",
                    "• Phone: \(company.phone)"
                ]
                currentY = drawSimpleSectionInContext(title: "COMPANY INFO", items: companyItems, currentY: currentY, headerFont: headerFont, bodyFont: bodyFont)
            } else {
                currentY = drawSimpleSectionInContext(title: "COMPANY INFO", items: ["• N/A - No company information found"], currentY: currentY, headerFont: headerFont, bodyFont: bodyFont)
            }
        }
        
        // Convert image to PDF
        let pdfData = NSMutableData()
        let pdfConsumer = CGDataConsumer(data: pdfData)!
        let mediaBox = CGRect(origin: .zero, size: pageSize)
        var mediaBoxVar = mediaBox
        let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBoxVar, nil)!
        
        pdfContext.beginPage(mediaBox: &mediaBoxVar)
        pdfContext.draw(image.cgImage!, in: CGRect(origin: .zero, size: pageSize))
        pdfContext.endPage()
        pdfContext.closePDF()
        
        return pdfData as Data
    }
    
    // MARK: - Simple Drawing Functions
    
    private func drawSimpleSectionInContext(title: String, items: [String], currentY: CGFloat, headerFont: UIFont, bodyFont: UIFont) -> CGFloat {
        var y = currentY
        
        // Draw section title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.black
        ]
        title.draw(at: CGPoint(x: 50, y: y), withAttributes: titleAttributes)
        y += 30
        
        // Draw items
        let itemAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: UIColor.darkGray
        ]
        
        for item in items {
            print("Drawing item: '\(item)' at y: \(y)")
            item.draw(at: CGPoint(x: 70, y: y), withAttributes: itemAttributes)
            y += 20
        }
        
        y += 20
        return y
    }
    
}

// MARK: - Export Data Structure

struct ExportData: Codable {
    let company: Company?
    let customers: [Customer]
    let products: [Product]
    let invoices: [Invoice]
    let paymentMethods: [PaymentMethod]
    let settings: AppSettings
    let logoData: Data?
    let exportDate: Date
    let appVersion: String
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let exportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}

