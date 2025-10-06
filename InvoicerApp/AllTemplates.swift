import Foundation
import UIKit

// MARK: - All Geometric Abstract Template

struct AllGeometricAbstractTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent
        
        // Set white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)
        
        // Geometric header
        drawGeometricHeader(context: context, page: page, company: company, logo: logo, primary: primary, secondary: secondary, accent: accent)
        
        // Abstract invoice section
        drawAbstractInvoiceSection(context: context, page: page, invoice: invoice, primary: primary, accent: accent)
        
        // Geometric bill to section
        drawGeometricBillTo(context: context, page: page, customer: customer, primary: primary, accent: accent)
        
        // Abstract table
        drawAbstractTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary, accent: accent)
        
        // Geometric total
        drawGeometricTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
        
        // Abstract footer
        drawAbstractFooter(context: context, page: page, company: company, primary: primary)
    }
    
    private func drawGeometricHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Geometric background with abstract shapes
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 130)
        
        // Abstract background
        context.setFillColor(primary.withAlphaComponent(0.08).cgColor)
        context.fill(headerRect)
        
        // Geometric shapes
        context.setFillColor(accent.withAlphaComponent(0.15).cgColor)
        for i in 0..<8 {
            let triangle = CGRect(x: CGFloat(i * 80), y: 20, width: 40, height: 40)
            context.fillEllipse(in: triangle)
        }
        
        // Logo with geometric frame
        if let logo = logo {
            let logoRect = CGRect(x: 40, y: 40, width: 70, height: 70)
            // Geometric hexagonal frame
            context.setStrokeColor(accent.cgColor)
            context.setLineWidth(3)
            context.stroke(logoRect)
            logo.draw(in: logoRect)
        }
        
        // Company name with geometric styling
        let companyFont = UIFont.systemFont(ofSize: 26, weight: .black)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: primary
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 130, y: 50, width: page.width - 170, height: 35)
        companyText.draw(in: companyRect)
        
        // Abstract tagline
        let taglineFont = UIFont.systemFont(ofSize: 13, weight: .medium)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: accent
        ]
        let taglineText = NSAttributedString(string: "GEOMETRIC DESIGN", attributes: taglineAttributes)
        let taglineRect = CGRect(x: 130, y: 85, width: page.width - 170, height: 20)
        taglineText.draw(in: taglineRect)
    }
    
    private func drawAbstractInvoiceSection(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor, accent: UIColor) {
        // Abstract invoice box
        let invoiceRect = CGRect(x: page.width - 180, y: 40, width: 130, height: 80)
        
        // Abstract background
        context.setFillColor(accent.withAlphaComponent(0.12).cgColor)
        context.fill(invoiceRect)
        
        // Abstract border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(3)
        context.stroke(invoiceRect)
        
        // Invoice title with abstract styling
        let titleFont = UIFont.systemFont(ofSize: 18, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: accent
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 170, y: 50, width: 110, height: 25)
        titleText.draw(in: titleRect)
        
        // Invoice number with abstract styling
        let numberFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: primary
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 170, y: 80, width: 110, height: 20)
        numberText.draw(in: numberRect)
        
        // Date with abstract styling
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let dateText = NSAttributedString(string: dateFormatter.string(from: invoice.issueDate), attributes: numberAttributes)
        let dateRect = CGRect(x: page.width - 170, y: 105, width: 110, height: 20)
        dateText.draw(in: dateRect)
    }
    
    private func drawGeometricBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor, accent: UIColor) {
        // Geometric bill to section
        let billToRect = CGRect(x: 40, y: 160, width: 300, height: 90)
        
        // Geometric background
        context.setFillColor(primary.withAlphaComponent(0.06).cgColor)
        context.fill(billToRect)
        
        // Geometric border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(2)
        context.stroke(billToRect)
        
        // Bill to title with geometric styling
        let billToFont = UIFont.systemFont(ofSize: 14, weight: .bold)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "BILL TO:", attributes: billToAttributes)
        let billToTextRect = CGRect(x: 50, y: 170, width: 100, height: 25)
        billToText.draw(in: billToTextRect)
        
        // Customer details with geometric styling
        let customerFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        let customerAttributes: [NSAttributedString.Key: Any] = [
            .font: customerFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset: CGFloat = 200
        let customerNameText = NSAttributedString(string: customer.name, attributes: customerAttributes)
        let customerNameRect = CGRect(x: 50, y: yOffset, width: 280, height: 20)
        customerNameText.draw(in: customerNameRect)
        yOffset += 18
        
        if !customer.address.oneLine.isEmpty {
            let addressText = NSAttributedString(string: customer.address.oneLine, attributes: customerAttributes)
            let addressRect = CGRect(x: 50, y: yOffset, width: 280, height: 20)
            addressText.draw(in: addressRect)
            yOffset += 18
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
        let headerRect = CGRect(x: 40, y: startY, width: page.width - 80, height: 35)
        
        // Abstract header background
        context.setFillColor(primary.cgColor)
        context.fill(headerRect)
        
        // Header text
        let headerFont = UIFont.systemFont(ofSize: 12, weight: .bold)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white
        ]
        
        let headers = ["Description", "Qty", "Rate", "Total"]
        let columnWidths: [CGFloat] = [300, 70, 90, 90]
        var xOffset: CGFloat = 50
        
        for (index, header) in headers.enumerated() {
            let headerText = NSAttributedString(string: header, attributes: headerAttributes)
            let headerTextRect = CGRect(x: xOffset, y: startY + 10, width: columnWidths[index], height: 20)
            headerText.draw(in: headerTextRect)
            xOffset += columnWidths[index]
        }
        
        // Abstract table rows
        let rowFont = UIFont.systemFont(ofSize: 11, weight: .medium)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset = startY + 35
        for (index, item) in invoice.items.enumerated() {
            // Abstract alternating rows
            if index % 2 == 0 {
                let rowRect = CGRect(x: 40, y: yOffset, width: page.width - 80, height: 30)
                context.setFillColor(accent.withAlphaComponent(0.08).cgColor)
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
    
    private func drawGeometricTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, accent: UIColor) {
        let totalY: CGFloat = 450
        
        // Geometric total box
        let totalRect = CGRect(x: page.width - 200, y: totalY, width: 140, height: 50)
        
        // Geometric background
        context.setFillColor(accent.cgColor)
        context.fill(totalRect)
        
        // Geometric border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(3)
        context.stroke(totalRect)
        
        // Total text with geometric styling
        let totalFont = UIFont.systemFont(ofSize: 16, weight: .bold)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 190, y: totalY + 15, width: 120, height: 20)
        totalText.draw(in: totalTextRect)
    }
    
    private func drawAbstractFooter(context: CGContext, page: CGRect, company: Company, primary: UIColor) {
        let footerFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = NSAttributedString(string: "Geometric precision. Abstract beauty.", attributes: footerAttributes)
        let footerRect = CGRect(x: 40, y: page.height - 50, width: page.width - 80, height: 20)
        footerText.draw(in: footerRect)
    }
}

// MARK: - All Vintage Retro Template

struct AllVintageRetroTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent
        
        // Set white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)
        
        // Vintage header
        drawVintageHeader(context: context, page: page, company: company, logo: logo, primary: primary, secondary: secondary, accent: accent)
        
        // Retro invoice section
        drawRetroInvoiceSection(context: context, page: page, invoice: invoice, primary: primary, accent: accent)
        
        // Vintage bill to section
        drawVintageBillTo(context: context, page: page, customer: customer, primary: primary, accent: accent)
        
        // Retro table
        drawRetroTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary, accent: accent)
        
        // Vintage total
        drawVintageTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
        
        // Retro footer
        drawRetroFooter(context: context, page: page, company: company, primary: primary)
    }
    
    private func drawVintageHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Vintage background with retro pattern
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 140)
        
        // Vintage background
        context.setFillColor(primary.withAlphaComponent(0.12).cgColor)
        context.fill(headerRect)
        
        // Retro decorative elements
        context.setFillColor(accent.withAlphaComponent(0.2).cgColor)
        for i in 0..<6 {
            let circle = CGRect(x: CGFloat(i * 100 + 20), y: 10, width: 15, height: 15)
            context.fillEllipse(in: circle)
        }
        
        // Logo with vintage frame
        if let logo = logo {
            let logoRect = CGRect(x: 50, y: 40, width: 80, height: 80)
            // Vintage decorative frame
            context.setStrokeColor(accent.cgColor)
            context.setLineWidth(4)
            context.stroke(logoRect)
            logo.draw(in: logoRect)
        }
        
        // Company name with vintage styling
        let companyFont = UIFont.systemFont(ofSize: 30, weight: .bold)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: primary
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 150, y: 50, width: page.width - 200, height: 40)
        companyText.draw(in: companyRect)
        
        // Vintage tagline
        let taglineFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: accent
        ]
        let taglineText = NSAttributedString(string: "VINTAGE SERVICES", attributes: taglineAttributes)
        let taglineRect = CGRect(x: 150, y: 90, width: page.width - 200, height: 25)
        taglineText.draw(in: taglineRect)
    }
    
    private func drawRetroInvoiceSection(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor, accent: UIColor) {
        // Retro invoice box
        let invoiceRect = CGRect(x: page.width - 200, y: 50, width: 150, height: 80)
        
        // Retro background
        context.setFillColor(accent.withAlphaComponent(0.15).cgColor)
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
        let titleRect = CGRect(x: page.width - 190, y: 60, width: 130, height: 25)
        titleText.draw(in: titleRect)
        
        // Invoice number with retro styling
        let numberFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: primary
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 190, y: 90, width: 130, height: 20)
        numberText.draw(in: numberRect)
        
        // Date with retro styling
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        let dateText = NSAttributedString(string: dateFormatter.string(from: invoice.issueDate), attributes: numberAttributes)
        let dateRect = CGRect(x: page.width - 190, y: 115, width: 130, height: 20)
        dateText.draw(in: dateRect)
    }
    
    private func drawVintageBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor, accent: UIColor) {
        // Vintage bill to section
        let billToRect = CGRect(x: 50, y: 180, width: 350, height: 100)
        
        // Vintage background
        context.setFillColor(primary.withAlphaComponent(0.08).cgColor)
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
            .foregroundColor: UIColor.black
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
        
        // Retro header background
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
            .foregroundColor: UIColor.black
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
        let totalRect = CGRect(x: page.width - 220, y: totalY, width: 160, height: 55)
        
        // Vintage background
        context.setFillColor(accent.cgColor)
        context.fill(totalRect)
        
        // Vintage border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(3)
        context.stroke(totalRect)
        
        // Total text with vintage styling
        let totalFont = UIFont.systemFont(ofSize: 18, weight: .bold)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 210, y: totalY + 17, width: 140, height: 20)
        totalText.draw(in: totalTextRect)
    }
    
    private func drawRetroFooter(context: CGContext, page: CGRect, company: Company, primary: UIColor) {
        let footerFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = NSAttributedString(string: "Vintage charm. Timeless service.", attributes: footerAttributes)
        let footerRect = CGRect(x: 50, y: page.height - 50, width: page.width - 100, height: 20)
        footerText.draw(in: footerRect)
    }
}

// MARK: - All Business Classic Template

struct AllBusinessClassicTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent
        
        // Set white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)
        
        // Classic header
        drawClassicHeader(context: context, page: page, company: company, logo: logo, primary: primary, secondary: secondary, accent: accent)
        
        // Business invoice section
        drawBusinessInvoiceSection(context: context, page: page, invoice: invoice, primary: primary, accent: accent)
        
        // Classic bill to section
        drawClassicBillTo(context: context, page: page, customer: customer, primary: primary, accent: accent)
        
        // Business table
        drawBusinessTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary, accent: accent)
        
        // Classic total
        drawClassicTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
        
        // Business footer
        drawBusinessFooter(context: context, page: page, company: company, primary: primary)
    }
    
    private func drawClassicHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Classic background
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 120)
        
        // Classic background
        context.setFillColor(primary.withAlphaComponent(0.06).cgColor)
        context.fill(headerRect)
        
        // Classic border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(2)
        context.stroke(headerRect)
        
        // Logo with classic frame
        if let logo = logo {
            let logoRect = CGRect(x: 40, y: 30, width: 70, height: 70)
            // Classic frame
            context.setStrokeColor(primary.cgColor)
            context.setLineWidth(2)
            context.stroke(logoRect)
            logo.draw(in: logoRect)
        }
        
        // Company name with classic styling
        let companyFont = UIFont.systemFont(ofSize: 25, weight: .bold)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: primary
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 130, y: 40, width: page.width - 170, height: 35)
        companyText.draw(in: companyRect)
        
        // Classic tagline
        let taglineFont = UIFont.systemFont(ofSize: 13, weight: .medium)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: UIColor.gray
        ]
        let taglineText = NSAttributedString(string: "CLASSIC BUSINESS", attributes: taglineAttributes)
        let taglineRect = CGRect(x: 130, y: 75, width: page.width - 170, height: 20)
        taglineText.draw(in: taglineRect)
    }
    
    private func drawBusinessInvoiceSection(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor, accent: UIColor) {
        // Business invoice box
        let invoiceRect = CGRect(x: page.width - 190, y: 30, width: 140, height: 80)
        
        // Business background
        context.setFillColor(primary.withAlphaComponent(0.08).cgColor)
        context.fill(invoiceRect)
        
        // Business border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(2)
        context.stroke(invoiceRect)
        
        // Invoice title with business styling
        let titleFont = UIFont.systemFont(ofSize: 18, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: primary
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 180, y: 40, width: 120, height: 25)
        titleText.draw(in: titleRect)
        
        // Invoice number with business styling
        let numberFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: UIColor.black
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 180, y: 70, width: 120, height: 20)
        numberText.draw(in: numberRect)
        
        // Date with business styling
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateText = NSAttributedString(string: dateFormatter.string(from: invoice.issueDate), attributes: numberAttributes)
        let dateRect = CGRect(x: page.width - 180, y: 95, width: 120, height: 20)
        dateText.draw(in: dateRect)
    }
    
    private func drawClassicBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor, accent: UIColor) {
        // Classic bill to section
        let billToRect = CGRect(x: 40, y: 150, width: 320, height: 90)
        
        // Classic background
        context.setFillColor(primary.withAlphaComponent(0.04).cgColor)
        context.fill(billToRect)
        
        // Classic border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(1)
        context.stroke(billToRect)
        
        // Bill to title with classic styling
        let billToFont = UIFont.systemFont(ofSize: 14, weight: .bold)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "BILL TO:", attributes: billToAttributes)
        let billToTextRect = CGRect(x: 50, y: 160, width: 100, height: 25)
        billToText.draw(in: billToTextRect)
        
        // Customer details with classic styling
        let customerFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let customerAttributes: [NSAttributedString.Key: Any] = [
            .font: customerFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset: CGFloat = 190
        let customerNameText = NSAttributedString(string: customer.name, attributes: customerAttributes)
        let customerNameRect = CGRect(x: 50, y: yOffset, width: 300, height: 20)
        customerNameText.draw(in: customerNameRect)
        yOffset += 20
        
        if !customer.address.oneLine.isEmpty {
            let addressText = NSAttributedString(string: customer.address.oneLine, attributes: customerAttributes)
            let addressRect = CGRect(x: 50, y: yOffset, width: 300, height: 20)
            addressText.draw(in: addressRect)
            yOffset += 20
        }
        
        if !customer.email.isEmpty {
            let emailText = NSAttributedString(string: customer.email, attributes: customerAttributes)
            let emailRect = CGRect(x: 50, y: yOffset, width: 300, height: 20)
            emailText.draw(in: emailRect)
        }
    }
    
    private func drawBusinessTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, secondary: UIColor, accent: UIColor) {
        let startY: CGFloat = 280
        
        // Business table header
        let headerRect = CGRect(x: 40, y: startY, width: page.width - 80, height: 35)
        
        // Business header background
        context.setFillColor(primary.cgColor)
        context.fill(headerRect)
        
        // Header text
        let headerFont = UIFont.systemFont(ofSize: 12, weight: .bold)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white
        ]
        
        let headers = ["Description", "Quantity", "Unit Price", "Total"]
        let columnWidths: [CGFloat] = [300, 80, 100, 100]
        var xOffset: CGFloat = 50
        
        for (index, header) in headers.enumerated() {
            let headerText = NSAttributedString(string: header, attributes: headerAttributes)
            let headerTextRect = CGRect(x: xOffset, y: startY + 10, width: columnWidths[index], height: 20)
            headerText.draw(in: headerTextRect)
            xOffset += columnWidths[index]
        }
        
        // Business table rows
        let rowFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset = startY + 35
        for (index, item) in invoice.items.enumerated() {
            // Business alternating rows
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
    
    private func drawClassicTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, accent: UIColor) {
        let totalY: CGFloat = 450
        
        // Classic total box
        let totalRect = CGRect(x: page.width - 220, y: totalY, width: 160, height: 50)
        
        // Classic background
        context.setFillColor(primary.cgColor)
        context.fill(totalRect)
        
        // Classic border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(2)
        context.stroke(totalRect)
        
        // Total text with classic styling
        let totalFont = UIFont.systemFont(ofSize: 16, weight: .bold)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 210, y: totalY + 15, width: 140, height: 20)
        totalText.draw(in: totalTextRect)
    }
    
    private func drawBusinessFooter(context: CGContext, page: CGRect, company: Company, primary: UIColor) {
        let footerFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = NSAttributedString(string: "Thank you for your business. Classic service guaranteed.", attributes: footerAttributes)
        let footerRect = CGRect(x: 40, y: page.height - 50, width: page.width - 80, height: 20)
        footerText.draw(in: footerRect)
    }
}

// MARK: - Enterprise Bold Template

struct EnterpriseBoldTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent
        
        // Set white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)
        
        // Enterprise header
        drawEnterpriseHeader(context: context, page: page, company: company, logo: logo, primary: primary, secondary: secondary, accent: accent)
        
        // Bold invoice section
        drawBoldInvoiceSection(context: context, page: page, invoice: invoice, primary: primary, accent: accent)
        
        // Enterprise bill to section
        drawEnterpriseBillTo(context: context, page: page, customer: customer, primary: primary, accent: accent)
        
        // Bold table
        drawBoldTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary, accent: accent)
        
        // Enterprise total
        drawEnterpriseTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
        
        // Bold footer
        drawBoldFooter(context: context, page: page, company: company, primary: primary)
    }
    
    private func drawEnterpriseHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Enterprise background with bold pattern
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 150)
        
        // Enterprise background
        context.setFillColor(primary.withAlphaComponent(0.15).cgColor)
        context.fill(headerRect)
        
        // Bold geometric elements
        context.setFillColor(accent.withAlphaComponent(0.25).cgColor)
        for i in 0..<4 {
            let rect = CGRect(x: CGFloat(i * 150), y: 0, width: 75, height: 150)
            context.fill(rect)
        }
        
        // Logo with enterprise frame
        if let logo = logo {
            let logoRect = CGRect(x: 50, y: 50, width: 90, height: 90)
            // Enterprise frame
            context.setStrokeColor(accent.cgColor)
            context.setLineWidth(4)
            context.stroke(logoRect)
            logo.draw(in: logoRect)
        }
        
        // Company name with enterprise styling
        let companyFont = UIFont.systemFont(ofSize: 32, weight: .black)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: primary
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 160, y: 60, width: page.width - 200, height: 40)
        companyText.draw(in: companyRect)
        
        // Enterprise tagline
        let taglineFont = UIFont.systemFont(ofSize: 16, weight: .bold)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: accent
        ]
        let taglineText = NSAttributedString(string: "ENTERPRISE SOLUTIONS", attributes: taglineAttributes)
        let taglineRect = CGRect(x: 160, y: 100, width: page.width - 200, height: 25)
        taglineText.draw(in: taglineRect)
    }
    
    private func drawBoldInvoiceSection(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor, accent: UIColor) {
        // Bold invoice box
        let invoiceRect = CGRect(x: page.width - 250, y: 60, width: 200, height: 80)
        
        // Bold background
        context.setFillColor(accent.withAlphaComponent(0.2).cgColor)
        context.fill(invoiceRect)
        
        // Bold border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(4)
        context.stroke(invoiceRect)
        
        // Invoice title with bold styling
        let titleFont = UIFont.systemFont(ofSize: 24, weight: .black)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: accent
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 240, y: 70, width: 180, height: 30)
        titleText.draw(in: titleRect)
        
        // Invoice number with bold styling
        let numberFont = UIFont.systemFont(ofSize: 18, weight: .bold)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: primary
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 240, y: 105, width: 180, height: 25)
        numberText.draw(in: numberRect)
        
        // Date with bold styling
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let dateText = NSAttributedString(string: dateFormatter.string(from: invoice.issueDate), attributes: numberAttributes)
        let dateRect = CGRect(x: page.width - 240, y: 130, width: 180, height: 25)
        dateText.draw(in: dateRect)
    }
    
    private func drawEnterpriseBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor, accent: UIColor) {
        // Enterprise bill to section
        let billToRect = CGRect(x: 50, y: 180, width: 400, height: 120)
        
        // Enterprise background
        context.setFillColor(primary.withAlphaComponent(0.08).cgColor)
        context.fill(billToRect)
        
        // Enterprise border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(3)
        context.stroke(billToRect)
        
        // Bill to title with enterprise styling
        let billToFont = UIFont.systemFont(ofSize: 18, weight: .black)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "BILL TO:", attributes: billToAttributes)
        let billToTextRect = CGRect(x: 60, y: 190, width: 120, height: 30)
        billToText.draw(in: billToTextRect)
        
        // Customer details with enterprise styling
        let customerFont = UIFont.systemFont(ofSize: 16, weight: .bold)
        let customerAttributes: [NSAttributedString.Key: Any] = [
            .font: customerFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset: CGFloat = 230
        let customerNameText = NSAttributedString(string: customer.name, attributes: customerAttributes)
        let customerNameRect = CGRect(x: 60, y: yOffset, width: 380, height: 25)
        customerNameText.draw(in: customerNameRect)
        yOffset += 25
        
        if !customer.address.oneLine.isEmpty {
            let addressText = NSAttributedString(string: customer.address.oneLine, attributes: customerAttributes)
            let addressRect = CGRect(x: 60, y: yOffset, width: 380, height: 25)
            addressText.draw(in: addressRect)
            yOffset += 25
        }
        
        if !customer.email.isEmpty {
            let emailText = NSAttributedString(string: customer.email, attributes: customerAttributes)
            let emailRect = CGRect(x: 60, y: yOffset, width: 380, height: 25)
            emailText.draw(in: emailRect)
        }
    }
    
    private func drawBoldTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, secondary: UIColor, accent: UIColor) {
        let startY: CGFloat = 340
        
        // Bold table header
        let headerRect = CGRect(x: 50, y: startY, width: page.width - 100, height: 45)
        
        // Bold header background
        context.setFillColor(primary.cgColor)
        context.fill(headerRect)
        
        // Header text
        let headerFont = UIFont.systemFont(ofSize: 14, weight: .black)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white
        ]
        
        let headers = ["Description", "Quantity", "Unit Price", "Total"]
        let columnWidths: [CGFloat] = [350, 100, 120, 120]
        var xOffset: CGFloat = 60
        
        for (index, header) in headers.enumerated() {
            let headerText = NSAttributedString(string: header, attributes: headerAttributes)
            let headerTextRect = CGRect(x: xOffset, y: startY + 12, width: columnWidths[index], height: 25)
            headerText.draw(in: headerTextRect)
            xOffset += columnWidths[index]
        }
        
        // Bold table rows
        let rowFont = UIFont.systemFont(ofSize: 13, weight: .bold)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset = startY + 45
        for (index, item) in invoice.items.enumerated() {
            // Bold alternating rows
            if index % 2 == 0 {
                let rowRect = CGRect(x: 50, y: yOffset, width: page.width - 100, height: 40)
                context.setFillColor(accent.withAlphaComponent(0.1).cgColor)
                context.fill(rowRect)
            }
            
            // Row content
            xOffset = 60
            
            let itemText = NSAttributedString(string: item.description, attributes: rowAttributes)
            let itemRect = CGRect(x: xOffset, y: yOffset + 12, width: columnWidths[0], height: 25)
            itemText.draw(in: itemRect)
            xOffset += columnWidths[0]
            
            let qtyText = NSAttributedString(string: "\(item.quantity)", attributes: rowAttributes)
            let qtyRect = CGRect(x: xOffset, y: yOffset + 12, width: columnWidths[1], height: 25)
            qtyText.draw(in: qtyRect)
            xOffset += columnWidths[1]
            
            let rateText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.rate as NSDecimalNumber)))", attributes: rowAttributes)
            let rateRect = CGRect(x: xOffset, y: yOffset + 12, width: columnWidths[2], height: 25)
            rateText.draw(in: rateRect)
            xOffset += columnWidths[2]
            
            let amountText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.total as NSDecimalNumber)))", attributes: rowAttributes)
            let amountRect = CGRect(x: xOffset, y: yOffset + 12, width: columnWidths[3], height: 25)
            amountText.draw(in: amountRect)
            
            yOffset += 40
        }
    }
    
    private func drawEnterpriseTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, accent: UIColor) {
        let totalY: CGFloat = 520
        
        // Enterprise total box
        let totalRect = CGRect(x: page.width - 280, y: totalY, width: 200, height: 70)
        
        // Enterprise background
        context.setFillColor(accent.cgColor)
        context.fill(totalRect)
        
        // Enterprise border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(4)
        context.stroke(totalRect)
        
        // Total text with enterprise styling
        let totalFont = UIFont.systemFont(ofSize: 20, weight: .black)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 270, y: totalY + 20, width: 180, height: 25)
        totalText.draw(in: totalTextRect)
    }
    
    private func drawBoldFooter(context: CGContext, page: CGRect, company: Company, primary: UIColor) {
        let footerFont = UIFont.systemFont(ofSize: 12, weight: .bold)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = NSAttributedString(string: "Enterprise-grade service. Bold results guaranteed.", attributes: footerAttributes)
        let footerRect = CGRect(x: 50, y: page.height - 50, width: page.width - 100, height: 25)
        footerText.draw(in: footerRect)
    }
}

// MARK: - Consulting Elegant Template

struct ConsultingElegantTemplate: SimpleTemplateRenderer {
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
        
        // Consulting invoice section
        drawConsultingInvoiceSection(context: context, page: page, invoice: invoice, primary: primary, accent: accent)
        
        // Elegant bill to section
        drawElegantBillTo(context: context, page: page, customer: customer, primary: primary, accent: accent)
        
        // Consulting table
        drawConsultingTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary, accent: accent)
        
        // Elegant total
        drawElegantTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
        
        // Consulting footer
        drawConsultingFooter(context: context, page: page, company: company, primary: primary)
    }
    
    private func drawElegantHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Elegant background with sophisticated pattern
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 130)
        
        // Elegant background
        context.setFillColor(primary.withAlphaComponent(0.05).cgColor)
        context.fill(headerRect)
        
        // Elegant decorative lines
        context.setStrokeColor(accent.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(1)
        for i in 0..<10 {
            let y = CGFloat(i * 13)
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: page.width, y: y))
        }
        context.strokePath()
        
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
        let companyRect = CGRect(x: 130, y: 45, width: page.width - 170, height: 35)
        companyText.draw(in: companyRect)
        
        // Elegant tagline
        let taglineFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: accent
        ]
        let taglineText = NSAttributedString(string: "ELEGANT CONSULTING", attributes: taglineAttributes)
        let taglineRect = CGRect(x: 130, y: 80, width: page.width - 170, height: 20)
        taglineText.draw(in: taglineRect)
    }
    
    private func drawConsultingInvoiceSection(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor, accent: UIColor) {
        // Consulting invoice box
        let invoiceRect = CGRect(x: page.width - 200, y: 40, width: 150, height: 80)
        
        // Consulting background
        context.setFillColor(accent.withAlphaComponent(0.08).cgColor)
        context.fill(invoiceRect)
        
        // Consulting border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(2)
        context.stroke(invoiceRect)
        
        // Invoice title with consulting styling
        let titleFont = UIFont.systemFont(ofSize: 20, weight: .light)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: accent
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 190, y: 50, width: 130, height: 25)
        titleText.draw(in: titleRect)
        
        // Invoice number with consulting styling
        let numberFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: primary
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 190, y: 80, width: 130, height: 20)
        numberText.draw(in: numberRect)
        
        // Date with consulting styling
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
        context.setFillColor(primary.withAlphaComponent(0.03).cgColor)
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
    
    private func drawConsultingTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, secondary: UIColor, accent: UIColor) {
        let startY: CGFloat = 300
        
        // Consulting table header
        let headerRect = CGRect(x: 40, y: startY, width: page.width - 80, height: 35)
        
        // Consulting header background
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
        
        // Consulting table rows
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
        let totalY: CGFloat = 470
        
        // Elegant total box
        let totalRect = CGRect(x: page.width - 240, y: totalY, width: 180, height: 50)
        
        // Elegant background
        context.setFillColor(accent.cgColor)
        context.fill(totalRect)
        
        // Elegant border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(2)
        context.stroke(totalRect)
        
        // Total text with elegant styling
        let totalFont = UIFont.systemFont(ofSize: 18, weight: .light)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 230, y: totalY + 15, width: 160, height: 20)
        totalText.draw(in: totalTextRect)
    }
    
    private func drawConsultingFooter(context: CGContext, page: CGRect, company: Company, primary: UIColor) {
        let footerFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = NSAttributedString(string: "Elegant consulting services. Sophisticated solutions.", attributes: footerAttributes)
        let footerRect = CGRect(x: 40, y: page.height - 50, width: page.width - 80, height: 20)
        footerText.draw(in: footerRect)
    }
}
