import Foundation
import UIKit

// MARK: - Financial Structured Template

struct FinancialStructuredTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent
        
        // Set white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)
        
        // Financial header
        drawFinancialHeader(context: context, page: page, company: company, logo: logo, primary: primary, secondary: secondary, accent: accent)
        
        // Structured invoice section
        drawStructuredInvoiceSection(context: context, page: page, invoice: invoice, primary: primary, accent: accent)
        
        // Financial bill to section
        drawFinancialBillTo(context: context, page: page, customer: customer, primary: primary, accent: accent)
        
        // Structured table
        drawStructuredTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary, accent: accent)
        
        // Financial total
        drawFinancialTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
        
        // Structured footer
        drawStructuredFooter(context: context, page: page, company: company, primary: primary)
    }
    
    private func drawFinancialHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Financial background with structured pattern
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 120)
        
        // Financial background
        context.setFillColor(primary.withAlphaComponent(0.08).cgColor)
        context.fill(headerRect)
        
        // Structured grid pattern
        context.setStrokeColor(accent.withAlphaComponent(0.2).cgColor)
        context.setLineWidth(0.5)
        for i in 0..<20 {
            let x = CGFloat(i * 30)
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: 120))
        }
        for i in 0..<8 {
            let y = CGFloat(i * 15)
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: page.width, y: y))
        }
        context.strokePath()
        
        // Logo with financial frame
        if let logo = logo {
            let logoRect = CGRect(x: 30, y: 25, width: 70, height: 70)
            // Financial frame
            context.setStrokeColor(primary.cgColor)
            context.setLineWidth(2)
            context.stroke(logoRect)
            logo.draw(in: logoRect)
        }
        
        // Company name with financial styling
        let companyFont = UIFont.systemFont(ofSize: 26, weight: .semibold)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: primary
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 120, y: 35, width: page.width - 150, height: 35)
        companyText.draw(in: companyRect)
        
        // Financial tagline
        let taglineFont = UIFont.systemFont(ofSize: 13, weight: .medium)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: accent
        ]
        let taglineText = NSAttributedString(string: "FINANCIAL SERVICES", attributes: taglineAttributes)
        let taglineRect = CGRect(x: 120, y: 70, width: page.width - 150, height: 20)
        taglineText.draw(in: taglineRect)
    }
    
    private func drawStructuredInvoiceSection(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor, accent: UIColor) {
        // Structured invoice box
        let invoiceRect = CGRect(x: page.width - 190, y: 30, width: 150, height: 80)
        
        // Structured background
        context.setFillColor(accent.withAlphaComponent(0.1).cgColor)
        context.fill(invoiceRect)
        
        // Structured border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(2)
        context.stroke(invoiceRect)
        
        // Invoice title with structured styling
        let titleFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: accent
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 180, y: 40, width: 130, height: 25)
        titleText.draw(in: titleRect)
        
        // Invoice number with structured styling
        let numberFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: primary
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 180, y: 70, width: 130, height: 20)
        numberText.draw(in: numberRect)
        
        // Date with structured styling
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateText = NSAttributedString(string: dateFormatter.string(from: invoice.issueDate), attributes: numberAttributes)
        let dateRect = CGRect(x: page.width - 180, y: 95, width: 130, height: 20)
        dateText.draw(in: dateRect)
    }
    
    private func drawFinancialBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor, accent: UIColor) {
        // Financial bill to section
        let billToRect = CGRect(x: 30, y: 150, width: 350, height: 100)
        
        // Financial background
        context.setFillColor(primary.withAlphaComponent(0.04).cgColor)
        context.fill(billToRect)
        
        // Financial border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(1)
        context.stroke(billToRect)
        
        // Bill to title with financial styling
        let billToFont = UIFont.systemFont(ofSize: 15, weight: .semibold)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "BILL TO:", attributes: billToAttributes)
        let billToTextRect = CGRect(x: 40, y: 160, width: 100, height: 25)
        billToText.draw(in: billToTextRect)
        
        // Customer details with financial styling
        let customerFont = UIFont.systemFont(ofSize: 13, weight: .regular)
        let customerAttributes: [NSAttributedString.Key: Any] = [
            .font: customerFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset: CGFloat = 190
        let customerNameText = NSAttributedString(string: customer.name, attributes: customerAttributes)
        let customerNameRect = CGRect(x: 40, y: yOffset, width: 330, height: 20)
        customerNameText.draw(in: customerNameRect)
        yOffset += 20
        
        if !customer.address.oneLine.isEmpty {
            let addressText = NSAttributedString(string: customer.address.oneLine, attributes: customerAttributes)
            let addressRect = CGRect(x: 40, y: yOffset, width: 330, height: 20)
            addressText.draw(in: addressRect)
            yOffset += 20
        }
        
        if !customer.email.isEmpty {
            let emailText = NSAttributedString(string: customer.email, attributes: customerAttributes)
            let emailRect = CGRect(x: 40, y: yOffset, width: 330, height: 20)
            emailText.draw(in: emailRect)
        }
    }
    
    private func drawStructuredTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, secondary: UIColor, accent: UIColor) {
        let startY: CGFloat = 280
        
        // Structured table header
        let headerRect = CGRect(x: 30, y: startY, width: page.width - 60, height: 35)
        
        // Structured header background
        context.setFillColor(primary.cgColor)
        context.fill(headerRect)
        
        // Header text
        let headerFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white
        ]
        
        let headers = ["Description", "Quantity", "Unit Price", "Total"]
        let columnWidths: [CGFloat] = [320, 80, 100, 100]
        var xOffset: CGFloat = 40
        
        for (index, header) in headers.enumerated() {
            let headerText = NSAttributedString(string: header, attributes: headerAttributes)
            let headerTextRect = CGRect(x: xOffset, y: startY + 10, width: columnWidths[index], height: 20)
            headerText.draw(in: headerTextRect)
            xOffset += columnWidths[index]
        }
        
        // Structured table rows
        let rowFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset = startY + 35
        for (index, item) in invoice.items.enumerated() {
            // Structured alternating rows
            if index % 2 == 0 {
                let rowRect = CGRect(x: 30, y: yOffset, width: page.width - 60, height: 30)
                context.setFillColor(accent.withAlphaComponent(0.06).cgColor)
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
    
    private func drawFinancialTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, accent: UIColor) {
        let totalY: CGFloat = 450
        
        // Financial total box
        let totalRect = CGRect(x: page.width - 220, y: totalY, width: 170, height: 50)
        
        // Financial background
        context.setFillColor(accent.cgColor)
        context.fill(totalRect)
        
        // Financial border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(2)
        context.stroke(totalRect)
        
        // Total text with financial styling
        let totalFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 210, y: totalY + 15, width: 150, height: 20)
        totalText.draw(in: totalTextRect)
    }
    
    private func drawStructuredFooter(context: CGContext, page: CGRect, company: Company, primary: UIColor) {
        let footerFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = NSAttributedString(string: "Structured financial services. Professional accounting.", attributes: footerAttributes)
        let footerRect = CGRect(x: 30, y: page.height - 50, width: page.width - 60, height: 20)
        footerText.draw(in: footerRect)
    }
}

// MARK: - Legal Traditional Template

struct LegalTraditionalTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent
        
        // Set white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)
        
        // Legal header
        drawLegalHeader(context: context, page: page, company: company, logo: logo, primary: primary, secondary: secondary, accent: accent)
        
        // Traditional invoice section
        drawTraditionalInvoiceSection(context: context, page: page, invoice: invoice, primary: primary, accent: accent)
        
        // Legal bill to section
        drawLegalBillTo(context: context, page: page, customer: customer, primary: primary, accent: accent)
        
        // Traditional table
        drawTraditionalTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary, accent: accent)
        
        // Legal total
        drawLegalTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
        
        // Traditional footer
        drawTraditionalFooter(context: context, page: page, company: company, primary: primary)
    }
    
    private func drawLegalHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Legal background with traditional pattern
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 140)
        
        // Legal background
        context.setFillColor(primary.withAlphaComponent(0.06).cgColor)
        context.fill(headerRect)
        
        // Traditional decorative border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(3)
        context.stroke(headerRect)
        
        // Inner border
        let innerRect = CGRect(x: 10, y: 10, width: page.width - 20, height: 120)
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(1)
        context.stroke(innerRect)
        
        // Logo with legal frame
        if let logo = logo {
            let logoRect = CGRect(x: 40, y: 40, width: 80, height: 80)
            // Legal frame
            context.setStrokeColor(primary.cgColor)
            context.setLineWidth(3)
            context.stroke(logoRect)
            logo.draw(in: logoRect)
        }
        
        // Company name with legal styling
        let companyFont = UIFont.systemFont(ofSize: 30, weight: .bold)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: primary
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 140, y: 50, width: page.width - 180, height: 40)
        companyText.draw(in: companyRect)
        
        // Legal tagline
        let taglineFont = UIFont.systemFont(ofSize: 15, weight: .medium)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: accent
        ]
        let taglineText = NSAttributedString(string: "LEGAL SERVICES", attributes: taglineAttributes)
        let taglineRect = CGRect(x: 140, y: 90, width: page.width - 180, height: 25)
        taglineText.draw(in: taglineRect)
    }
    
    private func drawTraditionalInvoiceSection(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor, accent: UIColor) {
        // Traditional invoice box
        let invoiceRect = CGRect(x: page.width - 220, y: 50, width: 170, height: 80)
        
        // Traditional background
        context.setFillColor(accent.withAlphaComponent(0.1).cgColor)
        context.fill(invoiceRect)
        
        // Traditional border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(3)
        context.stroke(invoiceRect)
        
        // Invoice title with traditional styling
        let titleFont = UIFont.systemFont(ofSize: 22, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: accent
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 210, y: 60, width: 150, height: 30)
        titleText.draw(in: titleRect)
        
        // Invoice number with traditional styling
        let numberFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: primary
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 210, y: 95, width: 150, height: 25)
        numberText.draw(in: numberRect)
        
        // Date with traditional styling
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM dd, yyyy"
        let dateText = NSAttributedString(string: dateFormatter.string(from: invoice.issueDate), attributes: numberAttributes)
        let dateRect = CGRect(x: page.width - 210, y: 120, width: 150, height: 25)
        dateText.draw(in: dateRect)
    }
    
    private func drawLegalBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor, accent: UIColor) {
        // Legal bill to section
        let billToRect = CGRect(x: 40, y: 180, width: 380, height: 110)
        
        // Legal background
        context.setFillColor(primary.withAlphaComponent(0.05).cgColor)
        context.fill(billToRect)
        
        // Legal border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(2)
        context.stroke(billToRect)
        
        // Bill to title with legal styling
        let billToFont = UIFont.systemFont(ofSize: 17, weight: .bold)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "BILL TO:", attributes: billToAttributes)
        let billToTextRect = CGRect(x: 50, y: 190, width: 100, height: 30)
        billToText.draw(in: billToTextRect)
        
        // Customer details with legal styling
        let customerFont = UIFont.systemFont(ofSize: 15, weight: .medium)
        let customerAttributes: [NSAttributedString.Key: Any] = [
            .font: customerFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset: CGFloat = 225
        let customerNameText = NSAttributedString(string: customer.name, attributes: customerAttributes)
        let customerNameRect = CGRect(x: 50, y: yOffset, width: 360, height: 25)
        customerNameText.draw(in: customerNameRect)
        yOffset += 25
        
        if !customer.address.oneLine.isEmpty {
            let addressText = NSAttributedString(string: customer.address.oneLine, attributes: customerAttributes)
            let addressRect = CGRect(x: 50, y: yOffset, width: 360, height: 25)
            addressText.draw(in: addressRect)
            yOffset += 25
        }
        
        if !customer.email.isEmpty {
            let emailText = NSAttributedString(string: customer.email, attributes: customerAttributes)
            let emailRect = CGRect(x: 50, y: yOffset, width: 360, height: 25)
            emailText.draw(in: emailRect)
        }
    }
    
    private func drawTraditionalTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, secondary: UIColor, accent: UIColor) {
        let startY: CGFloat = 330
        
        // Traditional table header
        let headerRect = CGRect(x: 40, y: startY, width: page.width - 80, height: 40)
        
        // Traditional header background
        context.setFillColor(primary.cgColor)
        context.fill(headerRect)
        
        // Header text
        let headerFont = UIFont.systemFont(ofSize: 14, weight: .bold)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white
        ]
        
        let headers = ["Description", "Quantity", "Unit Price", "Total"]
        let columnWidths: [CGFloat] = [340, 90, 110, 110]
        var xOffset: CGFloat = 50
        
        for (index, header) in headers.enumerated() {
            let headerText = NSAttributedString(string: header, attributes: headerAttributes)
            let headerTextRect = CGRect(x: xOffset, y: startY + 12, width: columnWidths[index], height: 25)
            headerText.draw(in: headerTextRect)
            xOffset += columnWidths[index]
        }
        
        // Traditional table rows
        let rowFont = UIFont.systemFont(ofSize: 13, weight: .medium)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset = startY + 40
        for (index, item) in invoice.items.enumerated() {
            // Traditional alternating rows
            if index % 2 == 0 {
                let rowRect = CGRect(x: 40, y: yOffset, width: page.width - 80, height: 35)
                context.setFillColor(accent.withAlphaComponent(0.08).cgColor)
                context.fill(rowRect)
            }
            
            // Row content
            xOffset = 50
            
            let itemText = NSAttributedString(string: item.description, attributes: rowAttributes)
            let itemRect = CGRect(x: xOffset, y: yOffset + 10, width: columnWidths[0], height: 25)
            itemText.draw(in: itemRect)
            xOffset += columnWidths[0]
            
            let qtyText = NSAttributedString(string: "\(item.quantity)", attributes: rowAttributes)
            let qtyRect = CGRect(x: xOffset, y: yOffset + 10, width: columnWidths[1], height: 25)
            qtyText.draw(in: qtyRect)
            xOffset += columnWidths[1]
            
            let rateText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.rate as NSDecimalNumber)))", attributes: rowAttributes)
            let rateRect = CGRect(x: xOffset, y: yOffset + 10, width: columnWidths[2], height: 25)
            rateText.draw(in: rateRect)
            xOffset += columnWidths[2]
            
            let amountText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.total as NSDecimalNumber)))", attributes: rowAttributes)
            let amountRect = CGRect(x: xOffset, y: yOffset + 10, width: columnWidths[3], height: 25)
            amountText.draw(in: amountRect)
            
            yOffset += 35
        }
    }
    
    private func drawLegalTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, accent: UIColor) {
        let totalY: CGFloat = 500
        
        // Legal total box
        let totalRect = CGRect(x: page.width - 250, y: totalY, width: 190, height: 60)
        
        // Legal background
        context.setFillColor(accent.cgColor)
        context.fill(totalRect)
        
        // Legal border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(3)
        context.stroke(totalRect)
        
        // Total text with legal styling
        let totalFont = UIFont.systemFont(ofSize: 19, weight: .bold)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 240, y: totalY + 18, width: 170, height: 25)
        totalText.draw(in: totalTextRect)
    }
    
    private func drawTraditionalFooter(context: CGContext, page: CGRect, company: Company, primary: UIColor) {
        let footerFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = NSAttributedString(string: "Traditional legal services. Professional representation.", attributes: footerAttributes)
        let footerRect = CGRect(x: 40, y: page.height - 50, width: page.width - 80, height: 20)
        footerText.draw(in: footerRect)
    }
}

// MARK: - Healthcare Modern Template

struct HealthcareModernTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent
        
        // Set white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)
        
        // Healthcare header
        drawHealthcareHeader(context: context, page: page, company: company, logo: logo, primary: primary, secondary: secondary, accent: accent)
        
        // Modern invoice section
        drawModernInvoiceSection(context: context, page: page, invoice: invoice, primary: primary, accent: accent)
        
        // Healthcare bill to section
        drawHealthcareBillTo(context: context, page: page, customer: customer, primary: primary, accent: accent)
        
        // Modern table
        drawModernTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary, accent: accent)
        
        // Healthcare total
        drawHealthcareTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
        
        // Modern footer
        drawModernFooter(context: context, page: page, company: company, primary: primary)
    }
    
    private func drawHealthcareHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Healthcare background with modern pattern
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 130)
        
        // Healthcare background
        context.setFillColor(primary.withAlphaComponent(0.1).cgColor)
        context.fill(headerRect)
        
        // Modern wave pattern
        context.setStrokeColor(accent.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(2)
        for i in 0..<8 {
            let y = CGFloat(i * 16)
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: page.width, y: y + 8))
        }
        context.strokePath()
        
        // Logo with healthcare frame
        if let logo = logo {
            let logoRect = CGRect(x: 35, y: 35, width: 75, height: 75)
            // Healthcare frame
            context.setStrokeColor(accent.cgColor)
            context.setLineWidth(2)
            context.stroke(logoRect)
            logo.draw(in: logoRect)
        }
        
        // Company name with healthcare styling
        let companyFont = UIFont.systemFont(ofSize: 27, weight: .semibold)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: primary
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 125, y: 45, width: page.width - 155, height: 35)
        companyText.draw(in: companyRect)
        
        // Healthcare tagline
        let taglineFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: accent
        ]
        let taglineText = NSAttributedString(string: "HEALTHCARE SERVICES", attributes: taglineAttributes)
        let taglineRect = CGRect(x: 125, y: 80, width: page.width - 155, height: 20)
        taglineText.draw(in: taglineRect)
    }
    
    private func drawModernInvoiceSection(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor, accent: UIColor) {
        // Modern invoice box
        let invoiceRect = CGRect(x: page.width - 200, y: 40, width: 150, height: 80)
        
        // Modern background
        context.setFillColor(accent.withAlphaComponent(0.12).cgColor)
        context.fill(invoiceRect)
        
        // Modern border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(2)
        context.stroke(invoiceRect)
        
        // Invoice title with modern styling
        let titleFont = UIFont.systemFont(ofSize: 19, weight: .semibold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: accent
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 190, y: 50, width: 130, height: 25)
        titleText.draw(in: titleRect)
        
        // Invoice number with modern styling
        let numberFont = UIFont.systemFont(ofSize: 15, weight: .medium)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: primary
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 190, y: 80, width: 130, height: 20)
        numberText.draw(in: numberRect)
        
        // Date with modern styling
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        let dateText = NSAttributedString(string: dateFormatter.string(from: invoice.issueDate), attributes: numberAttributes)
        let dateRect = CGRect(x: page.width - 190, y: 105, width: 130, height: 20)
        dateText.draw(in: dateRect)
    }
    
    private func drawHealthcareBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor, accent: UIColor) {
        // Healthcare bill to section
        let billToRect = CGRect(x: 35, y: 160, width: 360, height: 100)
        
        // Healthcare background
        context.setFillColor(primary.withAlphaComponent(0.06).cgColor)
        context.fill(billToRect)
        
        // Healthcare border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(1)
        context.stroke(billToRect)
        
        // Bill to title with healthcare styling
        let billToFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "BILL TO:", attributes: billToAttributes)
        let billToTextRect = CGRect(x: 45, y: 170, width: 100, height: 25)
        billToText.draw(in: billToTextRect)
        
        // Customer details with healthcare styling
        let customerFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        let customerAttributes: [NSAttributedString.Key: Any] = [
            .font: customerFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset: CGFloat = 200
        let customerNameText = NSAttributedString(string: customer.name, attributes: customerAttributes)
        let customerNameRect = CGRect(x: 45, y: yOffset, width: 340, height: 20)
        customerNameText.draw(in: customerNameRect)
        yOffset += 20
        
        if !customer.address.oneLine.isEmpty {
            let addressText = NSAttributedString(string: customer.address.oneLine, attributes: customerAttributes)
            let addressRect = CGRect(x: 45, y: yOffset, width: 340, height: 20)
            addressText.draw(in: addressRect)
            yOffset += 20
        }
        
        if !customer.email.isEmpty {
            let emailText = NSAttributedString(string: customer.email, attributes: customerAttributes)
            let emailRect = CGRect(x: 45, y: yOffset, width: 340, height: 20)
            emailText.draw(in: emailRect)
        }
    }
    
    private func drawModernTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, secondary: UIColor, accent: UIColor) {
        let startY: CGFloat = 290
        
        // Modern table header
        let headerRect = CGRect(x: 35, y: startY, width: page.width - 70, height: 35)
        
        // Modern header background
        context.setFillColor(primary.cgColor)
        context.fill(headerRect)
        
        // Header text
        let headerFont = UIFont.systemFont(ofSize: 13, weight: .semibold)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white
        ]
        
        let headers = ["Description", "Quantity", "Unit Price", "Total"]
        let columnWidths: [CGFloat] = [330, 80, 100, 100]
        var xOffset: CGFloat = 45
        
        for (index, header) in headers.enumerated() {
            let headerText = NSAttributedString(string: header, attributes: headerAttributes)
            let headerTextRect = CGRect(x: xOffset, y: startY + 10, width: columnWidths[index], height: 20)
            headerText.draw(in: headerTextRect)
            xOffset += columnWidths[index]
        }
        
        // Modern table rows
        let rowFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset = startY + 35
        for (index, item) in invoice.items.enumerated() {
            // Modern alternating rows
            if index % 2 == 0 {
                let rowRect = CGRect(x: 35, y: yOffset, width: page.width - 70, height: 30)
                context.setFillColor(accent.withAlphaComponent(0.07).cgColor)
                context.fill(rowRect)
            }
            
            // Row content
            xOffset = 45
            
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
    
    private func drawHealthcareTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, accent: UIColor) {
        let totalY: CGFloat = 460
        
        // Healthcare total box
        let totalRect = CGRect(x: page.width - 230, y: totalY, width: 180, height: 50)
        
        // Healthcare background
        context.setFillColor(accent.cgColor)
        context.fill(totalRect)
        
        // Healthcare border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(2)
        context.stroke(totalRect)
        
        // Total text with healthcare styling
        let totalFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 220, y: totalY + 15, width: 160, height: 20)
        totalText.draw(in: totalTextRect)
    }
    
    private func drawModernFooter(context: CGContext, page: CGRect, company: Company, primary: UIColor) {
        let footerFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = NSAttributedString(string: "Modern healthcare services. Caring for your wellbeing.", attributes: footerAttributes)
        let footerRect = CGRect(x: 35, y: page.height - 50, width: page.width - 70, height: 20)
        footerText.draw(in: footerRect)
    }
}
