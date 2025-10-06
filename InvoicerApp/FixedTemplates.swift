//
//  FixedTemplates.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/29/25.
//

import SwiftUI
import UIKit

// MARK: - Simple and Reliable Template Renderer

protocol SimpleTemplateRenderer {
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?)
}

// MARK: - Clean Modern Template

struct CleanModernTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        
        // Set white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)
        
        // Header
        drawHeader(context: context, page: page, company: company, logo: logo, primary: primary)
        
        // Invoice info
        drawInvoiceInfo(context: context, page: page, invoice: invoice, primary: primary)
        
        // Bill to
        drawBillTo(context: context, page: page, customer: customer, primary: primary)
        
        // Items table
        drawItemsTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary)
        
        // Total
        drawTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary)
        
        // Footer
        drawFooter(context: context, page: page, company: company, primary: primary)
    }
    
    private func drawHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor) {
        // Logo
        if let logo = logo {
            let logoRect = CGRect(x: 50, y: 50, width: 80, height: 80)
            logo.draw(in: logoRect)
        }
        
        // Company name
        let companyFont = UIFont.systemFont(ofSize: 24, weight: .bold)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: primary
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 150, y: 60, width: page.width - 200, height: 30)
        companyText.draw(in: companyRect)
        
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
    
    private func drawInvoiceInfo(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor) {
        // Invoice title
        let titleFont = UIFont.systemFont(ofSize: 32, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: primary
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 200, y: 50, width: 150, height: 40)
        titleText.draw(in: titleRect)
        
        // Invoice number
        let numberFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: UIColor.black
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 200, y: 90, width: 150, height: 20)
        numberText.draw(in: numberRect)
    }
    
    private func drawBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor) {
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
    
    private func drawItemsTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor) {
        let startY: CGFloat = 320
        
        // Table header background
        let headerRect = CGRect(x: 50, y: startY, width: page.width - 100, height: 30)
        context.setFillColor(primary.cgColor)
        context.fill(headerRect)
        
        // Header text
        let headerFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white
        ]
        
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
        for (index, item) in invoice.items.enumerated() {
            // Alternating row background
            if index % 2 == 0 {
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
    
    private func drawTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor) {
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

// MARK: - Simple Minimal Template

struct SimpleMinimalTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        
        // Set white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)
        
        // Header
        drawHeader(context: context, page: page, company: company, logo: logo, primary: primary)
        
        // Invoice info
        drawInvoiceInfo(context: context, page: page, invoice: invoice, primary: primary)
        
        // Bill to
        drawBillTo(context: context, page: page, customer: customer, primary: primary)
        
        // Items table
        drawItemsTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary)
        
        // Total
        drawTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary)
    }
    
    private func drawHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor) {
        // Company name - large and clean
        let companyFont = UIFont.systemFont(ofSize: 28, weight: .light)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: UIColor.black
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 60, y: 60, width: page.width - 120, height: 35)
        companyText.draw(in: companyRect)
        
        // Invoice number - small and subtle
        let invoiceFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        let invoiceAttributes: [NSAttributedString.Key: Any] = [
            .font: invoiceFont,
            .foregroundColor: UIColor.gray
        ]
        let invoiceText = NSAttributedString(string: "Invoice #123", attributes: invoiceAttributes)
        let invoiceRect = CGRect(x: 60, y: 100, width: page.width - 120, height: 20)
        invoiceText.draw(in: invoiceRect)
        
        // Thin line separator
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: 60, y: 130))
        context.addLine(to: CGPoint(x: page.width - 60, y: 130))
        context.strokePath()
    }
    
    private func drawInvoiceInfo(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor) {
        // This template doesn't have separate invoice info section
    }
    
    private func drawBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor) {
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
            .foregroundColor: UIColor.black
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
    
    private func drawItemsTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor) {
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
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: 60, y: startY + 25))
        context.addLine(to: CGPoint(x: page.width - 60, y: startY + 25))
        context.strokePath()
        
        // Table rows
        let rowFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.black
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
    
    private func drawTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor) {
        let totalY: CGFloat = 450
        
        // Simple total text
        let totalFont = UIFont.systemFont(ofSize: 18, weight: .medium)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.black
        ]
        let totalText = NSAttributedString(string: "Total: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalRect = CGRect(x: page.width - 200, y: totalY, width: 140, height: 25)
        totalText.draw(in: totalRect)
    }
}

// MARK: - Fixed Corporate Formal Template

struct FixedCorporateFormalTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        
        // Set white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)
        
        // Corporate header with formal styling
        drawCorporateHeader(context: context, page: page, company: company, logo: logo, primary: primary)
        
        // Formal invoice section
        drawFormalInvoiceSection(context: context, page: page, invoice: invoice, primary: primary)
        
        // Corporate bill to section
        drawCorporateBillTo(context: context, page: page, customer: customer, primary: primary)
        
        // Formal table
        drawFormalTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary)
        
        // Corporate total
        drawCorporateTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary)
        
        // Formal footer
        drawFormalFooter(context: context, page: page, company: company, primary: primary)
    }
    
    private func drawCorporateHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor) {
        // Corporate header with thick border
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 120)
        context.setFillColor(primary.withAlphaComponent(0.1).cgColor)
        context.fill(headerRect)
        
        // Thick corporate border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(4)
        context.stroke(headerRect)
        
        // Logo with corporate frame
        if let logo = logo {
            let logoRect = CGRect(x: 40, y: 30, width: 60, height: 60)
            // Corporate frame
            context.setStrokeColor(primary.cgColor)
            context.setLineWidth(2)
            context.stroke(logoRect)
            logo.draw(in: logoRect)
        }
        
        // Company name with corporate styling
        let companyFont = UIFont.systemFont(ofSize: 22, weight: .bold)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: primary
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 120, y: 40, width: page.width - 160, height: 30)
        companyText.draw(in: companyRect)
        
        // Corporate tagline
        let taglineFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: UIColor.gray
        ]
        let taglineText = NSAttributedString(string: "CORPORATE SERVICES", attributes: taglineAttributes)
        let taglineRect = CGRect(x: 120, y: 70, width: page.width - 160, height: 20)
        taglineText.draw(in: taglineRect)
    }
    
    private func drawFormalInvoiceSection(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor) {
        // Formal invoice box
        let invoiceRect = CGRect(x: page.width - 180, y: 30, width: 140, height: 80)
        
        // Formal background
        context.setFillColor(primary.withAlphaComponent(0.1).cgColor)
        context.fill(invoiceRect)
        
        // Formal border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(2)
        context.stroke(invoiceRect)
        
        // Invoice title with formal styling
        let titleFont = UIFont.systemFont(ofSize: 18, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: primary
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 170, y: 40, width: 120, height: 25)
        titleText.draw(in: titleRect)
        
        // Invoice number with formal styling
        let numberFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: UIColor.black
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 170, y: 70, width: 120, height: 20)
        numberText.draw(in: numberRect)
        
        // Date with formal styling
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateText = NSAttributedString(string: dateFormatter.string(from: invoice.issueDate), attributes: numberAttributes)
        let dateRect = CGRect(x: page.width - 170, y: 95, width: 120, height: 20)
        dateText.draw(in: dateRect)
    }
    
    private func drawCorporateBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor) {
        // Corporate bill to section
        let billToRect = CGRect(x: 40, y: 150, width: 300, height: 100)
        
        // Corporate background
        context.setFillColor(primary.withAlphaComponent(0.05).cgColor)
        context.fill(billToRect)
        
        // Corporate border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(1)
        context.stroke(billToRect)
        
        // Bill to title with corporate styling
        let billToFont = UIFont.systemFont(ofSize: 14, weight: .bold)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "BILL TO:", attributes: billToAttributes)
        let billToTextRect = CGRect(x: 50, y: 160, width: 100, height: 25)
        billToText.draw(in: billToTextRect)
        
        // Customer details with corporate styling
        let customerFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let customerAttributes: [NSAttributedString.Key: Any] = [
            .font: customerFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset: CGFloat = 190
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
    
    private func drawFormalTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor) {
        let startY: CGFloat = 280
        
        // Formal table header
        let headerRect = CGRect(x: 40, y: startY, width: page.width - 80, height: 35)
        
        // Formal header background
        context.setFillColor(primary.cgColor)
        context.fill(headerRect)
        
        // Header text
        let headerFont = UIFont.systemFont(ofSize: 12, weight: .bold)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white
        ]
        
        let headers = ["Description", "Quantity", "Unit Price", "Total"]
        let columnWidths: [CGFloat] = [280, 80, 100, 100]
        var xOffset: CGFloat = 50
        
        for (index, header) in headers.enumerated() {
            let headerText = NSAttributedString(string: header, attributes: headerAttributes)
            let headerTextRect = CGRect(x: xOffset, y: startY + 10, width: columnWidths[index], height: 20)
            headerText.draw(in: headerTextRect)
            xOffset += columnWidths[index]
        }
        
        // Formal table rows
        let rowFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset = startY + 35
        for (index, item) in invoice.items.enumerated() {
            // Formal alternating rows
            if index % 2 == 0 {
                let rowRect = CGRect(x: 40, y: yOffset, width: page.width - 80, height: 30)
                context.setFillColor(primary.withAlphaComponent(0.05).cgColor)
                context.fill(rowRect)
            }
            
            // Row content
            xOffset = 50
            
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
    
    private func drawCorporateTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor) {
        let totalY: CGFloat = 450
        
        // Corporate total box
        let totalRect = CGRect(x: page.width - 220, y: totalY, width: 160, height: 50)
        
        // Corporate background
        context.setFillColor(primary.cgColor)
        context.fill(totalRect)
        
        // Corporate border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(2)
        context.stroke(totalRect)
        
        // Total text with corporate styling
        let totalFont = UIFont.systemFont(ofSize: 16, weight: .bold)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 210, y: totalY + 15, width: 140, height: 20)
        totalText.draw(in: totalTextRect)
    }
    
    private func drawFormalFooter(context: CGContext, page: CGRect, company: Company, primary: UIColor) {
        let footerFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = NSAttributedString(string: "Thank you for your business. Payment terms: Net 30 days.", attributes: footerAttributes)
        let footerRect = CGRect(x: 40, y: page.height - 50, width: page.width - 80, height: 20)
        footerText.draw(in: footerRect)
    }
}

// MARK: - Fixed Creative Vibrant Template

struct FixedCreativeVibrantTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent
        
        // Set white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)
        
        // Creative header with vibrant styling
        drawCreativeHeader(context: context, page: page, company: company, logo: logo, primary: primary, secondary: secondary, accent: accent)
        
        // Vibrant invoice section
        drawVibrantInvoiceSection(context: context, page: page, invoice: invoice, primary: primary, accent: accent)
        
        // Creative bill to section
        drawCreativeBillTo(context: context, page: page, customer: customer, primary: primary, accent: accent)
        
        // Vibrant table
        drawVibrantTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary, accent: accent)
        
        // Creative total
        drawCreativeTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
        
        // Vibrant footer
        drawVibrantFooter(context: context, page: page, company: company, primary: primary)
    }
    
    private func drawCreativeHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Creative header with vibrant background
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 100)
        
        // Vibrant gradient-like effect using multiple colors
        context.setFillColor(primary.withAlphaComponent(0.2).cgColor)
        context.fill(headerRect)
        
        // Creative geometric shapes
        context.setFillColor(accent.withAlphaComponent(0.3).cgColor)
        for i in 0..<6 {
            let circle = CGRect(x: CGFloat(i * 100), y: 20, width: 20, height: 20)
            context.fillEllipse(in: circle)
        }
        
        // Logo with creative frame
        if let logo = logo {
            let logoRect = CGRect(x: 30, y: 30, width: 50, height: 50)
            // Creative circular frame
            context.setStrokeColor(accent.cgColor)
            context.setLineWidth(3)
            context.strokeEllipse(in: logoRect)
            logo.draw(in: logoRect)
        }
        
        // Company name with creative styling
        let companyFont = UIFont.systemFont(ofSize: 26, weight: .black)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: primary
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 100, y: 35, width: page.width - 130, height: 35)
        companyText.draw(in: companyRect)
        
        // Creative tagline
        let taglineFont = UIFont.systemFont(ofSize: 13, weight: .medium)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: accent
        ]
        let taglineText = NSAttributedString(string: "CREATIVE SOLUTIONS", attributes: taglineAttributes)
        let taglineRect = CGRect(x: 100, y: 70, width: page.width - 130, height: 20)
        taglineText.draw(in: taglineRect)
    }
    
    private func drawVibrantInvoiceSection(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor, accent: UIColor) {
        // Vibrant invoice box
        let invoiceRect = CGRect(x: page.width - 160, y: 20, width: 120, height: 60)
        
        // Vibrant background
        context.setFillColor(accent.withAlphaComponent(0.2).cgColor)
        context.fill(invoiceRect)
        
        // Vibrant border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(3)
        context.stroke(invoiceRect)
        
        // Invoice title with vibrant styling
        let titleFont = UIFont.systemFont(ofSize: 16, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: accent
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 150, y: 30, width: 100, height: 20)
        titleText.draw(in: titleRect)
        
        // Invoice number with vibrant styling
        let numberFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: primary
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 150, y: 55, width: 100, height: 20)
        numberText.draw(in: numberRect)
    }
    
    private func drawCreativeBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor, accent: UIColor) {
        // Creative bill to section
        let billToRect = CGRect(x: 30, y: 130, width: 250, height: 80)
        
        // Creative background
        context.setFillColor(primary.withAlphaComponent(0.1).cgColor)
        context.fill(billToRect)
        
        // Creative border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(2)
        context.stroke(billToRect)
        
        // Bill to title with creative styling
        let billToFont = UIFont.systemFont(ofSize: 13, weight: .bold)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "Bill To:", attributes: billToAttributes)
        let billToTextRect = CGRect(x: 40, y: 140, width: 100, height: 20)
        billToText.draw(in: billToTextRect)
        
        // Customer details with creative styling
        let customerFont = UIFont.systemFont(ofSize: 11, weight: .medium)
        let customerAttributes: [NSAttributedString.Key: Any] = [
            .font: customerFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset: CGFloat = 165
        let customerNameText = NSAttributedString(string: customer.name, attributes: customerAttributes)
        let customerNameRect = CGRect(x: 40, y: yOffset, width: 230, height: 20)
        customerNameText.draw(in: customerNameRect)
        yOffset += 18
        
        if !customer.address.oneLine.isEmpty {
            let addressText = NSAttributedString(string: customer.address.oneLine, attributes: customerAttributes)
            let addressRect = CGRect(x: 40, y: yOffset, width: 230, height: 20)
            addressText.draw(in: addressRect)
            yOffset += 18
        }
        
        if !customer.email.isEmpty {
            let emailText = NSAttributedString(string: customer.email, attributes: customerAttributes)
            let emailRect = CGRect(x: 40, y: yOffset, width: 230, height: 20)
            emailText.draw(in: emailRect)
        }
    }
    
    private func drawVibrantTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, secondary: UIColor, accent: UIColor) {
        let startY: CGFloat = 240
        
        // Vibrant table header
        let headerRect = CGRect(x: 30, y: startY, width: page.width - 60, height: 30)
        
        // Vibrant header background
        context.setFillColor(accent.cgColor)
        context.fill(headerRect)
        
        // Header text
        let headerFont = UIFont.systemFont(ofSize: 11, weight: .bold)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white
        ]
        
        let headers = ["Item", "Qty", "Rate", "Total"]
        let columnWidths: [CGFloat] = [250, 60, 80, 80]
        var xOffset: CGFloat = 40
        
        for (index, header) in headers.enumerated() {
            let headerText = NSAttributedString(string: header, attributes: headerAttributes)
            let headerTextRect = CGRect(x: xOffset, y: startY + 8, width: columnWidths[index], height: 20)
            headerText.draw(in: headerTextRect)
            xOffset += columnWidths[index]
        }
        
        // Vibrant table rows
        let rowFont = UIFont.systemFont(ofSize: 10, weight: .medium)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset = startY + 30
        for (index, item) in invoice.items.enumerated() {
            // Vibrant alternating rows
            if index % 2 == 0 {
                let rowRect = CGRect(x: 30, y: yOffset, width: page.width - 60, height: 25)
                context.setFillColor(primary.withAlphaComponent(0.1).cgColor)
                context.fill(rowRect)
            }
            
            // Row content
            xOffset = 40
            
            let itemText = NSAttributedString(string: item.description, attributes: rowAttributes)
            let itemRect = CGRect(x: xOffset, y: yOffset + 6, width: columnWidths[0], height: 20)
            itemText.draw(in: itemRect)
            xOffset += columnWidths[0]
            
            let qtyText = NSAttributedString(string: "\(item.quantity)", attributes: rowAttributes)
            let qtyRect = CGRect(x: xOffset, y: yOffset + 6, width: columnWidths[1], height: 20)
            qtyText.draw(in: qtyRect)
            xOffset += columnWidths[1]
            
            let rateText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.rate as NSDecimalNumber)))", attributes: rowAttributes)
            let rateRect = CGRect(x: xOffset, y: yOffset + 6, width: columnWidths[2], height: 20)
            rateText.draw(in: rateRect)
            xOffset += columnWidths[2]
            
            let amountText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.total as NSDecimalNumber)))", attributes: rowAttributes)
            let amountRect = CGRect(x: xOffset, y: yOffset + 6, width: columnWidths[3], height: 20)
            amountText.draw(in: amountRect)
            
            yOffset += 25
        }
    }
    
    private func drawCreativeTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, accent: UIColor) {
        let totalY: CGFloat = 400
        
        // Creative total box
        let totalRect = CGRect(x: page.width - 180, y: totalY, width: 140, height: 40)
        
        // Creative background
        context.setFillColor(accent.cgColor)
        context.fill(totalRect)
        
        // Creative border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(3)
        context.stroke(totalRect)
        
        // Total text with creative styling
        let totalFont = UIFont.systemFont(ofSize: 14, weight: .bold)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 170, y: totalY + 12, width: 120, height: 20)
        totalText.draw(in: totalTextRect)
    }
    
    private func drawVibrantFooter(context: CGContext, page: CGRect, company: Company, primary: UIColor) {
        let footerFont = UIFont.systemFont(ofSize: 9, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = NSAttributedString(string: "✨ Thank you for choosing our creative services! ✨", attributes: footerAttributes)
        let footerRect = CGRect(x: 30, y: page.height - 40, width: page.width - 60, height: 20)
        footerText.draw(in: footerRect)
    }
}

// MARK: - Fixed Executive Luxury Template

struct FixedExecutiveLuxuryTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let accent = theme.accent
        
        // Set white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)
        
        // Luxury header
        drawLuxuryHeader(context: context, page: page, company: company, logo: logo, primary: primary, accent: accent)
        
        // Executive invoice section
        drawExecutiveInvoiceSection(context: context, page: page, invoice: invoice, primary: primary, accent: accent)
        
        // Luxury bill to section
        drawLuxuryBillTo(context: context, page: page, customer: customer, primary: primary, accent: accent)
        
        // Executive table
        drawExecutiveTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
        
        // Luxury total
        drawLuxuryTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
        
        // Executive footer
        drawExecutiveFooter(context: context, page: page, company: company, primary: primary)
    }
    
    private func drawLuxuryHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, accent: UIColor) {
        // Luxury header with gold accents
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
            logo.draw(in: logoRect)
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
            .foregroundColor: UIColor.black
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
    
    private func drawExecutiveTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, accent: UIColor) {
        let startY: CGFloat = 320
        
        // Executive table header
        let headerRect = CGRect(x: 40, y: startY, width: page.width - 80, height: 40)
        
        // Luxury header background
        context.setFillColor(primary.cgColor)
        context.fill(headerRect)
        
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
            .foregroundColor: UIColor.black
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
        
        // Luxury background
        context.setFillColor(accent.cgColor)
        context.fill(totalRect)
        
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
    
    private func drawExecutiveFooter(context: CGContext, page: CGRect, company: Company, primary: UIColor) {
        let footerFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = NSAttributedString(string: "Thank you for your business. Premium service guaranteed.", attributes: footerAttributes)
        let footerRect = CGRect(x: 40, y: page.height - 50, width: page.width - 80, height: 20)
        footerText.draw(in: footerRect)
    }
}

// MARK: - Fixed Tech Modern Template

struct FixedTechModernTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent
        
        // Set white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)
        
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
        
        // Tech footer
        drawTechFooter(context: context, page: page, company: company, primary: primary)
    }
    
    private func drawTechHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Tech background with geometric pattern
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 120)
        
        // Tech background
        context.setFillColor(primary.withAlphaComponent(0.1).cgColor)
        context.fill(headerRect)
        
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
            logo.draw(in: logoRect)
        }
        
        // Company name with tech styling
        let companyFont = UIFont.systemFont(ofSize: 24, weight: .bold)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: primary
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 110, y: 40, width: page.width - 140, height: 30)
        companyText.draw(in: companyRect)
        
        // Tech tagline
        let taglineFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: accent
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
            .foregroundColor: UIColor.black
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
        
        // Tech header background
        context.setFillColor(primary.cgColor)
        context.fill(headerRect)
        
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
            .foregroundColor: UIColor.black
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
        
        // Tech background
        context.setFillColor(accent.cgColor)
        context.fill(totalRect)
        
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
    
    private func drawTechFooter(context: CGContext, page: CGRect, company: Company, primary: UIColor) {
        let footerFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = NSAttributedString(string: "Powered by technology. Innovation delivered.", attributes: footerAttributes)
        let footerRect = CGRect(x: 30, y: page.height - 50, width: page.width - 60, height: 20)
        footerText.draw(in: footerRect)
    }
}

// MARK: - Fixed Template Factory

class FixedTemplateFactory {
    static func createTemplate(for design: TemplateDesign, theme: TemplateTheme) -> SimpleTemplateRenderer {
        switch design {
        case .modernClean:
            return CleanModernTemplate(theme: theme)
        case .professionalMinimal:
            return SimpleMinimalTemplate(theme: theme)
        case .corporateFormal:
            return FixedCorporateFormalTemplate(theme: theme)
        case .creativeVibrant:
            return FixedCreativeVibrantTemplate(theme: theme)
        case .executiveLuxury:
            return FixedExecutiveLuxuryTemplate(theme: theme)
        case .techModern:
            return FixedTechModernTemplate(theme: theme)
        case .geometricAbstract:
            return AllGeometricAbstractTemplate(theme: theme)
        case .vintageRetro:
            return AllVintageRetroTemplate(theme: theme)
        case .businessClassic:
            return AllBusinessClassicTemplate(theme: theme)
        case .enterpriseBold:
            return EnterpriseBoldTemplate(theme: theme)
        case .consultingElegant:
            return ConsultingElegantTemplate(theme: theme)
        case .financialStructured:
            return FinancialStructuredTemplate(theme: theme)
        case .legalTraditional:
            return LegalTraditionalTemplate(theme: theme)
        case .healthcareModern:
            return HealthcareModernTemplate(theme: theme)
        case .realEstateWarm:
            return RealEstateWarmTemplate(theme: theme)
        case .insuranceTrust:
            return InsuranceTrustTemplate(theme: theme)
        case .bankingSecure:
            return BankingSecureTemplate(theme: theme)
        case .accountingDetailed:
            return AccountingDetailedTemplate(theme: theme)
        case .consultingProfessional:
            return ConsultingProfessionalTemplate(theme: theme)
        case .artisticBold:
            return ArtisticBoldTemplate(theme: theme)
        case .designStudio:
            return DesignStudioTemplate(theme: theme)
        case .fashionElegant:
            return FashionElegantTemplate(theme: theme)
        case .photographyClean:
            return PhotographyCleanTemplate(theme: theme)
        default:
            // For all other designs, use CleanModernTemplate
            return CleanModernTemplate(theme: theme)
        }
    }
}
