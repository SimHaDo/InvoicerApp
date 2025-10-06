import Foundation
import UIKit

// MARK: - Real Estate Warm Template

struct RealEstateWarmTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent
        
        // Set white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)
        
        // Warm header
        drawWarmHeader(context: context, page: page, company: company, logo: logo, primary: primary, secondary: secondary, accent: accent)
        
        // Real estate invoice section
        drawRealEstateInvoiceSection(context: context, page: page, invoice: invoice, primary: primary, accent: accent)
        
        // Warm bill to section
        drawWarmBillTo(context: context, page: page, customer: customer, primary: primary, accent: accent)
        
        // Real estate table
        drawRealEstateTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary, accent: accent)
        
        // Warm total
        drawWarmTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
        
        // Real estate footer
        drawRealEstateFooter(context: context, page: page, company: company, primary: primary)
    }
    
    private func drawWarmHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Warm background with cozy pattern
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 125)
        
        // Warm background
        context.setFillColor(primary.withAlphaComponent(0.12).cgColor)
        context.fill(headerRect)
        
        // Cozy decorative elements
        context.setFillColor(accent.withAlphaComponent(0.2).cgColor)
        for i in 0..<6 {
            let circle = CGRect(x: CGFloat(i * 100 + 20), y: 15, width: 12, height: 12)
            context.fillEllipse(in: circle)
        }
        
        // Logo with warm frame
        if let logo = logo {
            let logoRect = CGRect(x: 40, y: 35, width: 70, height: 70)
            // Warm frame
            context.setStrokeColor(accent.cgColor)
            context.setLineWidth(3)
            context.stroke(logoRect)
            logo.draw(in: logoRect)
        }
        
        // Company name with warm styling
        let companyFont = UIFont.systemFont(ofSize: 29, weight: .semibold)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: primary
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 130, y: 45, width: page.width - 160, height: 35)
        companyText.draw(in: companyRect)
        
        // Warm tagline
        let taglineFont = UIFont.systemFont(ofSize: 15, weight: .medium)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: accent
        ]
        let taglineText = NSAttributedString(string: "REAL ESTATE SERVICES", attributes: taglineAttributes)
        let taglineRect = CGRect(x: 130, y: 80, width: page.width - 160, height: 25)
        taglineText.draw(in: taglineRect)
    }
    
    private func drawRealEstateInvoiceSection(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor, accent: UIColor) {
        // Real estate invoice box
        let invoiceRect = CGRect(x: page.width - 210, y: 40, width: 160, height: 75)
        
        // Real estate background
        context.setFillColor(accent.withAlphaComponent(0.15).cgColor)
        context.fill(invoiceRect)
        
        // Real estate border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(3)
        context.stroke(invoiceRect)
        
        // Invoice title with real estate styling
        let titleFont = UIFont.systemFont(ofSize: 21, weight: .semibold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: accent
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 200, y: 50, width: 140, height: 25)
        titleText.draw(in: titleRect)
        
        // Invoice number with real estate styling
        let numberFont = UIFont.systemFont(ofSize: 17, weight: .medium)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: primary
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 200, y: 80, width: 140, height: 20)
        numberText.draw(in: numberRect)
        
        // Date with real estate styling
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        let dateText = NSAttributedString(string: dateFormatter.string(from: invoice.issueDate), attributes: numberAttributes)
        let dateRect = CGRect(x: page.width - 200, y: 105, width: 140, height: 20)
        dateText.draw(in: dateRect)
    }
    
    private func drawWarmBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor, accent: UIColor) {
        // Warm bill to section
        let billToRect = CGRect(x: 40, y: 160, width: 370, height: 105)
        
        // Warm background
        context.setFillColor(primary.withAlphaComponent(0.07).cgColor)
        context.fill(billToRect)
        
        // Warm border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(2)
        context.stroke(billToRect)
        
        // Bill to title with warm styling
        let billToFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "BILL TO:", attributes: billToAttributes)
        let billToTextRect = CGRect(x: 50, y: 170, width: 100, height: 30)
        billToText.draw(in: billToTextRect)
        
        // Customer details with warm styling
        let customerFont = UIFont.systemFont(ofSize: 15, weight: .medium)
        let customerAttributes: [NSAttributedString.Key: Any] = [
            .font: customerFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset: CGFloat = 205
        let customerNameText = NSAttributedString(string: customer.name, attributes: customerAttributes)
        let customerNameRect = CGRect(x: 50, y: yOffset, width: 350, height: 25)
        customerNameText.draw(in: customerNameRect)
        yOffset += 25
        
        if !customer.address.oneLine.isEmpty {
            let addressText = NSAttributedString(string: customer.address.oneLine, attributes: customerAttributes)
            let addressRect = CGRect(x: 50, y: yOffset, width: 350, height: 25)
            addressText.draw(in: addressRect)
            yOffset += 25
        }
        
        if !customer.email.isEmpty {
            let emailText = NSAttributedString(string: customer.email, attributes: customerAttributes)
            let emailRect = CGRect(x: 50, y: yOffset, width: 350, height: 25)
            emailText.draw(in: emailRect)
        }
    }
    
    private func drawRealEstateTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, secondary: UIColor, accent: UIColor) {
        let startY: CGFloat = 295
        
        // Real estate table header
        let headerRect = CGRect(x: 40, y: startY, width: page.width - 80, height: 38)
        
        // Real estate header background
        context.setFillColor(primary.cgColor)
        context.fill(headerRect)
        
        // Header text
        let headerFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
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
        
        // Real estate table rows
        let rowFont = UIFont.systemFont(ofSize: 13, weight: .medium)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset = startY + 38
        for (index, item) in invoice.items.enumerated() {
            // Warm alternating rows
            if index % 2 == 0 {
                let rowRect = CGRect(x: 40, y: yOffset, width: page.width - 80, height: 32)
                context.setFillColor(accent.withAlphaComponent(0.09).cgColor)
                context.fill(rowRect)
            }
            
            // Row content
            xOffset = 50
            
            let itemText = NSAttributedString(string: item.description, attributes: rowAttributes)
            let itemRect = CGRect(x: xOffset, y: yOffset + 9, width: columnWidths[0], height: 25)
            itemText.draw(in: itemRect)
            xOffset += columnWidths[0]
            
            let qtyText = NSAttributedString(string: "\(item.quantity)", attributes: rowAttributes)
            let qtyRect = CGRect(x: xOffset, y: yOffset + 9, width: columnWidths[1], height: 25)
            qtyText.draw(in: qtyRect)
            xOffset += columnWidths[1]
            
            let rateText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.rate as NSDecimalNumber)))", attributes: rowAttributes)
            let rateRect = CGRect(x: xOffset, y: yOffset + 9, width: columnWidths[2], height: 25)
            rateText.draw(in: rateRect)
            xOffset += columnWidths[2]
            
            let amountText = NSAttributedString(string: "\(currency)\(String(format: "%.2f", Double(truncating: item.total as NSDecimalNumber)))", attributes: rowAttributes)
            let amountRect = CGRect(x: xOffset, y: yOffset + 9, width: columnWidths[3], height: 25)
            amountText.draw(in: amountRect)
            
            yOffset += 32
        }
    }
    
    private func drawWarmTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, accent: UIColor) {
        let totalY: CGFloat = 485
        
        // Warm total box
        let totalRect = CGRect(x: page.width - 240, y: totalY, width: 180, height: 55)
        
        // Warm background
        context.setFillColor(accent.cgColor)
        context.fill(totalRect)
        
        // Warm border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(3)
        context.stroke(totalRect)
        
        // Total text with warm styling
        let totalFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 230, y: totalY + 17, width: 160, height: 20)
        totalText.draw(in: totalTextRect)
    }
    
    private func drawRealEstateFooter(context: CGContext, page: CGRect, company: Company, primary: UIColor) {
        let footerFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = NSAttributedString(string: "Warm real estate services. Your home is our priority.", attributes: footerAttributes)
        let footerRect = CGRect(x: 40, y: page.height - 50, width: page.width - 80, height: 20)
        footerText.draw(in: footerRect)
    }
}

// MARK: - Insurance Trust Template

struct InsuranceTrustTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent
        
        // Set white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)
        
        // Trust header
        drawTrustHeader(context: context, page: page, company: company, logo: logo, primary: primary, secondary: secondary, accent: accent)
        
        // Insurance invoice section
        drawInsuranceInvoiceSection(context: context, page: page, invoice: invoice, primary: primary, accent: accent)
        
        // Trust bill to section
        drawTrustBillTo(context: context, page: page, customer: customer, primary: primary, accent: accent)
        
        // Insurance table
        drawInsuranceTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary, accent: accent)
        
        // Trust total
        drawTrustTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
        
        // Insurance footer
        drawInsuranceFooter(context: context, page: page, company: company, primary: primary)
    }
    
    private func drawTrustHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Trust background with secure pattern
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 135)
        
        // Trust background
        context.setFillColor(primary.withAlphaComponent(0.09).cgColor)
        context.fill(headerRect)
        
        // Secure shield pattern
        context.setFillColor(accent.withAlphaComponent(0.18).cgColor)
        for i in 0..<5 {
            let shield = CGRect(x: CGFloat(i * 120 + 30), y: 20, width: 25, height: 25)
            context.fillEllipse(in: shield)
        }
        
        // Logo with trust frame
        if let logo = logo {
            let logoRect = CGRect(x: 45, y: 40, width: 75, height: 75)
            // Trust frame
            context.setStrokeColor(primary.cgColor)
            context.setLineWidth(3)
            context.stroke(logoRect)
            logo.draw(in: logoRect)
        }
        
        // Company name with trust styling
        let companyFont = UIFont.systemFont(ofSize: 31, weight: .bold)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: primary
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 140, y: 50, width: page.width - 170, height: 40)
        companyText.draw(in: companyRect)
        
        // Trust tagline
        let taglineFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: accent
        ]
        let taglineText = NSAttributedString(string: "INSURANCE SERVICES", attributes: taglineAttributes)
        let taglineRect = CGRect(x: 140, y: 90, width: page.width - 170, height: 25)
        taglineText.draw(in: taglineRect)
    }
    
    private func drawInsuranceInvoiceSection(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor, accent: UIColor) {
        // Insurance invoice box
        let invoiceRect = CGRect(x: page.width - 220, y: 50, width: 170, height: 75)
        
        // Insurance background
        context.setFillColor(accent.withAlphaComponent(0.12).cgColor)
        context.fill(invoiceRect)
        
        // Insurance border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(3)
        context.stroke(invoiceRect)
        
        // Invoice title with insurance styling
        let titleFont = UIFont.systemFont(ofSize: 22, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: accent
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 210, y: 60, width: 150, height: 30)
        titleText.draw(in: titleRect)
        
        // Invoice number with insurance styling
        let numberFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: primary
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 210, y: 95, width: 150, height: 25)
        numberText.draw(in: numberRect)
        
        // Date with insurance styling
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM dd, yyyy"
        let dateText = NSAttributedString(string: dateFormatter.string(from: invoice.issueDate), attributes: numberAttributes)
        let dateRect = CGRect(x: page.width - 210, y: 120, width: 150, height: 25)
        dateText.draw(in: dateRect)
    }
    
    private func drawTrustBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor, accent: UIColor) {
        // Trust bill to section
        let billToRect = CGRect(x: 45, y: 175, width: 380, height: 110)
        
        // Trust background
        context.setFillColor(primary.withAlphaComponent(0.06).cgColor)
        context.fill(billToRect)
        
        // Trust border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(2)
        context.stroke(billToRect)
        
        // Bill to title with trust styling
        let billToFont = UIFont.systemFont(ofSize: 18, weight: .bold)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "BILL TO:", attributes: billToAttributes)
        let billToTextRect = CGRect(x: 55, y: 185, width: 100, height: 30)
        billToText.draw(in: billToTextRect)
        
        // Customer details with trust styling
        let customerFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        let customerAttributes: [NSAttributedString.Key: Any] = [
            .font: customerFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset: CGFloat = 220
        let customerNameText = NSAttributedString(string: customer.name, attributes: customerAttributes)
        let customerNameRect = CGRect(x: 55, y: yOffset, width: 360, height: 25)
        customerNameText.draw(in: customerNameRect)
        yOffset += 25
        
        if !customer.address.oneLine.isEmpty {
            let addressText = NSAttributedString(string: customer.address.oneLine, attributes: customerAttributes)
            let addressRect = CGRect(x: 55, y: yOffset, width: 360, height: 25)
            addressText.draw(in: addressRect)
            yOffset += 25
        }
        
        if !customer.email.isEmpty {
            let emailText = NSAttributedString(string: customer.email, attributes: customerAttributes)
            let emailRect = CGRect(x: 55, y: yOffset, width: 360, height: 25)
            emailText.draw(in: emailRect)
        }
    }
    
    private func drawInsuranceTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, secondary: UIColor, accent: UIColor) {
        let startY: CGFloat = 315
        
        // Insurance table header
        let headerRect = CGRect(x: 45, y: startY, width: page.width - 90, height: 40)
        
        // Insurance header background
        context.setFillColor(primary.cgColor)
        context.fill(headerRect)
        
        // Header text
        let headerFont = UIFont.systemFont(ofSize: 15, weight: .bold)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white
        ]
        
        let headers = ["Description", "Quantity", "Unit Price", "Total"]
        let columnWidths: [CGFloat] = [350, 90, 110, 110]
        var xOffset: CGFloat = 55
        
        for (index, header) in headers.enumerated() {
            let headerText = NSAttributedString(string: header, attributes: headerAttributes)
            let headerTextRect = CGRect(x: xOffset, y: startY + 12, width: columnWidths[index], height: 25)
            headerText.draw(in: headerTextRect)
            xOffset += columnWidths[index]
        }
        
        // Insurance table rows
        let rowFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset = startY + 40
        for (index, item) in invoice.items.enumerated() {
            // Trust alternating rows
            if index % 2 == 0 {
                let rowRect = CGRect(x: 45, y: yOffset, width: page.width - 90, height: 35)
                context.setFillColor(accent.withAlphaComponent(0.08).cgColor)
                context.fill(rowRect)
            }
            
            // Row content
            xOffset = 55
            
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
    
    private func drawTrustTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, accent: UIColor) {
        let totalY: CGFloat = 500
        
        // Trust total box
        let totalRect = CGRect(x: page.width - 250, y: totalY, width: 190, height: 60)
        
        // Trust background
        context.setFillColor(accent.cgColor)
        context.fill(totalRect)
        
        // Trust border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(3)
        context.stroke(totalRect)
        
        // Total text with trust styling
        let totalFont = UIFont.systemFont(ofSize: 19, weight: .bold)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 240, y: totalY + 18, width: 170, height: 25)
        totalText.draw(in: totalTextRect)
    }
    
    private func drawInsuranceFooter(context: CGContext, page: CGRect, company: Company, primary: UIColor) {
        let footerFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = NSAttributedString(string: "Trusted insurance services. Your protection is our commitment.", attributes: footerAttributes)
        let footerRect = CGRect(x: 45, y: page.height - 50, width: page.width - 90, height: 20)
        footerText.draw(in: footerRect)
    }
}

// MARK: - Banking Secure Template

struct BankingSecureTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent
        
        // Set white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)
        
        // Secure header
        drawSecureHeader(context: context, page: page, company: company, logo: logo, primary: primary, secondary: secondary, accent: accent)
        
        // Banking invoice section
        drawBankingInvoiceSection(context: context, page: page, invoice: invoice, primary: primary, accent: accent)
        
        // Secure bill to section
        drawSecureBillTo(context: context, page: page, customer: customer, primary: primary, accent: accent)
        
        // Banking table
        drawBankingTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary, accent: accent)
        
        // Secure total
        drawSecureTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
        
        // Banking footer
        drawBankingFooter(context: context, page: page, company: company, primary: primary)
    }
    
    private func drawSecureHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Secure background with banking pattern
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 140)
        
        // Secure background
        context.setFillColor(primary.withAlphaComponent(0.08).cgColor)
        context.fill(headerRect)
        
        // Banking security pattern
        context.setStrokeColor(accent.withAlphaComponent(0.25).cgColor)
        context.setLineWidth(1)
        for i in 0..<15 {
            let x = CGFloat(i * 40)
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: 140))
        }
        for i in 0..<10 {
            let y = CGFloat(i * 14)
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: page.width, y: y))
        }
        context.strokePath()
        
        // Logo with secure frame
        if let logo = logo {
            let logoRect = CGRect(x: 50, y: 45, width: 80, height: 80)
            // Secure frame
            context.setStrokeColor(primary.cgColor)
            context.setLineWidth(4)
            context.stroke(logoRect)
            logo.draw(in: logoRect)
        }
        
        // Company name with secure styling
        let companyFont = UIFont.systemFont(ofSize: 33, weight: .bold)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: primary
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 150, y: 55, width: page.width - 180, height: 40)
        companyText.draw(in: companyRect)
        
        // Secure tagline
        let taglineFont = UIFont.systemFont(ofSize: 17, weight: .medium)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: accent
        ]
        let taglineText = NSAttributedString(string: "BANKING SERVICES", attributes: taglineAttributes)
        let taglineRect = CGRect(x: 150, y: 95, width: page.width - 180, height: 25)
        taglineText.draw(in: taglineRect)
    }
    
    private func drawBankingInvoiceSection(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor, accent: UIColor) {
        // Banking invoice box
        let invoiceRect = CGRect(x: page.width - 230, y: 55, width: 180, height: 80)
        
        // Banking background
        context.setFillColor(accent.withAlphaComponent(0.1).cgColor)
        context.fill(invoiceRect)
        
        // Banking border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(4)
        context.stroke(invoiceRect)
        
        // Invoice title with banking styling
        let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: accent
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 220, y: 65, width: 160, height: 30)
        titleText.draw(in: titleRect)
        
        // Invoice number with banking styling
        let numberFont = UIFont.systemFont(ofSize: 19, weight: .semibold)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: primary
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 220, y: 100, width: 160, height: 25)
        numberText.draw(in: numberRect)
        
        // Date with banking styling
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM dd, yyyy"
        let dateText = NSAttributedString(string: dateFormatter.string(from: invoice.issueDate), attributes: numberAttributes)
        let dateRect = CGRect(x: page.width - 220, y: 125, width: 160, height: 25)
        dateText.draw(in: dateRect)
    }
    
    private func drawSecureBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor, accent: UIColor) {
        // Secure bill to section
        let billToRect = CGRect(x: 50, y: 180, width: 400, height: 115)
        
        // Secure background
        context.setFillColor(primary.withAlphaComponent(0.05).cgColor)
        context.fill(billToRect)
        
        // Secure border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(3)
        context.stroke(billToRect)
        
        // Bill to title with secure styling
        let billToFont = UIFont.systemFont(ofSize: 19, weight: .bold)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "BILL TO:", attributes: billToAttributes)
        let billToTextRect = CGRect(x: 60, y: 190, width: 100, height: 30)
        billToText.draw(in: billToTextRect)
        
        // Customer details with secure styling
        let customerFont = UIFont.systemFont(ofSize: 17, weight: .medium)
        let customerAttributes: [NSAttributedString.Key: Any] = [
            .font: customerFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset: CGFloat = 225
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
    
    private func drawBankingTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, secondary: UIColor, accent: UIColor) {
        let startY: CGFloat = 325
        
        // Banking table header
        let headerRect = CGRect(x: 50, y: startY, width: page.width - 100, height: 42)
        
        // Banking header background
        context.setFillColor(primary.cgColor)
        context.fill(headerRect)
        
        // Header text
        let headerFont = UIFont.systemFont(ofSize: 16, weight: .bold)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white
        ]
        
        let headers = ["Description", "Quantity", "Unit Price", "Total"]
        let columnWidths: [CGFloat] = [360, 90, 110, 110]
        var xOffset: CGFloat = 60
        
        for (index, header) in headers.enumerated() {
            let headerText = NSAttributedString(string: header, attributes: headerAttributes)
            let headerTextRect = CGRect(x: xOffset, y: startY + 12, width: columnWidths[index], height: 25)
            headerText.draw(in: headerTextRect)
            xOffset += columnWidths[index]
        }
        
        // Banking table rows
        let rowFont = UIFont.systemFont(ofSize: 15, weight: .medium)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset = startY + 42
        for (index, item) in invoice.items.enumerated() {
            // Secure alternating rows
            if index % 2 == 0 {
                let rowRect = CGRect(x: 50, y: yOffset, width: page.width - 100, height: 37)
                context.setFillColor(accent.withAlphaComponent(0.07).cgColor)
                context.fill(rowRect)
            }
            
            // Row content
            xOffset = 60
            
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
            
            yOffset += 37
        }
    }
    
    private func drawSecureTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, accent: UIColor) {
        let totalY: CGFloat = 520
        
        // Secure total box
        let totalRect = CGRect(x: page.width - 260, y: totalY, width: 200, height: 65)
        
        // Secure background
        context.setFillColor(accent.cgColor)
        context.fill(totalRect)
        
        // Secure border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(4)
        context.stroke(totalRect)
        
        // Total text with secure styling
        let totalFont = UIFont.systemFont(ofSize: 20, weight: .bold)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 250, y: totalY + 20, width: 180, height: 25)
        totalText.draw(in: totalTextRect)
    }
    
    private func drawBankingFooter(context: CGContext, page: CGRect, company: Company, primary: UIColor) {
        let footerFont = UIFont.systemFont(ofSize: 13, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = NSAttributedString(string: "Secure banking services. Your financial security is our priority.", attributes: footerAttributes)
        let footerRect = CGRect(x: 50, y: page.height - 50, width: page.width - 100, height: 20)
        footerText.draw(in: footerRect)
    }
}
