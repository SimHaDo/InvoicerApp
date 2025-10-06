import Foundation
import UIKit

// MARK: - Accounting Detailed Template

struct AccountingDetailedTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent
        
        // Set white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)
        
        // Detailed header
        drawDetailedHeader(context: context, page: page, company: company, logo: logo, primary: primary, secondary: secondary, accent: accent)
        
        // Accounting invoice section
        drawAccountingInvoiceSection(context: context, page: page, invoice: invoice, primary: primary, accent: accent)
        
        // Detailed bill to section
        drawDetailedBillTo(context: context, page: page, customer: customer, primary: primary, accent: accent)
        
        // Accounting table
        drawAccountingTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary, accent: accent)
        
        // Detailed total
        drawDetailedTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
        
        // Accounting footer
        drawAccountingFooter(context: context, page: page, company: company, primary: primary)
    }
    
    private func drawDetailedHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Detailed background with accounting pattern
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 130)
        
        // Detailed background
        context.setFillColor(primary.withAlphaComponent(0.07).cgColor)
        context.fill(headerRect)
        
        // Accounting grid pattern
        context.setStrokeColor(accent.withAlphaComponent(0.2).cgColor)
        context.setLineWidth(0.5)
        for i in 0..<25 {
            let x = CGFloat(i * 25)
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: 130))
        }
        for i in 0..<10 {
            let y = CGFloat(i * 13)
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: page.width, y: y))
        }
        context.strokePath()
        
        // Logo with detailed frame
        if let logo = logo {
            let logoRect = CGRect(x: 35, y: 30, width: 75, height: 75)
            // Detailed frame
            context.setStrokeColor(primary.cgColor)
            context.setLineWidth(2)
            context.stroke(logoRect)
            logo.draw(in: logoRect)
        }
        
        // Company name with detailed styling
        let companyFont = UIFont.systemFont(ofSize: 28, weight: .semibold)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: primary
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 125, y: 40, width: page.width - 155, height: 35)
        companyText.draw(in: companyRect)
        
        // Detailed tagline
        let taglineFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: accent
        ]
        let taglineText = NSAttributedString(string: "ACCOUNTING SERVICES", attributes: taglineAttributes)
        let taglineRect = CGRect(x: 125, y: 75, width: page.width - 155, height: 20)
        taglineText.draw(in: taglineRect)
    }
    
    private func drawAccountingInvoiceSection(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor, accent: UIColor) {
        // Accounting invoice box
        let invoiceRect = CGRect(x: page.width - 200, y: 35, width: 155, height: 80)
        
        // Accounting background
        context.setFillColor(accent.withAlphaComponent(0.1).cgColor)
        context.fill(invoiceRect)
        
        // Accounting border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(2)
        context.stroke(invoiceRect)
        
        // Invoice title with accounting styling
        let titleFont = UIFont.systemFont(ofSize: 19, weight: .semibold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: accent
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 190, y: 45, width: 135, height: 25)
        titleText.draw(in: titleRect)
        
        // Invoice number with accounting styling
        let numberFont = UIFont.systemFont(ofSize: 15, weight: .medium)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: primary
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 190, y: 75, width: 135, height: 20)
        numberText.draw(in: numberRect)
        
        // Date with accounting styling
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateText = NSAttributedString(string: dateFormatter.string(from: invoice.issueDate), attributes: numberAttributes)
        let dateRect = CGRect(x: page.width - 190, y: 100, width: 135, height: 20)
        dateText.draw(in: dateRect)
    }
    
    private func drawDetailedBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor, accent: UIColor) {
        // Detailed bill to section
        let billToRect = CGRect(x: 35, y: 155, width: 360, height: 100)
        
        // Detailed background
        context.setFillColor(primary.withAlphaComponent(0.05).cgColor)
        context.fill(billToRect)
        
        // Detailed border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(1)
        context.stroke(billToRect)
        
        // Bill to title with detailed styling
        let billToFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "BILL TO:", attributes: billToAttributes)
        let billToTextRect = CGRect(x: 45, y: 165, width: 100, height: 25)
        billToText.draw(in: billToTextRect)
        
        // Customer details with detailed styling
        let customerFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        let customerAttributes: [NSAttributedString.Key: Any] = [
            .font: customerFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset: CGFloat = 195
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
    
    private func drawAccountingTable(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, secondary: UIColor, accent: UIColor) {
        let startY: CGFloat = 285
        
        // Accounting table header
        let headerRect = CGRect(x: 35, y: startY, width: page.width - 70, height: 35)
        
        // Accounting header background
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
        
        // Accounting table rows
        let rowFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset = startY + 35
        for (index, item) in invoice.items.enumerated() {
            // Detailed alternating rows
            if index % 2 == 0 {
                let rowRect = CGRect(x: 35, y: yOffset, width: page.width - 70, height: 30)
                context.setFillColor(accent.withAlphaComponent(0.06).cgColor)
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
    
    private func drawDetailedTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, accent: UIColor) {
        let totalY: CGFloat = 450
        
        // Detailed total box
        let totalRect = CGRect(x: page.width - 220, y: totalY, width: 170, height: 50)
        
        // Detailed background
        context.setFillColor(accent.cgColor)
        context.fill(totalRect)
        
        // Detailed border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(2)
        context.stroke(totalRect)
        
        // Total text with detailed styling
        let totalFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 210, y: totalY + 15, width: 150, height: 20)
        totalText.draw(in: totalTextRect)
    }
    
    private func drawAccountingFooter(context: CGContext, page: CGRect, company: Company, primary: UIColor) {
        let footerFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = NSAttributedString(string: "Detailed accounting services. Precision in every calculation.", attributes: footerAttributes)
        let footerRect = CGRect(x: 35, y: page.height - 50, width: page.width - 70, height: 20)
        footerText.draw(in: footerRect)
    }
}

// MARK: - Consulting Professional Template

struct ConsultingProfessionalTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent
        
        // Set white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(page)
        
        // Professional header
        drawProfessionalHeader(context: context, page: page, company: company, logo: logo, primary: primary, secondary: secondary, accent: accent)
        
        // Consulting invoice section
        drawConsultingInvoiceSection(context: context, page: page, invoice: invoice, primary: primary, accent: accent)
        
        // Professional bill to section
        drawProfessionalBillTo(context: context, page: page, customer: customer, primary: primary, accent: accent)
        
        // Consulting table
        drawConsultingTable(context: context, page: page, invoice: invoice, currency: currency, primary: primary, secondary: secondary, accent: accent)
        
        // Professional total
        drawProfessionalTotal(context: context, page: page, invoice: invoice, currency: currency, primary: primary, accent: accent)
        
        // Consulting footer
        drawConsultingFooter(context: context, page: page, company: company, primary: primary)
    }
    
    private func drawProfessionalHeader(context: CGContext, page: CGRect, company: Company, logo: UIImage?, primary: UIColor, secondary: UIColor, accent: UIColor) {
        // Professional background with consulting pattern
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 125)
        
        // Professional background
        context.setFillColor(primary.withAlphaComponent(0.08).cgColor)
        context.fill(headerRect)
        
        // Consulting professional lines
        context.setStrokeColor(accent.withAlphaComponent(0.25).cgColor)
        context.setLineWidth(1)
        for i in 0..<12 {
            let y = CGFloat(i * 10)
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: page.width, y: y))
        }
        context.strokePath()
        
        // Logo with professional frame
        if let logo = logo {
            let logoRect = CGRect(x: 40, y: 35, width: 70, height: 70)
            // Professional frame
            context.setStrokeColor(primary.cgColor)
            context.setLineWidth(2)
            context.stroke(logoRect)
            logo.draw(in: logoRect)
        }
        
        // Company name with professional styling
        let companyFont = UIFont.systemFont(ofSize: 27, weight: .semibold)
        let companyAttributes: [NSAttributedString.Key: Any] = [
            .font: companyFont,
            .foregroundColor: primary
        ]
        let companyText = NSAttributedString(string: company.name, attributes: companyAttributes)
        let companyRect = CGRect(x: 125, y: 45, width: page.width - 155, height: 35)
        companyText.draw(in: companyRect)
        
        // Professional tagline
        let taglineFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: accent
        ]
        let taglineText = NSAttributedString(string: "PROFESSIONAL CONSULTING", attributes: taglineAttributes)
        let taglineRect = CGRect(x: 125, y: 80, width: page.width - 155, height: 20)
        taglineText.draw(in: taglineRect)
    }
    
    private func drawConsultingInvoiceSection(context: CGContext, page: CGRect, invoice: Invoice, primary: UIColor, accent: UIColor) {
        // Consulting invoice box
        let invoiceRect = CGRect(x: page.width - 195, y: 40, width: 145, height: 75)
        
        // Consulting background
        context.setFillColor(accent.withAlphaComponent(0.1).cgColor)
        context.fill(invoiceRect)
        
        // Consulting border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(2)
        context.stroke(invoiceRect)
        
        // Invoice title with consulting styling
        let titleFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: accent
        ]
        let titleText = NSAttributedString(string: "INVOICE", attributes: titleAttributes)
        let titleRect = CGRect(x: page.width - 185, y: 50, width: 125, height: 25)
        titleText.draw(in: titleRect)
        
        // Invoice number with consulting styling
        let numberFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: primary
        ]
        let numberText = NSAttributedString(string: "#\(invoice.number)", attributes: numberAttributes)
        let numberRect = CGRect(x: page.width - 185, y: 80, width: 125, height: 20)
        numberText.draw(in: numberRect)
        
        // Date with consulting styling
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        let dateText = NSAttributedString(string: dateFormatter.string(from: invoice.issueDate), attributes: numberAttributes)
        let dateRect = CGRect(x: page.width - 185, y: 105, width: 125, height: 20)
        dateText.draw(in: dateRect)
    }
    
    private func drawProfessionalBillTo(context: CGContext, page: CGRect, customer: Customer, primary: UIColor, accent: UIColor) {
        // Professional bill to section
        let billToRect = CGRect(x: 40, y: 160, width: 350, height: 95)
        
        // Professional background
        context.setFillColor(primary.withAlphaComponent(0.04).cgColor)
        context.fill(billToRect)
        
        // Professional border
        context.setStrokeColor(primary.cgColor)
        context.setLineWidth(1)
        context.stroke(billToRect)
        
        // Bill to title with professional styling
        let billToFont = UIFont.systemFont(ofSize: 15, weight: .semibold)
        let billToAttributes: [NSAttributedString.Key: Any] = [
            .font: billToFont,
            .foregroundColor: primary
        ]
        let billToText = NSAttributedString(string: "BILL TO:", attributes: billToAttributes)
        let billToTextRect = CGRect(x: 50, y: 170, width: 100, height: 25)
        billToText.draw(in: billToTextRect)
        
        // Customer details with professional styling
        let customerFont = UIFont.systemFont(ofSize: 13, weight: .regular)
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
        let startY: CGFloat = 285
        
        // Consulting table header
        let headerRect = CGRect(x: 40, y: startY, width: page.width - 80, height: 35)
        
        // Consulting header background
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
        var xOffset: CGFloat = 50
        
        for (index, header) in headers.enumerated() {
            let headerText = NSAttributedString(string: header, attributes: headerAttributes)
            let headerTextRect = CGRect(x: xOffset, y: startY + 10, width: columnWidths[index], height: 20)
            headerText.draw(in: headerTextRect)
            xOffset += columnWidths[index]
        }
        
        // Consulting table rows
        let rowFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: rowFont,
            .foregroundColor: UIColor.black
        ]
        
        var yOffset = startY + 35
        for (index, item) in invoice.items.enumerated() {
            // Professional alternating rows
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
    
    private func drawProfessionalTotal(context: CGContext, page: CGRect, invoice: Invoice, currency: String, primary: UIColor, accent: UIColor) {
        let totalY: CGFloat = 450
        
        // Professional total box
        let totalRect = CGRect(x: page.width - 210, y: totalY, width: 160, height: 50)
        
        // Professional background
        context.setFillColor(accent.cgColor)
        context.fill(totalRect)
        
        // Professional border
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(2)
        context.stroke(totalRect)
        
        // Total text with professional styling
        let totalFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let totalAttributes: [NSAttributedString.Key: Any] = [
            .font: totalFont,
            .foregroundColor: UIColor.white
        ]
        let totalText = NSAttributedString(string: "TOTAL: \(currency)\(String(format: "%.2f", Double(truncating: invoice.subtotal as NSDecimalNumber)))", attributes: totalAttributes)
        let totalTextRect = CGRect(x: page.width - 200, y: totalY + 15, width: 140, height: 20)
        totalText.draw(in: totalTextRect)
    }
    
    private func drawConsultingFooter(context: CGContext, page: CGRect, company: Company, primary: UIColor) {
        let footerFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = NSAttributedString(string: "Professional consulting services. Expert solutions delivered.", attributes: footerAttributes)
        let footerRect = CGRect(x: 40, y: page.height - 50, width: page.width - 80, height: 20)
        footerText.draw(in: footerRect)
    }
}

// MARK: - Artistic Bold Template


