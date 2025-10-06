import Foundation
import UIKit

// MARK: - Design Studio Template

struct DesignStudioTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent
        
        // Set white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)
        
        // Studio header
        drawStudioHeader(context: context, page: page, company: company, logo: logo, primary: primary, secondary: secondary, accent: accent)
        
        // Design invoice section
        drawDesignInvoiceSection(context: context, page: page, invoice: invoice, primary: primary, accent: accent)
        
        // Studio bill to section
        drawStudioBillTo(context: context, page: page, customer: customer, primary: primary, accent: accent)
        
        // Design table
        drawDesignTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary, accent: accent)
        
        // Studio total
        drawStudioTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
        
        // Design footer
        drawDesignFooter(context: context, page: page, company: company, primary: primary)
    }
    
    private func drawStudioHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Studio background with design pattern
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 120)
        
        // Studio background
        context.setFillColor(primary.withAlphaComponent(0.1).cgColor)
        context.fill(headerRect)
        
        // Design studio elements
        context.setFillColor(accent.withAlphaComponent(0.2).cgColor)
        for i in 0..<8 {
            let triangle = CGRect(x: CGFloat(i * 80), y: 15, width: 20, height: 20)
            context.fillEllipse(in: triangle)
        }
        
        // Logo with studio frame
        if let logo = logo {
            let logoRect = CGRect(x: 35, y: 30, width: 70, height: 70)
            // Studio frame
            context.setStrokeColor(accent.cgColor)
            context.setLineWidth(3)
            context.stroke(logoRect)
            logo.draw(in: logoRect)
        }
        
        // Company name with studio styling
        let companyFont = UIFont.systemFont(ofSize: 26, weight: .semibold)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: primary
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 120, y: 40, width: page.width - 150, height: 35)
        companyText.draw(in: companyRect)
        
        // Studio tagline
        let taglineFont = UIFont.systemFont(ofSize: 13, weight: .medium)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: accent
        ]
        let taglineText = NSAttributedString(string: "DESIGN STUDIO", attributes: taglineAttributes)
        let taglineRect = CGRect(x: 120, y: 75, width: page.width - 150, height: 20)
        taglineText.draw(in: taglineRect)
    }
    
    private func drawDesignInvoiceSection(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor, accent: UIColor) {
        // Design invoice box
        let invoiceRect = CGRect(x: page.width - 190, y: 35, width: 145, height: 75)
        
        // Design background
        context.setFillColor(accent.withAlphaComponent(0.12).cgColor)
        context.fill(invoiceRect)
        
        // Design border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(3)
        context.stroke(invoiceRect)
        
        // Invoice title with design styling
        let titleFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: accent
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 180, y: 45, width: 125, height: 25)
        titleText.draw(in: titleRect)
        
        // Invoice number with design styling
        let numberFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: primary
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 180, y: 75, width: 125, height: 20)
        numberText.draw(in: numberRect)
        
        // Date with design styling
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        let dateText = NSAttributedString(string: dateFormatter.string(from: invoice.issueDate), attributes: numberAttributes)
        let dateRect = CGRect(x: page.width - 180, y: 100, width: 125, height: 20)
        dateText.draw(in: dateRect)
    }
    
    private func drawStudioBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor, accent: UIColor) {
        // Studio bill to section
        let billToRect = CGRect(x: 35, y: 150, width: 350, height: 95)
        
        // Studio background
        context.setFillColor(primary.withAlphaComponent(0.06).cgColor)
        context.fill(billToRect)
        
        // Studio border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(2)
        context.stroke(billToRect)
        
        // Bill to title with studio styling
        let billToFont = UIFont.systemFont(ofSize: 15, weight: .semibold)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "BILL TO:", attributes: billToAttributes)
        let billToTextRect = CGRect(x: 45, y: 160, width: 100, height: 25)
        billToText.draw(in: billToTextRect)
        
        // Customer details with studio styling
        let customerFont = UIFont.systemFont(ofSize: 13, weight: .regular)
        let customerAttributes: [NSAttributedString.Key: Any] = [
            .font: customerFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset: CGFloat = 190
        let customerNameText = NSAttributedString(string: customer.name, attributes: customerAttributes)
        let customerNameRect = CGRect(x: 45, y: yOffset, width: 330, height: 20)
        customerNameText.draw(in: customerNameRect)
        yOffset += 20
        
        if !customer.address.oneLine.isEmpty {
            let addressText = NSAttributedString(string: customer.address.oneLine, attributes: customerAttributes)
            let addressRect = CGRect(x: 45, y: yOffset, width: 330, height: 20)
            addressText.draw(in: addressRect)
            yOffset += 20
        }
        
        if !customer.email.isEmpty {
            let emailText = NSAttributedString(string: customer.email, attributes: customerAttributes)
            let emailRect = CGRect(x: 45, y: yOffset, width: 330, height: 20)
            emailText.draw(in: emailRect)
        }
    }
    
    private func drawDesignTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, secondary: UIColor, accent: UIColor) {
        let startY: CGFloat = 275
        
        // Design table header
        let headerRect = CGRect(x: 35, y: startY, width: page.width - 70, height: 35)
        
        // Design header background
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
        var xOffset: CGFloat = 45
        
        for (index, header) in headers.enumerated() {
            let headerText = NSAttributedString(string: header, attributes: headerAttributes)
            let headerTextRect = CGRect(x: xOffset, y: startY + 10, width: columnWidths[index], height: 20)
            headerText.draw(in: headerTextRect)
            xOffset += columnWidths[index]
        }
        
        // Design table rows
        let rowFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset = startY + 35
        for (index, item) in invoice.items.enumerated() {
            // Studio alternating rows
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
    
    private func drawStudioTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, accent: UIColor) {
        let totalY: CGFloat = 440
        
        // Studio total box
        let totalRect = CGRect(x: page.width - 200, y: totalY, width: 150, height: 50)
        
        // Studio background
        context.setFillColor(accent.cgColor)
        context.fill(totalRect)
        
        // Studio border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(3)
        context.stroke(totalRect)
        
        // Total text with studio styling
        let totalFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 190, y: totalY + 15, width: 130, height: 20)
        totalText.draw(in: totalTextRect)
    }
    
    private func drawDesignFooter(context: CGContext, page: CGRect, company: Company, primary: UIColor) {
        let footerFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = NSAttributedString(string: "Design studio services. Creative solutions delivered.", attributes: footerAttributes)
        let footerRect = CGRect(x: 35, y: page.height - 50, width: page.width - 70, height: 20)
        footerText.draw(in: footerRect)
    }
}

// MARK: - Fashion Elegant Template

struct FashionElegantTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent
        
        // Set white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)
        
        // Elegant header
        drawElegantHeader(context: context, page: page, company: company, logo: logo, primary: primary, secondary: secondary, accent: accent)
        
        // Fashion invoice section
        drawFashionInvoiceSection(context: context, page: page, invoice: invoice, primary: primary, accent: accent)
        
        // Elegant bill to section
        drawElegantBillTo(context: context, page: page, customer: customer, primary: primary, accent: accent)
        
        // Fashion table
        drawFashionTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary, accent: accent)
        
        // Elegant total
        drawElegantTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
        
        // Fashion footer
        drawFashionFooter(context: context, page: page, company: company, primary: primary)
    }
    
    private func drawElegantHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Elegant background with fashion pattern
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 130)
        
        // Elegant background
        context.setFillColor(primary.withAlphaComponent(0.08).cgColor)
        context.fill(headerRect)
        
        // Fashion elegant elements
        context.setFillColor(accent.withAlphaComponent(0.15).cgColor)
        for i in 0..<6 {
            let circle = CGRect(x: CGFloat(i * 100 + 30), y: 20, width: 15, height: 15)
            context.fillEllipse(in: circle)
        }
        
        // Logo with elegant frame
        if let logo = logo {
            let logoRect = CGRect(x: 40, y: 35, width: 75, height: 75)
            // Elegant frame
            context.setStrokeColor(accent.cgColor)
            context.setLineWidth(2)
            context.stroke(logoRect)
            logo.draw(in: logoRect)
        }
        
        // Company name with elegant styling
        let companyFont = UIFont.systemFont(ofSize: 28, weight: .light)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: primary
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 130, y: 45, width: page.width - 160, height: 35)
        companyText.draw(in: companyRect)
        
        // Elegant tagline
        let taglineFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: accent
        ]
        let taglineText = NSAttributedString(string: "FASHION SERVICES", attributes: taglineAttributes)
        let taglineRect = CGRect(x: 130, y: 80, width: page.width - 160, height: 20)
        taglineText.draw(in: taglineRect)
    }
    
    private func drawFashionInvoiceSection(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor, accent: UIColor) {
        // Fashion invoice box
        let invoiceRect = CGRect(x: page.width - 200, y: 40, width: 150, height: 80)
        
        // Fashion background
        context.setFillColor(accent.withAlphaComponent(0.1).cgColor)
        context.fill(invoiceRect)
        
        // Fashion border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(2)
        context.stroke(invoiceRect)
        
        // Invoice title with fashion styling
        let titleFont = UIFont.systemFont(ofSize: 19, weight: .light)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: accent
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 190, y: 50, width: 130, height: 25)
        titleText.draw(in: titleRect)
        
        // Invoice number with fashion styling
        let numberFont = UIFont.systemFont(ofSize: 15, weight: .medium)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: primary
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 190, y: 80, width: 130, height: 20)
        numberText.draw(in: numberRect)
        
        // Date with fashion styling
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        let dateText = NSAttributedString(string: dateFormatter.string(from: invoice.issueDate), attributes: numberAttributes)
        let dateRect = CGRect(x: page.width - 190, y: 105, width: 130, height: 20)
        dateText.draw(in: dateRect)
    }
    
    private func drawElegantBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor, accent: UIColor) {
        // Elegant bill to section
        let billToRect = CGRect(x: 40, y: 160, width: 350, height: 100)
        
        // Elegant background
        context.setFillColor(primary.withAlphaComponent(0.04).cgColor)
        context.fill(billToRect)
        
        // Elegant border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(1)
        context.stroke(billToRect)
        
        // Bill to title with elegant styling
        let billToFont = UIFont.systemFont(ofSize: 16, weight: .light)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "Bill To:", attributes: billToAttributes)
        let billToTextRect = CGRect(x: 50, y: 170, width: 100, height: 25)
        billToText.draw(in: billToTextRect)
        
        // Customer details with elegant styling
        let customerFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        let customerAttributes: [NSAttributedString.Key: Any] = [
            .font: customerFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset: CGFloat = 200
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
    
    private func drawFashionTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, secondary: UIColor, accent: UIColor) {
        let startY: CGFloat = 290
        
        // Fashion table header
        let headerRect = CGRect(x: 40, y: startY, width: page.width - 80, height: 35)
        
        // Fashion header background
        context.setFillColor(primary.cgColor)
        context.fill(headerRect)
        
        // Header text
        let headerFont = UIFont.systemFont(ofSize: 13, weight: .light)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white
        ]
        
        let headers = ["Description", "Quantity", "Unit Price", "Total"]
        let columnWidths: [CGFloat] = [320, 80, 100, 100]
        var xOffset: CGFloat = 50
        
        for (index, header) in headers.enumerated() {
            let headerText = NSAttributedString(string: header, attributes: headerAttributes)
            let headerTextRect = CGRect(x: xOffset, y: startY + 10, width: columnWidths[index], height: 20)
            headerText.draw(in: headerTextRect)
            xOffset += columnWidths[index]
        }
        
        // Fashion table rows
        let rowFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset = startY + 35
        for (index, item) in invoice.items.enumerated() {
            // Elegant alternating rows
            if index % 2 == 0 {
                let rowRect = CGRect(x: 40, y: yOffset, width: page.width - 80, height: 30)
                context.setFillColor(accent.withAlphaComponent(0.05).cgColor)
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
    
    private func drawElegantTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, accent: UIColor) {
        let totalY: CGFloat = 460
        
        // Elegant total box
        let totalRect = CGRect(x: page.width - 220, y: totalY, width: 170, height: 50)
        
        // Elegant background
        context.setFillColor(accent.cgColor)
        context.fill(totalRect)
        
        // Elegant border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(2)
        context.stroke(totalRect)
        
        // Total text with elegant styling
        let totalFont = UIFont.systemFont(ofSize: 17, weight: .light)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 210, y: totalY + 15, width: 150, height: 20)
        totalText.draw(in: totalTextRect)
    }
    
    private func drawFashionFooter(context: CGContext, page: CGRect, company: Company, primary: UIColor) {
        let footerFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = NSAttributedString(string: "Elegant fashion services. Style and sophistication delivered.", attributes: footerAttributes)
        let footerRect = CGRect(x: 40, y: page.height - 50, width: page.width - 80, height: 20)
        footerText.draw(in: footerRect)
    }
}

// MARK: - Photography Clean Template

struct PhotographyCleanTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent
        
        // Set white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)
        
        // Clean header
        drawCleanHeader(context: context, page: page, company: company, logo: logo, primary: primary, secondary: secondary, accent: accent)
        
        // Photography invoice section
        drawPhotographyInvoiceSection(context: context, page: page, invoice: invoice, primary: primary, accent: accent)
        
        // Clean bill to section
        drawCleanBillTo(context: context, page: page, customer: customer, primary: primary, accent: accent)
        
        // Photography table
        drawPhotographyTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary, accent: accent)
        
        // Clean total
        drawCleanTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
        
        // Photography footer
        drawPhotographyFooter(context: context, page: page, company: company, primary: primary)
    }
    
    private func drawCleanHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Clean background with photography pattern
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 115)
        
        // Clean background
        context.setFillColor(primary.withAlphaComponent(0.06).cgColor)
        context.fill(headerRect)
        
        // Photography clean elements
        context.setFillColor(accent.withAlphaComponent(0.12).cgColor)
        for i in 0..<5 {
            let rect = CGRect(x: CGFloat(i * 120), y: 20, width: 60, height: 60)
            context.fillEllipse(in: rect)
        }
        
        // Logo with clean frame
        if let logo = logo {
            let logoRect = CGRect(x: 30, y: 25, width: 65, height: 65)
            // Clean frame
            context.setStrokeColor(primary.cgColor)
            context.setLineWidth(2)
            context.stroke(logoRect)
            logo.draw(in: logoRect)
        }
        
        // Company name with clean styling
        let companyFont = UIFont.systemFont(ofSize: 25, weight: .semibold)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: primary
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 110, y: 35, width: page.width - 140, height: 35)
        companyText.draw(in: companyRect)
        
        // Clean tagline
        let taglineFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: accent
        ]
        let taglineText = NSAttributedString(string: "PHOTOGRAPHY SERVICES", attributes: taglineAttributes)
        let taglineRect = CGRect(x: 110, y: 70, width: page.width - 140, height: 20)
        taglineText.draw(in: taglineRect)
    }
    
    private func drawPhotographyInvoiceSection(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor, accent: UIColor) {
        // Photography invoice box
        let invoiceRect = CGRect(x: page.width - 185, y: 30, width: 140, height: 70)
        
        // Photography background
        context.setFillColor(accent.withAlphaComponent(0.08).cgColor)
        context.fill(invoiceRect)
        
        // Photography border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(2)
        context.stroke(invoiceRect)
        
        // Invoice title with photography styling
        let titleFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: accent
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 175, y: 40, width: 120, height: 25)
        titleText.draw(in: titleRect)
        
        // Invoice number with photography styling
        let numberFont = UIFont.systemFont(ofSize: 13, weight: .medium)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: primary
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 175, y: 70, width: 120, height: 20)
        numberText.draw(in: numberRect)
        
        // Date with photography styling
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        let dateText = NSAttributedString(string: dateFormatter.string(from: invoice.issueDate), attributes: numberAttributes)
        let dateRect = CGRect(x: page.width - 175, y: 95, width: 120, height: 20)
        dateText.draw(in: dateRect)
    }
    
    private func drawCleanBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor, accent: UIColor) {
        // Clean bill to section
        let billToRect = CGRect(x: 30, y: 145, width: 340, height: 90)
        
        // Clean background
        context.setFillColor(primary.withAlphaComponent(0.04).cgColor)
        context.fill(billToRect)
        
        // Clean border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(1)
        context.stroke(billToRect)
        
        // Bill to title with clean styling
        let billToFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "BILL TO:", attributes: billToAttributes)
        let billToTextRect = CGRect(x: 40, y: 155, width: 100, height: 25)
        billToText.draw(in: billToTextRect)
        
        // Customer details with clean styling
        let customerFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let customerAttributes: [NSAttributedString.Key: Any] = [
            .font: customerFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset: CGFloat = 185
        let customerNameText = NSAttributedString(string: customer.name, attributes: customerAttributes)
        let customerNameRect = CGRect(x: 40, y: yOffset, width: 320, height: 20)
        customerNameText.draw(in: customerNameRect)
        yOffset += 20
        
        if !customer.address.oneLine.isEmpty {
            let addressText = NSAttributedString(string: customer.address.oneLine, attributes: customerAttributes)
            let addressRect = CGRect(x: 40, y: yOffset, width: 320, height: 20)
            addressText.draw(in: addressRect)
            yOffset += 20
        }
        
        if !customer.email.isEmpty {
            let emailText = NSAttributedString(string: customer.email, attributes: customerAttributes)
            let emailRect = CGRect(x: 40, y: yOffset, width: 320, height: 20)
            emailText.draw(in: emailRect)
        }
    }
    
    private func drawPhotographyTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, secondary: UIColor, accent: UIColor) {
        let startY: CGFloat = 265
        
        // Photography table header
        let headerRect = CGRect(x: 30, y: startY, width: page.width - 60, height: 32)
        
        // Photography header background
        context.setFillColor(primary.cgColor)
        context.fill(headerRect)
        
        // Header text
        let headerFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white
        ]
        
        let headers = ["Description", "Quantity", "Unit Price", "Total"]
        let columnWidths: [CGFloat] = [310, 70, 90, 90]
        var xOffset: CGFloat = 40
        
        for (index, header) in headers.enumerated() {
            let headerText = NSAttributedString(string: header, attributes: headerAttributes)
            let headerTextRect = CGRect(x: xOffset, y: startY + 8, width: columnWidths[index], height: 20)
            headerText.draw(in: headerTextRect)
            xOffset += columnWidths[index]
        }
        
        // Photography table rows
        let rowFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset = startY + 32
        for (index, item) in invoice.items.enumerated() {
            // Clean alternating rows
            if index % 2 == 0 {
                let rowRect = CGRect(x: 30, y: yOffset, width: page.width - 60, height: 28)
                context.setFillColor(accent.withAlphaComponent(0.06).cgColor)
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
            
            yOffset += 28
        }
    }
    
    private func drawCleanTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, accent: UIColor) {
        let totalY: CGFloat = 420
        
        // Clean total box
        let totalRect = CGRect(x: page.width - 190, y: totalY, width: 150, height: 45)
        
        // Clean background
        context.setFillColor(accent.cgColor)
        context.fill(totalRect)
        
        // Clean border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(2)
        context.stroke(totalRect)
        
        // Total text with clean styling
        let totalFont = UIFont.systemFont(ofSize: 15, weight: .semibold)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 180, y: totalY + 12, width: 130, height: 20)
        totalText.draw(in: totalTextRect)
    }
    
    private func drawPhotographyFooter(context: CGContext, page: CGRect, company: Company, primary: UIColor) {
        let footerFont = UIFont.systemFont(ofSize: 9, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = NSAttributedString(string: "Clean photography services. Capturing moments with precision.", attributes: footerAttributes)
        let footerRect = CGRect(x: 30, y: page.height - 50, width: page.width - 60, height: 20)
        footerText.draw(in: footerRect)
    }
}
