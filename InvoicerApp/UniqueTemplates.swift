//
//  UniqueTemplates.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/29/25.
//

import SwiftUI
import UIKit

// MARK: - Template Renderer Protocol

protocol TemplateRenderer {
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?)
}

// MARK: - Modern Clean Template

struct ModernCleanTemplate: TemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        
        // Header with logo and company info
        drawHeader(context: context, page: page, company: company, logo: logo, primary: primary)
        
        // Invoice title and number
        drawInvoiceTitle(context: context, page: page, invoice: invoice, primary: primary)
        
        // Bill to section
        drawBillToSection(context: context, page: page, customer: customer, primary: primary)
        
        // Items table
        drawItemsTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary)
        
        // Total section
        drawTotalSection(context: context, page: page, invoice: invoice, currency: currency, primary: primary)
        
        // Footer
        drawFooter(context: context, page: page, company: company, primary: primary)
    }
    
    private func drawHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor) {
        // Logo area
        if let logo = logo {
            let logoRect = CGRect(x: 50, y: 50, width: 80, height: 80)
            logo.draw(in: logoRect)
        }
        
        // Company name
        let companyNameFont = UIFont.systemFont(ofSize: 24, weight: .bold)
        let companyNameAttributes: [NSAttributedString.Key: Any] = [
            .font: companyNameFont,
            .foregroundColor: primary
        ]
        let companyNameText = NSAttributedString(string: company.name, attributes: companyNameAttributes)
        let companyNameRect = CGRect(x: 150, y: 60, width: page.width - 200, height: 30)
        companyNameText.draw(in: companyNameRect)
        
        // Company details
        let detailsFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let detailsAttributes: [NSAttributedString.Key: Any] = [
            .font: detailsFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset: CGFloat = 100
        if !company.address.oneLine.isEmpty {
            let addressText = NSAttributedString(string: company.address.oneLine, attributes: detailsAttributes)
            let addressRect = CGRect(x: 150, y: yOffset, width: page.width - 200, height: 20)
            addressText.draw(in: addressRect)
            yOffset += 20
        }
        
        if !company.email.isEmpty {
            let emailText = NSAttributedString(string: company.email, attributes: detailsAttributes)
            let emailRect = CGRect(x: 150, y: yOffset, width: page.width - 200, height: 20)
            emailText.draw(in: emailRect)
        }
    }
    
    private func drawInvoiceTitle(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor) {
        let titleFont = UIFont.systemFont(ofSize: 32, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: primary
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 200, y: 50, width: 150, height: 40)
        titleText.draw(in: titleRect)
        
        let numberFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: UIColor.label
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 200, y: 90, width: 150, height: 20)
        numberText.draw(in: numberRect)
    }
    
    private func drawBillToSection(context: CGContext, page: CGRect, customer: Customer, primary: UIColor) {
        let billToFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "Bill To:", attributes: billToAttributes)
        let billToRect = CGRect(x: 50, y: 200, width: 100, height: 20)
        billToText.draw(in: billToRect)
        
        let customerFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let customerAttributes: [NSAttributedString.Key: Any] = [
            .font: customerFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset: CGFloat = 230
        let customerNameText = NSAttributedString(string: customer.name, attributes: customerAttributes)
        let customerNameRect = CGRect(x: 50, y: yOffset, width: 200, height: 20)
        customerNameText.draw(in: customerNameRect)
        yOffset += 20
        
        if !customer.address.oneLine.isEmpty {
            let addressText = NSAttributedString(string: customer.address.oneLine, attributes: customerAttributes)
            let addressRect = CGRect(x: 50, y: yOffset, width: 200, height: 20)
            addressText.draw(in: addressRect)
            yOffset += 20
        }
        
        if !customer.email.isEmpty {
            let emailText = NSAttributedString(string: customer.email, attributes: customerAttributes)
            let emailRect = CGRect(x: 50, y: yOffset, width: 200, height: 20)
            emailText.draw(in: emailRect)
        }
    }
    
    private func drawItemsTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, secondary: UIColor) {
        let startY: CGFloat = 320
        
        // Table header
        let headerFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white
        ]
        
        // Header background
        let headerRect = CGRect(x: 50, y: startY, width: page.width - 100, height: 30)
        context.setFillColor(primary.cgColor)
        context.fill(headerRect)
        
        // Header text
        let headers = ["Description", "Qty", "Rate", "Amount"]
        let columnWidths: [CGFloat] = [300, 80, 100, 100]
        var xOffset: CGFloat = 60
        
        for (index, header) in headers.enumerated() {
            let headerText = NSAttributedString(string: header, attributes: headerAttributes)
            let headerTextRect = CGRect(x: xOffset, y: startY + 8, width: columnWidths[index], height: 20)
            headerText.draw(in: headerTextRect)
            xOffset += columnWidths[index]
        }
        
        // Table rows
        let rowFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset = startY + 30
        for item in invoice.items {
            // Row background (alternating)
            if Int(yOffset - startY - 30) % 60 == 0 {
                let rowRect = CGRect(x: 50, y: yOffset, width: page.width - 100, height: 30)
                context.setFillColor(UIColor.lightGray.cgColor)
                context.fill(rowRect)
            }
            
            // Row content
            xOffset = 60
            let itemText = NSAttributedString(string: item.description, attributes: rowAttributes)
            let itemRect = CGRect(x: xOffset, y: yOffset + 8, width: columnWidths[0], height: 20)
            itemText.draw(in: itemRect)
            xOffset += columnWidths[0]
            
            let qtyText = NSAttributedString(string: "\(item.quantity)", attributes: rowAttributes)
            let qtyRect = CGRect(x: xOffset, y: yOffset + 8, width: columnWidths[1], height: 20)
            qtyText.draw(in: qtyRect)
            xOffset += columnWidths[1]
            
            let rateText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.rate as NSDecimalNumber)))", attributes: rowAttributes)
            let rateRect = CGRect(x: xOffset, y: yOffset + 8, width: columnWidths[2], height: 20)
            rateText.draw(in: rateRect)
            xOffset += columnWidths[2]
            
            let amountText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.total as NSDecimalNumber)))", attributes: rowAttributes)
            let amountRect = CGRect(x: xOffset, y: yOffset + 8, width: columnWidths[3], height: 20)
            amountText.draw(in: amountRect)
            
            yOffset += 30
        }
    }
    
    private func drawTotalSection(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor) {
        let totalY: CGFloat = 500
        
        // Total background
        let totalRect = CGRect(x: page.width - 250, y: totalY, width: 200, height: 40)
        context.setFillColor(primary.cgColor)
        context.fill(totalRect)
        
        // Total text
        let totalFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "Total: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 240, y: totalY + 10, width: 180, height: 20)
        totalText.draw(in: totalTextRect)
    }
    
    private func drawFooter(context: CGContext, page: CGRect, company: Company, primary: UIColor) {
        let footerFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = NSAttributedString(string: "Thank you for your business!", attributes: footerAttributes)
        let footerRect = CGRect(x: 50, y: page.height - 50, width: page.width - 100, height: 20)
        footerText.draw(in: footerRect)
    }
}

// MARK: - Minimal Professional Template

struct MinimalProfessionalTemplate: TemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        
        // Minimal header - just company name and invoice number
        drawMinimalHeader(context: context, page: page, company: company, invoice: invoice, primary: primary)
        
        // Clean bill to section
        drawCleanBillTo(context: context, page: page, customer: customer, primary: primary)
        
        // Minimal items table
        drawMinimalItemsTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary)
        
        // Simple total
        drawSimpleTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary)
    }
    
    private func drawMinimalHeader(context: CGContext, page: CGRect, company: Company, invoice: Invoice, primary: UIColor) {
        // Company name - large and clean
        let companyFont = UIFont.systemFont(ofSize: 28, weight: .light)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: UIColor.label
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 60, y: 60, width: page.width - 120, height: 35)
        companyText.draw(in: companyRect)
        
        // Invoice number - small and subtle
        let invoiceFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        let invoiceAttributes: [NSAttributedString.Key: Any] = [
            .font: invoiceFont,
            .foregroundColor: UIColor.secondaryLabel
        ]
        let invoiceText = NSAttributedString(string: "Invoice #\(invoice.number)", attributes: invoiceAttributes)
        let invoiceRect = CGRect(x: 60, y: 100, width: page.width - 120, height: 20)
        invoiceText.draw(in: invoiceRect)
        
        // Thin line separator
        context.setStrokeColor(primary.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: 60, y: 130))
        context.addLine(to: CGPoint(x: page.width - 60, y: 130))
        context.strokePath()
    }
    
    private func drawCleanBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor) {
        let billToFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "Bill to", attributes: billToAttributes)
        let billToRect = CGRect(x: 60, y: 160, width: 100, height: 20)
        billToText.draw(in: billToRect)
        
        let customerFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        let customerAttributes: [NSAttributedString.Key: Any] = [
            .font: customerFont,
            .foregroundColor: UIColor.label
        ]
        
        var yOffset: CGFloat = 190
        let customerNameText = NSAttributedString(string: customer.name, attributes: customerAttributes)
        let customerNameRect = CGRect(x: 60, y: yOffset, width: 300, height: 20)
        customerNameText.draw(in: customerNameRect)
        yOffset += 25
        
        if !customer.address.oneLine.isEmpty {
            let addressText = NSAttributedString(string: customer.address.oneLine, attributes: customerAttributes)
            let addressRect = CGRect(x: 60, y: yOffset, width: 300, height: 20)
            addressText.draw(in: addressRect)
            yOffset += 25
        }
        
        if !customer.email.isEmpty {
            let emailText = NSAttributedString(string: customer.email, attributes: customerAttributes)
            let emailRect = CGRect(x: 60, y: yOffset, width: 300, height: 20)
            emailText.draw(in: emailRect)
        }
    }
    
    private func drawMinimalItemsTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor) {
        let startY: CGFloat = 280
        
        // No header background - just text
        let headerFont = UIFont.systemFont(ofSize: 11, weight: .medium)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: primary
        ]
        
        let headers = ["Item", "Qty", "Rate", "Total"]
        let columnWidths: [CGFloat] = [350, 60, 80, 80]
        var xOffset: CGFloat = 60
        
        for (index, header) in headers.enumerated() {
            let headerText = NSAttributedString(string: header, attributes: headerAttributes)
            let headerTextRect = CGRect(x: xOffset, y: startY, width: columnWidths[index], height: 20)
            headerText.draw(in: headerTextRect)
            xOffset += columnWidths[index]
        }
        
        // Thin line under headers
        context.setStrokeColor(primary.withAlphaComponent(0.2).cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: 60, y: startY + 25))
        context.addLine(to: CGPoint(x: page.width - 60, y: startY + 25))
        context.strokePath()
        
        // Table rows
        let rowFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.label
        ]
        
        var yOffset = startY + 35
        for item in invoice.items {
            xOffset = 60
            
            let itemText = NSAttributedString(string: item.description, attributes: rowAttributes)
            let itemRect = CGRect(x: xOffset, y: yOffset, width: columnWidths[0], height: 20)
            itemText.draw(in: itemRect)
            xOffset += columnWidths[0]
            
            let qtyText = NSAttributedString(string: "\(item.quantity)", attributes: rowAttributes)
            let qtyRect = CGRect(x: xOffset, y: yOffset, width: columnWidths[1], height: 20)
            qtyText.draw(in: qtyRect)
            xOffset += columnWidths[1]
            
            let rateText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.rate as NSDecimalNumber)))", attributes: rowAttributes)
            let rateRect = CGRect(x: xOffset, y: yOffset, width: columnWidths[2], height: 20)
            rateText.draw(in: rateRect)
            xOffset += columnWidths[2]
            
            let amountText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.total as NSDecimalNumber)))", attributes: rowAttributes)
            let amountRect = CGRect(x: xOffset, y: yOffset, width: columnWidths[3], height: 20)
            amountText.draw(in: amountRect)
            
            yOffset += 25
        }
    }
    
    private func drawSimpleTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor) {
        let totalY: CGFloat = 450
        
        // Simple total text
        let totalFont = UIFont.systemFont(ofSize: 18, weight: .medium)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.label
        ]
        let totalText = NSAttributedString(string: "Total: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalRect = CGRect(x: page.width - 200, y: totalY, width: 140, height: 25)
        totalText.draw(in: totalRect)
    }
}

// MARK: - Corporate Formal Template

struct CorporateFormalTemplate: TemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        
        // Formal header with border
        drawFormalHeader(context: context, page: page, company: company, logo: logo, primary: primary, secondary: secondary)
        
        // Invoice details in formal box
        drawFormalInvoiceDetails(context: context, page: page, invoice: invoice, primary: primary)
        
        // Bill to section with formal styling
        drawFormalBillTo(context: context, page: page, customer: customer, primary: primary)
        
        // Formal table with borders
        drawFormalTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary)
        
        // Formal total section
        drawFormalTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary)
        
        // Formal footer
        drawFormalFooter(context: context, page: page, company: company, primary: primary)
    }
    
    private func drawFormalHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor) {
        // Header border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(3)
        let headerRect = CGRect(x: 40, y: 40, width: page.width - 80, height: 100)
        context.stroke(headerRect)
        
        // Logo
        if let logo = logo {
            let logoRect = CGRect(x: 60, y: 60, width: 60, height: 60)
            context.saveGState()
            context.clip(to: logoRect)
            logo.draw(in: logoRect)
            context.restoreGState()
        }
        
        // Company name - formal serif style
        let companyFont = UIFont.systemFont(ofSize: 22, weight: .bold)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: primary
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 140, y: 70, width: page.width - 200, height: 30)
        companyText.draw(in: companyRect)
        
        // Company details in formal style
        let detailsFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        let detailsAttributes: [NSAttributedString.Key: Any] = [
            .font: detailsFont,
            .foregroundColor: UIColor.label
        ]
        
        var yOffset: CGFloat = 100
        if !company.address.oneLine.isEmpty {
            let addressText = NSAttributedString(string: company.address.oneLine, attributes: detailsAttributes)
            let addressRect = CGRect(x: 140, y: yOffset, width: page.width - 200, height: 15)
            addressText.draw(in: addressRect)
            yOffset += 15
        }
        
        if !company.email.isEmpty {
            let emailText = NSAttributedString(string: company.email, attributes: detailsAttributes)
            let emailRect = CGRect(x: 140, y: yOffset, width: page.width - 200, height: 15)
            emailText.draw(in: emailRect)
        }
    }
    
    private func drawFormalInvoiceDetails(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor) {
        // Invoice details box
        let detailsRect = CGRect(x: page.width - 200, y: 60, width: 150, height: 60)
        context.setStrokeColor(primary.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(1)
        context.stroke(detailsRect)
        
        // Invoice title
        let titleFont = UIFont.systemFont(ofSize: 16, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: primary
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 190, y: 70, width: 130, height: 20)
        titleText.draw(in: titleRect)
        
        // Invoice number
        let numberFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: UIColor.label
        ]
        let numberText = NSAttributedString(string: "Number: \(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 190, y: 95, width: 130, height: 15)
        numberText.draw(in: numberRect)
        
        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateText = NSAttributedString(string: "Date: \(dateFormatter.string(from: invoice.issueDate))", attributes: numberAttributes)
        let dateRect = CGRect(x: page.width - 190, y: 110, width: 130, height: 15)
        dateText.draw(in: dateRect)
    }
    
    private func drawFormalBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor) {
        // Bill to section with border
        let billToRect = CGRect(x: 50, y: 180, width: 250, height: 80)
        context.setStrokeColor(primary.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(1)
        context.stroke(billToRect)
        
        // Bill to title
        let billToFont = UIFont.systemFont(ofSize: 12, weight: .bold)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "BILL TO:", attributes: billToAttributes)
        let billToTextRect = CGRect(x: 60, y: 190, width: 100, height: 20)
        billToText.draw(in: billToTextRect)
        
        // Customer details
        let customerFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        let customerAttributes: [NSAttributedString.Key: Any] = [
            .font: customerFont,
            .foregroundColor: UIColor.label
        ]
        
        var yOffset: CGFloat = 215
        let customerNameText = NSAttributedString(string: customer.name, attributes: customerAttributes)
        let customerNameRect = CGRect(x: 60, y: yOffset, width: 230, height: 15)
        customerNameText.draw(in: customerNameRect)
        yOffset += 15
        
        if !customer.address.oneLine.isEmpty {
            let addressText = NSAttributedString(string: customer.address.oneLine, attributes: customerAttributes)
            let addressRect = CGRect(x: 60, y: yOffset, width: 230, height: 15)
            addressText.draw(in: addressRect)
            yOffset += 15
        }
        
        if !customer.email.isEmpty {
            let emailText = NSAttributedString(string: customer.email, attributes: customerAttributes)
            let emailRect = CGRect(x: 60, y: yOffset, width: 230, height: 15)
            emailText.draw(in: emailRect)
        }
    }
    
    private func drawFormalTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, secondary: UIColor) {
        let startY: CGFloat = 300
        
        // Table with full borders
        let tableRect = CGRect(x: 50, y: startY, width: page.width - 100, height: 200)
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(1)
        context.stroke(tableRect)
        
        // Header row
        let headerRect = CGRect(x: 50, y: startY, width: page.width - 100, height: 30)
        context.setFillColor(primary.withAlphaComponent(0.1).cgColor)
        context.fill(headerRect)
        
        // Header text
        let headerFont = UIFont.systemFont(ofSize: 11, weight: .bold)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: primary
        ]
        
        let headers = ["Description", "Qty", "Unit Price", "Total"]
        let columnWidths: [CGFloat] = [300, 80, 100, 100]
        var xOffset: CGFloat = 60
        
        for (index, header) in headers.enumerated() {
            let headerText = NSAttributedString(string: header, attributes: headerAttributes)
            let headerTextRect = CGRect(x: xOffset, y: startY + 8, width: columnWidths[index], height: 20)
            headerText.draw(in: headerTextRect)
            
            // Vertical lines
            if index < headers.count - 1 {
                context.setStrokeColor(primary.withAlphaComponent(0.3).cgColor)
                context.setLineWidth(0.5)
                context.move(to: CGPoint(x: xOffset + columnWidths[index], y: startY))
                context.addLine(to: CGPoint(x: xOffset + columnWidths[index], y: startY + 200))
                context.strokePath()
            }
            
            xOffset += columnWidths[index]
        }
        
        // Table rows with borders
        let rowFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.label
        ]
        
        var yOffset = startY + 30
        for (index, item) in invoice.items.enumerated() {
            // Horizontal line
            context.setStrokeColor(primary.withAlphaComponent(0.2).cgColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: 50, y: yOffset))
            context.addLine(to: CGPoint(x: page.width - 50, y: yOffset))
            context.strokePath()
            
            // Row content
            xOffset = 60
            
            let itemText = NSAttributedString(string: item.description, attributes: rowAttributes)
            let itemRect = CGRect(x: xOffset, y: yOffset + 5, width: columnWidths[0], height: 20)
            itemText.draw(in: itemRect)
            xOffset += columnWidths[0]
            
            let qtyText = NSAttributedString(string: "\(item.quantity)", attributes: rowAttributes)
            let qtyRect = CGRect(x: xOffset, y: yOffset + 5, width: columnWidths[1], height: 20)
            qtyText.draw(in: qtyRect)
            xOffset += columnWidths[1]
            
            let rateText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.rate as NSDecimalNumber)))", attributes: rowAttributes)
            let rateRect = CGRect(x: xOffset, y: yOffset + 5, width: columnWidths[2], height: 20)
            rateText.draw(in: rateRect)
            xOffset += columnWidths[2]
            
            let amountText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.total as NSDecimalNumber)))", attributes: rowAttributes)
            let amountRect = CGRect(x: xOffset, y: yOffset + 5, width: columnWidths[3], height: 20)
            amountText.draw(in: amountRect)
            
            yOffset += 25
        }
    }
    
    private func drawFormalTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor) {
        let totalY: CGFloat = 520
        
        // Total box with border
        let totalRect = CGRect(x: page.width - 200, y: totalY, width: 150, height: 40)
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(2)
        context.stroke(totalRect)
        
        // Total background
        context.setFillColor(primary.withAlphaComponent(0.05).cgColor)
        context.fill(totalRect)
        
        // Total text
        let totalFont = UIFont.systemFont(ofSize: 14, weight: .bold)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: primary
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 190, y: totalY + 10, width: 130, height: 20)
        totalText.draw(in: totalTextRect)
    }
    
    private func drawFormalFooter(context: CGContext, page: CGRect, company: Company, primary: UIColor) {
        // Footer line
        context.setStrokeColor(primary.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: 50, y: page.height - 80))
        context.addLine(to: CGPoint(x: page.width - 50, y: page.height - 80))
        context.strokePath()
        
        // Footer text
        let footerFont = UIFont.systemFont(ofSize: 9, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        let footerText = NSAttributedString(string: "This invoice was generated by \(company.name). Thank you for your business.", attributes: footerAttributes)
        let footerRect = CGRect(x: 50, y: page.height - 60, width: page.width - 100, height: 15)
        footerText.draw(in: footerRect)
    }
}

// MARK: - Creative Vibrant Template

struct CreativeVibrantTemplate: TemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent
        
        // Creative header with gradient
        drawCreativeHeader(context: context, page: page, company: company, logo: logo, primary: primary, secondary: secondary, accent: accent)
        
        // Creative invoice section
        drawCreativeInvoiceSection(context: context, page: page, invoice: invoice, primary: primary, accent: accent)
        
        // Creative bill to
        drawCreativeBillTo(context: context, page: page, customer: customer, primary: primary, secondary: secondary)
        
        // Creative items table
        drawCreativeTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary, accent: accent)
        
        // Creative total
        drawCreativeTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
    }
    
    private func drawCreativeHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Creative gradient background
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 120)
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: [primary.cgColor, secondary.cgColor, accent.cgColor] as CFArray,
                                 locations: [0.0, 0.5, 1.0])!
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: page.width, y: 0), options: [])
        
        // Logo with creative styling
        if let logo = logo {
            let logoRect = CGRect(x: 30, y: 30, width: 60, height: 60)
            context.saveGState()
            context.clip(to: logoRect)
            logo.draw(in: logoRect)
            context.restoreGState()
        }
        
        // Company name with creative font
        let companyFont = UIFont.systemFont(ofSize: 26, weight: .black)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: UIColor.white
        ]
        let companyText = NSAttributedString(string: company.name.uppercased(), attributes: companyAttributes)
        let companyRect = CGRect(x: 110, y: 40, width: page.width - 140, height: 35)
        companyText.draw(in: companyRect)
        
        // Creative tagline
        let taglineFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: UIColor.white.withAlphaComponent(0.8)
        ]
        let taglineText = NSAttributedString(string: "CREATIVE SOLUTIONS", attributes: taglineAttributes)
        let taglineRect = CGRect(x: 110, y: 75, width: page.width - 140, height: 20)
        taglineText.draw(in: taglineRect)
    }
    
    private func drawCreativeInvoiceSection(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor, accent: UIColor) {
        // Creative invoice box
        let invoiceRect = CGRect(x: page.width - 180, y: 150, width: 130, height: 60)
        
        // Rounded corners effect
        context.setFillColor(accent.withAlphaComponent(0.1).cgColor)
        context.fill(invoiceRect)
        
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(2)
        context.stroke(invoiceRect)
        
        // Invoice title with creative styling
        let titleFont = UIFont.systemFont(ofSize: 18, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: accent
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 170, y: 160, width: 110, height: 25)
        titleText.draw(in: titleRect)
        
        // Invoice number with creative styling
        let numberFont = UIFont.systemFont(ofSize: 14, weight: .heavy)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: primary
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 170, y: 185, width: 110, height: 20)
        numberText.draw(in: numberRect)
    }
    
    private func drawCreativeBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor, secondary: UIColor) {
        // Creative bill to section
        let billToRect = CGRect(x: 30, y: 150, width: 300, height: 80)
        
        // Creative background
        context.setFillColor(primary.withAlphaComponent(0.05).cgColor)
        context.fill(billToRect)
        
        // Creative border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(2)
        context.stroke(billToRect)
        
        // Bill to title with creative styling
        let billToFont = UIFont.systemFont(ofSize: 14, weight: .bold)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "BILL TO:", attributes: billToAttributes)
        let billToTextRect = CGRect(x: 40, y: 160, width: 100, height: 20)
        billToText.draw(in: billToTextRect)
        
        // Customer details with creative styling
        let customerFont = UIFont.systemFont(ofSize: 13, weight: .semibold)
        let customerAttributes: [NSAttributedString.Key: Any] = [
            .font: customerFont,
            .foregroundColor: UIColor.label
        ]
        
        var yOffset: CGFloat = 185
        let customerNameText = NSAttributedString(string: customer.name, attributes: customerAttributes)
        let customerNameRect = CGRect(x: 40, y: yOffset, width: 280, height: 20)
        customerNameText.draw(in: customerNameRect)
        yOffset += 20
        
        if !customer.address.oneLine.isEmpty {
            let addressText = NSAttributedString(string: customer.address.oneLine, attributes: customerAttributes)
            let addressRect = CGRect(x: 40, y: yOffset, width: 280, height: 20)
            addressText.draw(in: addressRect)
            yOffset += 20
        }
        
        if !customer.email.isEmpty {
            let emailText = NSAttributedString(string: customer.email, attributes: customerAttributes)
            let emailRect = CGRect(x: 40, y: yOffset, width: 280, height: 20)
            emailText.draw(in: emailRect)
        }
    }
    
    private func drawCreativeTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, secondary: UIColor, accent: UIColor) {
        let startY: CGFloat = 260
        
        // Creative table header
        let headerRect = CGRect(x: 30, y: startY, width: page.width - 60, height: 35)
        
        // Gradient header background
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: [primary.cgColor, secondary.cgColor] as CFArray,
                                 locations: [0.0, 1.0])!
        context.drawLinearGradient(gradient, start: CGPoint(x: 30, y: startY), end: CGPoint(x: page.width - 30, y: startY), options: [])
        
        // Header text
        let headerFont = UIFont.systemFont(ofSize: 12, weight: .bold)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white
        ]
        
        let headers = ["Description", "Qty", "Rate", "Amount"]
        let columnWidths: [CGFloat] = [320, 70, 90, 90]
        var xOffset: CGFloat = 40
        
        for (index, header) in headers.enumerated() {
            let headerText = NSAttributedString(string: header, attributes: headerAttributes)
            let headerTextRect = CGRect(x: xOffset, y: startY + 10, width: columnWidths[index], height: 20)
            headerText.draw(in: headerTextRect)
            xOffset += columnWidths[index]
        }
        
        // Creative table rows
        let rowFont = UIFont.systemFont(ofSize: 11, weight: .medium)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.label
        ]
        
        var yOffset = startY + 35
        for (index, item) in invoice.items.enumerated() {
            // Alternating row colors
            if index % 2 == 0 {
                let rowRect = CGRect(x: 30, y: yOffset, width: page.width - 60, height: 30)
                context.setFillColor(accent.withAlphaComponent(0.05).cgColor)
                context.fill(rowRect)
            }
            
            // Row content
            xOffset = 40
            
            let itemText = NSAttributedString(string: item.description, attributes: rowAttributes)
            let itemRect = CGRect(x: xOffset, y: yOffset + 8, width: columnWidths[0], height: 20)
            itemText.draw(in: itemRect)
            xOffset += columnWidths[0]
            
            let qtyText = NSAttributedString(string: "\(item.quantity)", attributes: rowAttributes)
            let qtyRect = CGRect(x: xOffset, y: yOffset + 8, width: columnWidths[1], height: 20)
            qtyText.draw(in: qtyRect)
            xOffset += columnWidths[1]
            
            let rateText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.rate as NSDecimalNumber)))", attributes: rowAttributes)
            let rateRect = CGRect(x: xOffset, y: yOffset + 8, width: columnWidths[2], height: 20)
            rateText.draw(in: rateRect)
            xOffset += columnWidths[2]
            
            let amountText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.total as NSDecimalNumber)))", attributes: rowAttributes)
            let amountRect = CGRect(x: xOffset, y: yOffset + 8, width: columnWidths[3], height: 20)
            amountText.draw(in: amountRect)
            
            yOffset += 30
        }
    }
    
    private func drawCreativeTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, accent: UIColor) {
        let totalY: CGFloat = 450
        
        // Creative total box
        let totalRect = CGRect(x: page.width - 200, y: totalY, width: 150, height: 50)
        
        // Creative gradient background
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: [accent.cgColor, primary.cgColor] as CFArray,
                                 locations: [0.0, 1.0])!
        context.drawLinearGradient(gradient, start: CGPoint(x: page.width - 200, y: totalY), end: CGPoint(x: page.width - 50, y: totalY), options: [])
        
        // Creative border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(3)
        context.stroke(totalRect)
        
        // Total text with creative styling
        let totalFont = UIFont.systemFont(ofSize: 16, weight: .black)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 190, y: totalY + 15, width: 130, height: 20)
        totalText.draw(in: totalTextRect)
    }
}

// MARK: - Executive Luxury Template

struct ExecutiveLuxuryTemplate: TemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent
        
        // Luxury header with gold accents
        drawLuxuryHeader(context: context, page: page, company: company, logo: logo, primary: primary, secondary: secondary, accent: accent)
        
        // Executive invoice section
        drawExecutiveInvoiceSection(context: context, page: page, invoice: invoice, primary: primary, accent: accent)
        
        // Luxury bill to section
        drawLuxuryBillTo(context: context, page: page, customer: customer, primary: primary, accent: accent)
        
        // Executive table
        drawExecutiveTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary, accent: accent)
        
        // Luxury total
        drawLuxuryTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
    }
    
    private func drawLuxuryHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Luxury background with subtle pattern
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 140)
        context.setFillColor(primary.withAlphaComponent(0.05).cgColor)
        context.fill(headerRect)
        
        // Luxury border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(4)
        context.stroke(headerRect)
        
        // Logo with luxury frame
        if let logo = logo {
            let logoRect = CGRect(x: 40, y: 40, width: 80, height: 80)
            // Luxury frame around logo
            context.setStrokeColor(accent.cgColor)
            context.setLineWidth(3)
            context.stroke(logoRect)
            context.saveGState()
            context.clip(to: logoRect)
            logo.draw(in: logoRect)
            context.restoreGState()
        }
        
        // Company name with luxury styling
        let companyFont = UIFont.systemFont(ofSize: 28, weight: .bold)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: primary
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 140, y: 50, width: page.width - 200, height: 35)
        companyText.draw(in: companyRect)
        
        // Luxury tagline
        let taglineFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: accent
        ]
        let taglineText = NSAttributedString(string: "EXECUTIVE SERVICES", attributes: taglineAttributes)
        let taglineRect = CGRect(x: 140, y: 85, width: page.width - 200, height: 20)
        taglineText.draw(in: taglineRect)
        
        // Company details with luxury styling
        let detailsFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let detailsAttributes: [NSAttributedString.Key: Any] = [
            .font: detailsFont,
            .foregroundColor: UIColor.label
        ]
        
        var yOffset: CGFloat = 110
        if !company.address.oneLine.isEmpty {
            let addressText = NSAttributedString(string: company.address.oneLine, attributes: detailsAttributes)
            let addressRect = CGRect(x: 140, y: yOffset, width: page.width - 200, height: 20)
            addressText.draw(in: addressRect)
            yOffset += 20
        }
        
        if !company.email.isEmpty {
            let emailText = NSAttributedString(string: company.email, attributes: detailsAttributes)
            let emailRect = CGRect(x: 140, y: yOffset, width: page.width - 200, height: 20)
            emailText.draw(in: emailRect)
        }
    }
    
    private func drawExecutiveInvoiceSection(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor, accent: UIColor) {
        // Executive invoice box with luxury styling
        let invoiceRect = CGRect(x: page.width - 220, y: 50, width: 160, height: 80)
        
        // Luxury background
        context.setFillColor(accent.withAlphaComponent(0.1).cgColor)
        context.fill(invoiceRect)
        
        // Luxury border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(2)
        context.stroke(invoiceRect)
        
        // Invoice title with executive styling
        let titleFont = UIFont.systemFont(ofSize: 20, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: accent
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 210, y: 60, width: 140, height: 25)
        titleText.draw(in: titleRect)
        
        // Invoice number with luxury styling
        let numberFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: primary
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 210, y: 90, width: 140, height: 20)
        numberText.draw(in: numberRect)
        
        // Date with luxury styling
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let dateText = NSAttributedString(string: dateFormatter.string(from: invoice.issueDate), attributes: numberAttributes)
        let dateRect = CGRect(x: page.width - 210, y: 110, width: 140, height: 20)
        dateText.draw(in: dateRect)
    }
    
    private func drawLuxuryBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor, accent: UIColor) {
        // Luxury bill to section
        let billToRect = CGRect(x: 40, y: 180, width: 350, height: 100)
        
        // Luxury background
        context.setFillColor(primary.withAlphaComponent(0.03).cgColor)
        context.fill(billToRect)
        
        // Luxury border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(2)
        context.stroke(billToRect)
        
        // Bill to title with luxury styling
        let billToFont = UIFont.systemFont(ofSize: 16, weight: .bold)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "BILL TO:", attributes: billToAttributes)
        let billToTextRect = CGRect(x: 50, y: 190, width: 100, height: 25)
        billToText.draw(in: billToTextRect)
        
        // Customer details with luxury styling
        let customerFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        let customerAttributes: [NSAttributedString.Key: Any] = [
            .font: customerFont,
            .foregroundColor: UIColor.label
        ]
        
        var yOffset: CGFloat = 220
        let customerNameText = NSAttributedString(string: customer.name, attributes: customerAttributes)
        let customerNameRect = CGRect(x: 50, y: yOffset, width: 330, height: 20)
        customerNameText.draw(in: customerNameRect)
        yOffset += 20
        
        if !customer.address.oneLine.isEmpty {
            let addressText = NSAttributedString(string: customer.address.oneLine, attributes: customerAttributes)
            let addressRect = CGRect(x: 50, y: yOffset, width: 330, height: 20)
            addressText.draw(in: addressRect)
            yOffset += 20
        }
        
        if !customer.email.isEmpty {
            let emailText = NSAttributedString(string: customer.email, attributes: customerAttributes)
            let emailRect = CGRect(x: 50, y: yOffset, width: 330, height: 20)
            emailText.draw(in: emailRect)
        }
    }
    
    private func drawExecutiveTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, secondary: UIColor, accent: UIColor) {
        let startY: CGFloat = 320
        
        // Executive table header
        let headerRect = CGRect(x: 40, y: startY, width: page.width - 80, height: 40)
        
        // Luxury gradient header
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: [primary.cgColor, accent.cgColor] as CFArray,
                                 locations: [0.0, 1.0])!
        context.drawLinearGradient(gradient, start: CGPoint(x: 40, y: startY), end: CGPoint(x: page.width - 40, y: startY), options: [])
        
        // Header text
        let headerFont = UIFont.systemFont(ofSize: 13, weight: .bold)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white
        ]
        
        let headers = ["Description", "Quantity", "Unit Price", "Total"]
        let columnWidths: [CGFloat] = [320, 80, 100, 100]
        var xOffset: CGFloat = 50
        
        for (index, header) in headers.enumerated() {
            let headerText = NSAttributedString(string: header, attributes: headerAttributes)
            let headerTextRect = CGRect(x: xOffset, y: startY + 12, width: columnWidths[index], height: 20)
            headerText.draw(in: headerTextRect)
            xOffset += columnWidths[index]
        }
        
        // Executive table rows
        let rowFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.label
        ]
        
        var yOffset = startY + 40
        for (index, item) in invoice.items.enumerated() {
            // Luxury alternating rows
            if index % 2 == 0 {
                let rowRect = CGRect(x: 40, y: yOffset, width: page.width - 80, height: 35)
                context.setFillColor(accent.withAlphaComponent(0.03).cgColor)
                context.fill(rowRect)
            }
            
            // Row content
            xOffset = 50
            
            let itemText = NSAttributedString(string: item.description, attributes: rowAttributes)
            let itemRect = CGRect(x: xOffset, y: yOffset + 10, width: columnWidths[0], height: 20)
            itemText.draw(in: itemRect)
            xOffset += columnWidths[0]
            
            let qtyText = NSAttributedString(string: "\(item.quantity)", attributes: rowAttributes)
            let qtyRect = CGRect(x: xOffset, y: yOffset + 10, width: columnWidths[1], height: 20)
            qtyText.draw(in: qtyRect)
            xOffset += columnWidths[1]
            
            let rateText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.rate as NSDecimalNumber)))", attributes: rowAttributes)
            let rateRect = CGRect(x: xOffset, y: yOffset + 10, width: columnWidths[2], height: 20)
            rateText.draw(in: rateRect)
            xOffset += columnWidths[2]
            
            let amountText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.total as NSDecimalNumber)))", attributes: rowAttributes)
            let amountRect = CGRect(x: xOffset, y: yOffset + 10, width: columnWidths[3], height: 20)
            amountText.draw(in: amountRect)
            
            yOffset += 35
        }
    }
    
    private func drawLuxuryTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, accent: UIColor) {
        let totalY: CGFloat = 480
        
        // Luxury total box
        let totalRect = CGRect(x: page.width - 250, y: totalY, width: 180, height: 60)
        
        // Luxury gradient background
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: [accent.cgColor, primary.cgColor] as CFArray,
                                 locations: [0.0, 1.0])!
        context.drawLinearGradient(gradient, start: CGPoint(x: page.width - 250, y: totalY), end: CGPoint(x: page.width - 70, y: totalY), options: [])
        
        // Luxury border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(3)
        context.stroke(totalRect)
        
        // Total text with luxury styling
        let totalFont = UIFont.systemFont(ofSize: 18, weight: .bold)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 240, y: totalY + 20, width: 160, height: 20)
        totalText.draw(in: totalTextRect)
    }
}

// MARK: - Tech Modern Template

struct TechModernTemplate: TemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent
        
        // Tech header with modern styling
        drawTechHeader(context: context, page: page, company: company, logo: logo, primary: primary, secondary: secondary, accent: accent)
        
        // Tech invoice section
        drawTechInvoiceSection(context: context, page: page, invoice: invoice, primary: primary, accent: accent)
        
        // Tech bill to section
        drawTechBillTo(context: context, page: page, customer: customer, primary: primary, accent: accent)
        
        // Tech table
        drawTechTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary, accent: accent)
        
        // Tech total
        drawTechTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
    }
    
    private func drawTechHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Tech background with geometric pattern
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 120)
        
        // Tech gradient background
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: [primary.cgColor, secondary.cgColor] as CFArray,
                                 locations: [0.0, 1.0])!
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: page.width, y: 0), options: [])
        
        // Tech geometric elements
        context.setFillColor(accent.withAlphaComponent(0.2).cgColor)
        for i in 0..<5 {
            let rect = CGRect(x: CGFloat(i * 120), y: 0, width: 60, height: 120)
            context.fill(rect)
        }
        
        // Logo with tech frame
        if let logo = logo {
            let logoRect = CGRect(x: 30, y: 30, width: 60, height: 60)
            // Tech frame
            context.setStrokeColor(UIColor.white.cgColor)
            context.setLineWidth(2)
            context.stroke(logoRect)
            context.saveGState()
            context.clip(to: logoRect)
            logo.draw(in: logoRect)
            context.restoreGState()
        }
        
        // Company name with tech styling
        let companyFont = UIFont.systemFont(ofSize: 24, weight: .bold)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: UIColor.white
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 110, y: 40, width: page.width - 140, height: 30)
        companyText.draw(in: companyRect)
        
        // Tech tagline
        let taglineFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: UIColor.white.withAlphaComponent(0.8)
        ]
        let taglineText = NSAttributedString(string: "TECHNOLOGY SOLUTIONS", attributes: taglineAttributes)
        let taglineRect = CGRect(x: 110, y: 70, width: page.width - 140, height: 20)
        taglineText.draw(in: taglineRect)
    }
    
    private func drawTechInvoiceSection(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor, accent: UIColor) {
        // Tech invoice box
        let invoiceRect = CGRect(x: page.width - 200, y: 150, width: 150, height: 70)
        
        // Tech background
        context.setFillColor(accent.withAlphaComponent(0.1).cgColor)
        context.fill(invoiceRect)
        
        // Tech border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(2)
        context.stroke(invoiceRect)
        
        // Invoice title with tech styling
        let titleFont = UIFont.systemFont(ofSize: 16, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: accent
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 190, y: 160, width: 130, height: 20)
        titleText.draw(in: titleRect)
        
        // Invoice number with tech styling
        let numberFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: primary
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 190, y: 185, width: 130, height: 20)
        numberText.draw(in: numberRect)
        
        // Date with tech styling
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateText = NSAttributedString(string: dateFormatter.string(from: invoice.issueDate), attributes: numberAttributes)
        let dateRect = CGRect(x: page.width - 190, y: 205, width: 130, height: 20)
        dateText.draw(in: dateRect)
    }
    
    private func drawTechBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor, accent: UIColor) {
        // Tech bill to section
        let billToRect = CGRect(x: 30, y: 150, width: 320, height: 80)
        
        // Tech background
        context.setFillColor(primary.withAlphaComponent(0.05).cgColor)
        context.fill(billToRect)
        
        // Tech border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(1)
        context.stroke(billToRect)
        
        // Bill to title with tech styling
        let billToFont = UIFont.systemFont(ofSize: 13, weight: .bold)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "BILL TO:", attributes: billToAttributes)
        let billToTextRect = CGRect(x: 40, y: 160, width: 100, height: 20)
        billToText.draw(in: billToTextRect)
        
        // Customer details with tech styling
        let customerFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        let customerAttributes: [NSAttributedString.Key: Any] = [
            .font: customerFont,
            .foregroundColor: UIColor.label
        ]
        
        var yOffset: CGFloat = 185
        let customerNameText = NSAttributedString(string: customer.name, attributes: customerAttributes)
        let customerNameRect = CGRect(x: 40, y: yOffset, width: 300, height: 20)
        customerNameText.draw(in: customerNameRect)
        yOffset += 20
        
        if !customer.address.oneLine.isEmpty {
            let addressText = NSAttributedString(string: customer.address.oneLine, attributes: customerAttributes)
            let addressRect = CGRect(x: 40, y: yOffset, width: 300, height: 20)
            addressText.draw(in: addressRect)
            yOffset += 20
        }
        
        if !customer.email.isEmpty {
            let emailText = NSAttributedString(string: customer.email, attributes: customerAttributes)
            let emailRect = CGRect(x: 40, y: yOffset, width: 300, height: 20)
            emailText.draw(in: emailRect)
        }
    }
    
    private func drawTechTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, secondary: UIColor, accent: UIColor) {
        let startY: CGFloat = 260
        
        // Tech table header
        let headerRect = CGRect(x: 30, y: startY, width: page.width - 60, height: 35)
        
        // Tech gradient header
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: [primary.cgColor, accent.cgColor] as CFArray,
                                 locations: [0.0, 1.0])!
        context.drawLinearGradient(gradient, start: CGPoint(x: 30, y: startY), end: CGPoint(x: page.width - 30, y: startY), options: [])
        
        // Header text
        let headerFont = UIFont.systemFont(ofSize: 12, weight: .bold)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white
        ]
        
        let headers = ["Description", "Qty", "Rate", "Amount"]
        let columnWidths: [CGFloat] = [320, 70, 90, 90]
        var xOffset: CGFloat = 40
        
        for (index, header) in headers.enumerated() {
            let headerText = NSAttributedString(string: header, attributes: headerAttributes)
            let headerTextRect = CGRect(x: xOffset, y: startY + 10, width: columnWidths[index], height: 20)
            headerText.draw(in: headerTextRect)
            xOffset += columnWidths[index]
        }
        
        // Tech table rows
        let rowFont = UIFont.systemFont(ofSize: 11, weight: .medium)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.label
        ]
        
        var yOffset = startY + 35
        for (index, item) in invoice.items.enumerated() {
            // Tech alternating rows
            if index % 2 == 0 {
                let rowRect = CGRect(x: 30, y: yOffset, width: page.width - 60, height: 30)
                context.setFillColor(accent.withAlphaComponent(0.05).cgColor)
                context.fill(rowRect)
            }
            
            // Row content
            xOffset = 40
            
            let itemText = NSAttributedString(string: item.description, attributes: rowAttributes)
            let itemRect = CGRect(x: xOffset, y: yOffset + 8, width: columnWidths[0], height: 20)
            itemText.draw(in: itemRect)
            xOffset += columnWidths[0]
            
            let qtyText = NSAttributedString(string: "\(item.quantity)", attributes: rowAttributes)
            let qtyRect = CGRect(x: xOffset, y: yOffset + 8, width: columnWidths[1], height: 20)
            qtyText.draw(in: qtyRect)
            xOffset += columnWidths[1]
            
            let rateText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.rate as NSDecimalNumber)))", attributes: rowAttributes)
            let rateRect = CGRect(x: xOffset, y: yOffset + 8, width: columnWidths[2], height: 20)
            rateText.draw(in: rateRect)
            xOffset += columnWidths[2]
            
            let amountText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.total as NSDecimalNumber)))", attributes: rowAttributes)
            let amountRect = CGRect(x: xOffset, y: yOffset + 8, width: columnWidths[3], height: 20)
            amountText.draw(in: amountRect)
            
            yOffset += 30
        }
    }
    
    private func drawTechTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, accent: UIColor) {
        let totalY: CGFloat = 450
        
        // Tech total box
        let totalRect = CGRect(x: page.width - 200, y: totalY, width: 150, height: 45)
        
        // Tech gradient background
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: [accent.cgColor, primary.cgColor] as CFArray,
                                 locations: [0.0, 1.0])!
        context.drawLinearGradient(gradient, start: CGPoint(x: page.width - 200, y: totalY), end: CGPoint(x: page.width - 50, y: totalY), options: [])
        
        // Tech border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(2)
        context.stroke(totalRect)
        
        // Total text with tech styling
        let totalFont = UIFont.systemFont(ofSize: 16, weight: .bold)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 190, y: totalY + 12, width: 130, height: 20)
        totalText.draw(in: totalTextRect)
    }
}

// MARK: - Geometric Abstract Template

struct GeometricAbstractTemplate: TemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent
        
        // Geometric header with abstract shapes
        drawGeometricHeader(context: context, page: page, company: company, logo: logo, primary: primary, secondary: secondary, accent: accent)
        
        // Abstract invoice section
        drawAbstractInvoiceSection(context: context, page: page, invoice: invoice, primary: primary, accent: accent)
        
        // Geometric bill to section
        drawGeometricBillTo(context: context, page: page, customer: customer, primary: primary, accent: accent)
        
        // Abstract table
        drawAbstractTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary, accent: accent)
        
        // Geometric total
        drawGeometricTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
    }
    
    private func drawGeometricHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Geometric background with abstract shapes
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 130)
        
        // Abstract geometric pattern
        context.setFillColor(primary.withAlphaComponent(0.1).cgColor)
        context.fill(headerRect)
        
        // Geometric shapes
        context.setFillColor(accent.withAlphaComponent(0.3).cgColor)
        for i in 0..<8 {
            let triangle = CGRect(x: CGFloat(i * 75), y: 0, width: 50, height: 50)
            context.fillEllipse(in: triangle)
        }
        
        // Logo with geometric frame
        if let logo = logo {
            let logoRect = CGRect(x: 40, y: 40, width: 70, height: 70)
            // Geometric frame
            context.setStrokeColor(accent.cgColor)
            context.setLineWidth(3)
            context.stroke(logoRect)
            context.saveGState()
            context.clip(to: logoRect)
            logo.draw(in: logoRect)
            context.restoreGState()
        }
        
        // Company name with geometric styling
        let companyFont = UIFont.systemFont(ofSize: 26, weight: .black)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: primary
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 130, y: 50, width: page.width - 180, height: 35)
        companyText.draw(in: companyRect)
        
        // Abstract tagline
        let taglineFont = UIFont.systemFont(ofSize: 13, weight: .medium)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: accent
        ]
        let taglineText = NSAttributedString(string: "ABSTRACT DESIGN", attributes: taglineAttributes)
        let taglineRect = CGRect(x: 130, y: 85, width: page.width - 180, height: 20)
        taglineText.draw(in: taglineRect)
    }
    
    private func drawAbstractInvoiceSection(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor, accent: UIColor) {
        // Abstract invoice box
        let invoiceRect = CGRect(x: page.width - 200, y: 50, width: 150, height: 70)
        
        // Abstract background
        context.setFillColor(accent.withAlphaComponent(0.15).cgColor)
        context.fill(invoiceRect)
        
        // Abstract border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(2)
        context.stroke(invoiceRect)
        
        // Invoice title with abstract styling
        let titleFont = UIFont.systemFont(ofSize: 18, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: accent
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 190, y: 60, width: 130, height: 25)
        titleText.draw(in: titleRect)
        
        // Invoice number with abstract styling
        let numberFont = UIFont.systemFont(ofSize: 15, weight: .semibold)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: primary
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 190, y: 90, width: 130, height: 20)
        numberText.draw(in: numberRect)
    }
    
    private func drawGeometricBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor, accent: UIColor) {
        // Geometric bill to section
        let billToRect = CGRect(x: 40, y: 160, width: 300, height: 90)
        
        // Geometric background
        context.setFillColor(primary.withAlphaComponent(0.08).cgColor)
        context.fill(billToRect)
        
        // Geometric border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(2)
        context.stroke(billToRect)
        
        // Bill to title with geometric styling
        let billToFont = UIFont.systemFont(ofSize: 15, weight: .bold)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "BILL TO:", attributes: billToAttributes)
        let billToTextRect = CGRect(x: 50, y: 170, width: 100, height: 25)
        billToText.draw(in: billToTextRect)
        
        // Customer details with geometric styling
        let customerFont = UIFont.systemFont(ofSize: 13, weight: .medium)
        let customerAttributes: [NSAttributedString.Key: Any] = [
            .font: customerFont,
            .foregroundColor: UIColor.label
        ]
        
        var yOffset: CGFloat = 200
        let customerNameText = NSAttributedString(string: customer.name, attributes: customerAttributes)
        let customerNameRect = CGRect(x: 50, y: yOffset, width: 280, height: 20)
        customerNameText.draw(in: customerNameRect)
        yOffset += 20
        
        if !customer.address.oneLine.isEmpty {
            let addressText = NSAttributedString(string: customer.address.oneLine, attributes: customerAttributes)
            let addressRect = CGRect(x: 50, y: yOffset, width: 280, height: 20)
            addressText.draw(in: addressRect)
            yOffset += 20
        }
        
        if !customer.email.isEmpty {
            let emailText = NSAttributedString(string: customer.email, attributes: customerAttributes)
            let emailRect = CGRect(x: 50, y: yOffset, width: 280, height: 20)
            emailText.draw(in: emailRect)
        }
    }
    
    private func drawAbstractTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, secondary: UIColor, accent: UIColor) {
        let startY: CGFloat = 280
        
        // Abstract table header
        let headerRect = CGRect(x: 40, y: startY, width: page.width - 80, height: 40)
        
        // Abstract gradient header
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: [primary.cgColor, accent.cgColor, secondary.cgColor] as CFArray,
                                 locations: [0.0, 0.5, 1.0])!
        context.drawLinearGradient(gradient, start: CGPoint(x: 40, y: startY), end: CGPoint(x: page.width - 40, y: startY), options: [])
        
        // Header text
        let headerFont = UIFont.systemFont(ofSize: 13, weight: .bold)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white
        ]
        
        let headers = ["Description", "Qty", "Rate", "Amount"]
        let columnWidths: [CGFloat] = [320, 70, 90, 90]
        var xOffset: CGFloat = 50
        
        for (index, header) in headers.enumerated() {
            let headerText = NSAttributedString(string: header, attributes: headerAttributes)
            let headerTextRect = CGRect(x: xOffset, y: startY + 12, width: columnWidths[index], height: 20)
            headerText.draw(in: headerTextRect)
            xOffset += columnWidths[index]
        }
        
        // Abstract table rows
        let rowFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.label
        ]
        
        var yOffset = startY + 40
        for (index, item) in invoice.items.enumerated() {
            // Abstract alternating rows
            if index % 2 == 0 {
                let rowRect = CGRect(x: 40, y: yOffset, width: page.width - 80, height: 35)
                context.setFillColor(accent.withAlphaComponent(0.08).cgColor)
                context.fill(rowRect)
            }
            
            // Row content
            xOffset = 50
            
            let itemText = NSAttributedString(string: item.description, attributes: rowAttributes)
            let itemRect = CGRect(x: xOffset, y: yOffset + 10, width: columnWidths[0], height: 20)
            itemText.draw(in: itemRect)
            xOffset += columnWidths[0]
            
            let qtyText = NSAttributedString(string: "\(item.quantity)", attributes: rowAttributes)
            let qtyRect = CGRect(x: xOffset, y: yOffset + 10, width: columnWidths[1], height: 20)
            qtyText.draw(in: qtyRect)
            xOffset += columnWidths[1]
            
            let rateText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.rate as NSDecimalNumber)))", attributes: rowAttributes)
            let rateRect = CGRect(x: xOffset, y: yOffset + 10, width: columnWidths[2], height: 20)
            rateText.draw(in: rateRect)
            xOffset += columnWidths[2]
            
            let amountText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.total as NSDecimalNumber)))", attributes: rowAttributes)
            let amountRect = CGRect(x: xOffset, y: yOffset + 10, width: columnWidths[3], height: 20)
            amountText.draw(in: amountRect)
            
            yOffset += 35
        }
    }
    
    private func drawGeometricTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, accent: UIColor) {
        let totalY: CGFloat = 460
        
        // Geometric total box
        let totalRect = CGRect(x: page.width - 220, y: totalY, width: 170, height: 55)
        
        // Geometric gradient background
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: [accent.cgColor, primary.cgColor] as CFArray,
                                 locations: [0.0, 1.0])!
        context.drawLinearGradient(gradient, start: CGPoint(x: page.width - 220, y: totalY), end: CGPoint(x: page.width - 50, y: totalY), options: [])
        
        // Geometric border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(3)
        context.stroke(totalRect)
        
        // Total text with geometric styling
        let totalFont = UIFont.systemFont(ofSize: 17, weight: .bold)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 210, y: totalY + 17, width: 150, height: 20)
        totalText.draw(in: totalTextRect)
    }
}

// MARK: - Vintage Retro Template

struct VintageRetroTemplate: TemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent
        
        // Vintage header with retro styling
        drawVintageHeader(context: context, page: page, company: company, logo: logo, primary: primary, secondary: secondary, accent: accent)
        
        // Retro invoice section
        drawRetroInvoiceSection(context: context, page: page, invoice: invoice, primary: primary, accent: accent)
        
        // Vintage bill to section
        drawVintageBillTo(context: context, page: page, customer: customer, primary: primary, accent: accent)
        
        // Retro table
        drawRetroTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary, accent: accent)
        
        // Vintage total
        drawVintageTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
    }
    
    private func drawVintageHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Vintage background with retro pattern
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 140)
        
        // Vintage gradient background
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: [secondary.cgColor, primary.cgColor] as CFArray,
                                 locations: [0.0, 1.0])!
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: page.width, y: 0), options: [])
        
        // Vintage decorative elements
        context.setFillColor(accent.withAlphaComponent(0.2).cgColor)
        for i in 0..<6 {
            let circle = CGRect(x: CGFloat(i * 100), y: 20, width: 30, height: 30)
            context.fillEllipse(in: circle)
        }
        
        // Logo with vintage frame
        if let logo = logo {
            let logoRect = CGRect(x: 50, y: 50, width: 80, height: 80)
            // Vintage frame
            context.setStrokeColor(accent.cgColor)
            context.setLineWidth(4)
            context.stroke(logoRect)
            context.saveGState()
            context.clip(to: logoRect)
            logo.draw(in: logoRect)
            context.restoreGState()
        }
        
        // Company name with vintage styling
        let companyFont = UIFont.systemFont(ofSize: 30, weight: .bold)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: UIColor.white
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 150, y: 60, width: page.width - 200, height: 40)
        companyText.draw(in: companyRect)
        
        // Vintage tagline
        let taglineFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: UIColor.white.withAlphaComponent(0.9)
        ]
        let taglineText = NSAttributedString(string: "VINTAGE & RETRO", attributes: taglineAttributes)
        let taglineRect = CGRect(x: 150, y: 100, width: page.width - 200, height: 25)
        taglineText.draw(in: taglineRect)
    }
    
    private func drawRetroInvoiceSection(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor, accent: UIColor) {
        // Retro invoice box
        let invoiceRect = CGRect(x: page.width - 220, y: 60, width: 160, height: 70)
        
        // Retro background
        context.setFillColor(accent.withAlphaComponent(0.2).cgColor)
        context.fill(invoiceRect)
        
        // Retro border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(3)
        context.stroke(invoiceRect)
        
        // Invoice title with retro styling
        let titleFont = UIFont.systemFont(ofSize: 20, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: accent
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 210, y: 70, width: 140, height: 25)
        titleText.draw(in: titleRect)
        
        // Invoice number with retro styling
        let numberFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: primary
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 210, y: 100, width: 140, height: 20)
        numberText.draw(in: numberRect)
    }
    
    private func drawVintageBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor, accent: UIColor) {
        // Vintage bill to section
        let billToRect = CGRect(x: 50, y: 180, width: 350, height: 100)
        
        // Vintage background
        context.setFillColor(primary.withAlphaComponent(0.1).cgColor)
        context.fill(billToRect)
        
        // Vintage border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(2)
        context.stroke(billToRect)
        
        // Bill to title with vintage styling
        let billToFont = UIFont.systemFont(ofSize: 16, weight: .bold)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "BILL TO:", attributes: billToAttributes)
        let billToTextRect = CGRect(x: 60, y: 190, width: 100, height: 25)
        billToText.draw(in: billToTextRect)
        
        // Customer details with vintage styling
        let customerFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        let customerAttributes: [NSAttributedString.Key: Any] = [
            .font: customerFont,
            .foregroundColor: UIColor.label
        ]
        
        var yOffset: CGFloat = 220
        let customerNameText = NSAttributedString(string: customer.name, attributes: customerAttributes)
        let customerNameRect = CGRect(x: 60, y: yOffset, width: 330, height: 20)
        customerNameText.draw(in: customerNameRect)
        yOffset += 20
        
        if !customer.address.oneLine.isEmpty {
            let addressText = NSAttributedString(string: customer.address.oneLine, attributes: customerAttributes)
            let addressRect = CGRect(x: 60, y: yOffset, width: 330, height: 20)
            addressText.draw(in: addressRect)
            yOffset += 20
        }
        
        if !customer.email.isEmpty {
            let emailText = NSAttributedString(string: customer.email, attributes: customerAttributes)
            let emailRect = CGRect(x: 60, y: yOffset, width: 330, height: 20)
            emailText.draw(in: emailRect)
        }
    }
    
    private func drawRetroTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, secondary: UIColor, accent: UIColor) {
        let startY: CGFloat = 320
        
        // Retro table header
        let headerRect = CGRect(x: 50, y: startY, width: page.width - 100, height: 40)
        
        // Retro gradient header
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: [primary.cgColor, secondary.cgColor] as CFArray,
                                 locations: [0.0, 1.0])!
        context.drawLinearGradient(gradient, start: CGPoint(x: 50, y: startY), end: CGPoint(x: page.width - 50, y: startY), options: [])
        
        // Header text
        let headerFont = UIFont.systemFont(ofSize: 13, weight: .bold)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white
        ]
        
        let headers = ["Description", "Qty", "Rate", "Amount"]
        let columnWidths: [CGFloat] = [320, 80, 100, 100]
        var xOffset: CGFloat = 60
        
        for (index, header) in headers.enumerated() {
            let headerText = NSAttributedString(string: header, attributes: headerAttributes)
            let headerTextRect = CGRect(x: xOffset, y: startY + 12, width: columnWidths[index], height: 20)
            headerText.draw(in: headerTextRect)
            xOffset += columnWidths[index]
        }
        
        // Retro table rows
        let rowFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.label
        ]
        
        var yOffset = startY + 40
        for (index, item) in invoice.items.enumerated() {
            // Retro alternating rows
            if index % 2 == 0 {
                let rowRect = CGRect(x: 50, y: yOffset, width: page.width - 100, height: 35)
                context.setFillColor(accent.withAlphaComponent(0.1).cgColor)
                context.fill(rowRect)
            }
            
            // Row content
            xOffset = 60
            
            let itemText = NSAttributedString(string: item.description, attributes: rowAttributes)
            let itemRect = CGRect(x: xOffset, y: yOffset + 10, width: columnWidths[0], height: 20)
            itemText.draw(in: itemRect)
            xOffset += columnWidths[0]
            
            let qtyText = NSAttributedString(string: "\(item.quantity)", attributes: rowAttributes)
            let qtyRect = CGRect(x: xOffset, y: yOffset + 10, width: columnWidths[1], height: 20)
            qtyText.draw(in: qtyRect)
            xOffset += columnWidths[1]
            
            let rateText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.rate as NSDecimalNumber)))", attributes: rowAttributes)
            let rateRect = CGRect(x: xOffset, y: yOffset + 10, width: columnWidths[2], height: 20)
            rateText.draw(in: rateRect)
            xOffset += columnWidths[2]
            
            let amountText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.total as NSDecimalNumber)))", attributes: rowAttributes)
            let amountRect = CGRect(x: xOffset, y: yOffset + 10, width: columnWidths[3], height: 20)
            amountText.draw(in: amountRect)
            
            yOffset += 35
        }
    }
    
    private func drawVintageTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, accent: UIColor) {
        let totalY: CGFloat = 480
        
        // Vintage total box
        let totalRect = CGRect(x: page.width - 240, y: totalY, width: 180, height: 60)
        
        // Vintage gradient background
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: [accent.cgColor, primary.cgColor] as CFArray,
                                 locations: [0.0, 1.0])!
        context.drawLinearGradient(gradient, start: CGPoint(x: page.width - 240, y: totalY), end: CGPoint(x: page.width - 60, y: totalY), options: [])
        
        // Vintage border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(4)
        context.stroke(totalRect)
        
        // Total text with vintage styling
        let totalFont = UIFont.systemFont(ofSize: 18, weight: .bold)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 230, y: totalY + 20, width: 160, height: 20)
        totalText.draw(in: totalTextRect)
    }
}

// MARK: - Template Factory

class TemplateFactory {
    static func createTemplate(for design: TemplateDesign, theme: TemplateTheme) -> TemplateRenderer {
        switch design {
        case .modernClean:
            return ModernCleanTemplate(theme: theme)
        case .professionalMinimal:
            return MinimalProfessionalTemplate(theme: theme)
        case .corporateFormal:
            return CorporateFormalTemplate(theme: theme)
        case .creativeVibrant:
            return CreativeVibrantTemplate(theme: theme)
        case .executiveLuxury:
            return ExecutiveLuxuryTemplate(theme: theme)
        case .techModern:
            return TechModernTemplate(theme: theme)
        case .geometricAbstract:
            return GeometricAbstractTemplate(theme: theme)
        case .vintageRetro:
            return VintageRetroTemplate(theme: theme)
        default:
            // For now, return ModernCleanTemplate for all other designs
            // We'll add more templates gradually
            return ModernCleanTemplate(theme: theme)
        }
    }
}
