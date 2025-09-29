//
//  PDFService.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/28/25.
//

// PDFService.swift
import UIKit

final class PDFService {

    static let shared = PDFService()

    // Основной API
    func generatePDF(invoice: Invoice,
                     company: Company,
                     customer: Customer,
                     currencyCode: String,
                     template: InvoiceTemplateDescriptor,
                     logo: UIImage?) throws -> URL {

        let fmt = UIGraphicsPDFRendererFormat()
        fmt.documentInfo = [
            kCGPDFContextTitle as String: "Invoice \(invoice.number)",
            kCGPDFContextAuthor as String: company.name
        ]

        let pageRect = CGRect(origin: .zero, size: Paper.a4)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: fmt)

        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            switch template.style {
            case .modern:  ModernTemplate(theme: template.theme)
                .draw(in: ctx.cgContext, page: pageRect, invoice: invoice, company: company, customer: customer, currency: currencyCode, logo: logo)
            case .minimal: MinimalTemplate(theme: template.theme)
                .draw(in: ctx.cgContext, page: pageRect, invoice: invoice, company: company, customer: customer, currency: currencyCode, logo: logo)
            case .classic: ClassicTemplate(theme: template.theme)
                .draw(in: ctx.cgContext, page: pageRect, invoice: invoice, company: company, customer: customer, currency: currencyCode, logo: logo)
            }
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Invoice-\(invoice.number).pdf")
        try data.write(to: url, options: .atomic)
        return url
    }
}

// MARK: - CGContext helpers

private extension CGContext {
    func fill(_ rect: CGRect, color: UIColor) {
        saveGState(); setFillColor(color.cgColor); fill(rect); restoreGState()
    }
    func stroke(_ rect: CGRect, color: UIColor, width: CGFloat = 1) {
        saveGState(); setStrokeColor(color.cgColor); setLineWidth(width); stroke(rect); restoreGState()
    }
    func draw(text: String, in rect: CGRect, font: UIFont, color: UIColor, alignment: NSTextAlignment = .left) {
        let p = NSMutableParagraphStyle(); p.alignment = alignment
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: p]
        NSAttributedString(string: text, attributes: attrs)
            .draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
    }
    func draw(logo: UIImage, fit rect: CGRect) {
        let sz = logo.size
        let k = min(rect.width / sz.width, rect.height / sz.height)
        let size = CGSize(width: sz.width * k, height: sz.height * k)
        let x = rect.midX - size.width/2, y = rect.midY - size.height/2
        if let cg = logo.cgImage { draw(cg, in: CGRect(x: x, y: y, width: size.width, height: size.height)) }
    }
}

// MARK: - Таблица

private struct ItemsTable {
    let inset: CGFloat = 36
    let rowH: CGFloat = 24
    let headerH: CGFloat = 28
    let col1: CGFloat = 260 // description
    let col2: CGFloat = 60  // qty
    let col3: CGFloat = 90  // rate
    let col4: CGFloat = 90  // total

    func qtyString(_ d: Decimal) -> String { NSDecimalNumber(decimal: d).stringValue }

    func draw(context: CGContext, yStart: CGFloat, invoice: Invoice, currency: String, theme: TemplateTheme) -> CGFloat {
        let startX: CGFloat = inset
        var y = yStart

        // Header
        context.fill(CGRect(x: startX, y: y, width: Paper.a4.width - inset*2, height: headerH), color: theme.primary.withAlphaComponent(0.08))
        let headerFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
        context.draw(text: "DESCRIPTION", in: CGRect(x: startX+8, y: y+6, width: col1-16, height: headerH), font: headerFont, color: theme.primary)
        context.draw(text: "QTY",         in: CGRect(x: startX+col1, y: y+6, width: col2, height: headerH), font: headerFont, color: theme.primary, alignment: .right)
        context.draw(text: "RATE",        in: CGRect(x: startX+col1+col2, y: y+6, width: col3, height: headerH), font: headerFont, color: theme.primary, alignment: .right)
        context.draw(text: "AMOUNT",      in: CGRect(x: startX+col1+col2+col3, y: y+6, width: col4, height: headerH), font: headerFont, color: theme.primary, alignment: .right)
        y += headerH + 2

        // Rows
        let font = UIFont.systemFont(ofSize: 11)
        for it in invoice.items {
            context.draw(text: it.description, in: CGRect(x: startX+8, y: y+6, width: col1-12, height: rowH), font: font, color: .label)
            context.draw(text: qtyString(it.quantity), in: CGRect(x: startX+col1, y: y+6, width: col2, height: rowH), font: font, color: .label, alignment: .right)
            context.draw(text: Money.fmt(it.rate, code: currency), in: CGRect(x: startX+col1+col2, y: y+6, width: col3, height: rowH), font: font, color: .label, alignment: .right)
            context.draw(text: Money.fmt(it.total, code: currency), in: CGRect(x: startX+col1+col2+col3, y: y+6, width: col4, height: rowH), font: font, color: .label, alignment: .right)

            let lineR = CGRect(x: startX, y: y+rowH, width: Paper.a4.width - inset*2, height: 1)
            context.fill(lineR, color: theme.line)
            y += rowH + 1
        }

        return y + 10
    }
}

// MARK: - Протокол и шаблоны

private protocol Template {
    var theme: TemplateTheme { get }
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?)
}

private struct ModernTemplate: Template {
    let theme: TemplateTheme

    func draw(in ctx: CGContext, page r: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        // Accent bar
        ctx.fill(CGRect(x: 0, y: 0, width: r.width, height: 8), color: theme.primary)

        // Header
        let left = CGRect(x: 36, y: 24, width: r.width * 0.5 - 42, height: 120)
        let right = CGRect(x: r.width * 0.5, y: 24, width: r.width * 0.5 - 36, height: 120)

        if let logo { ctx.draw(logo: logo, fit: CGRect(x: left.minX, y: left.minY, width: 140, height: 60)) }
        let hTitle = UIFont.systemFont(ofSize: 28, weight: .bold)
        ctx.draw(text: "INVOICE", in: CGRect(x: right.minX, y: right.minY, width: right.width, height: 34), font: hTitle, color: theme.primary, alignment: .right)

        let infoFont = UIFont.systemFont(ofSize: 11)
        ctx.draw(text: company.name, in: CGRect(x: left.minX, y: left.minY + 70, width: left.width, height: 15), font: infoFont, color: .label)
        ctx.draw(text: company.address.line1, in: CGRect(x: left.minX, y: left.minY + 85, width: left.width, height: 15), font: infoFont, color: .secondaryLabel)

        let meta = [
            ("Number:", invoice.number),
            ("Issue Date:", Dates.display.string(from: invoice.issueDate)),
            ("Due Date:", Dates.display.string(from: invoice.dueDate ?? invoice.issueDate))
        ]
        var my = right.minY + 42
        for (k, v) in meta {
            ctx.draw(text: k, in: CGRect(x: right.minX, y: my, width: 90, height: 14), font: infoFont, color: theme.subtleText, alignment: .right)
            ctx.draw(text: v, in: CGRect(x: right.minX + 100, y: my, width: right.width - 110, height: 14), font: infoFont, color: .label, alignment: .right)
            my += 16
        }

        // Bill to
        let billY: CGFloat = 160
        ctx.draw(text: "Bill To", in: CGRect(x: 36, y: billY, width: 200, height: 16), font: .systemFont(ofSize: 12, weight: .semibold), color: theme.primary)
        ctx.draw(text: customer.name,  in: CGRect(x: 36, y: billY+18, width: r.width/2-72, height: 16), font: .systemFont(ofSize: 12), color: .label)
        ctx.draw(text: customer.email, in: CGRect(x: 36, y: billY+34, width: r.width/2-72, height: 16), font: .systemFont(ofSize: 11), color: .secondaryLabel)

        // Items table
        let table = ItemsTable()
        let afterTableY = table.draw(context: ctx, yStart: billY+64, invoice: invoice, currency: currency, theme: theme)

        // Totals
        let totalBoxX = r.width - 36 - 240
        var ty = afterTableY + 8
        func row(_ title: String, _ value: String, bold: Bool = false) {
            let f = UIFont.systemFont(ofSize: 12, weight: bold ? .semibold : .regular)
            ctx.draw(text: title, in: CGRect(x: totalBoxX, y: ty, width: 120, height: 18), font: f, color: theme.subtleText)
            ctx.draw(text: value, in: CGRect(x: totalBoxX+120, y: ty, width: 120, height: 18), font: f, color: .label, alignment: .right)
            ty += 20
        }
        row("Subtotal", Money.fmt(invoice.subtotal, code: currency))
        row("Tax", "—")
        row("Total", Money.fmt(invoice.subtotal, code: currency), bold: true)

        // Footer
        let footY = r.height - 80
        ctx.fill(CGRect(x: 36, y: footY, width: r.width-72, height: 1), color: theme.line)
        ctx.draw(text: "Thanks for your business!", in: CGRect(x: 36, y: footY+10, width: r.width-72, height: 16), font: .systemFont(ofSize: 11), color: theme.subtleText, alignment: .center)
    }
}

private struct MinimalTemplate: Template {
    let theme: TemplateTheme
    func draw(in ctx: CGContext, page r: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        ctx.fill(CGRect(x: 0, y: 0, width: r.width, height: 40), color: theme.primary.withAlphaComponent(0.06))
        if let logo { ctx.draw(logo: logo, fit: CGRect(x: 36, y: 6, width: 140, height: 28)) }
        ctx.draw(text: "Invoice \(invoice.number)", in: CGRect(x: 36, y: 52, width: r.width-72, height: 26), font: .systemFont(ofSize: 22, weight: .bold), color: .label)

        let metaF = UIFont.systemFont(ofSize: 11)
        let right = r.width - 36
        ctx.draw(text: "Issue: \(Dates.display.string(from: invoice.issueDate))", in: CGRect(x: right-240, y: 56, width: 240, height: 14), font: metaF, color: .secondaryLabel, alignment: .right)
        ctx.draw(text: "Due: \(Dates.display.string(from: invoice.dueDate ?? invoice.issueDate))", in: CGRect(x: right-240, y: 72, width: 240, height: 14), font: metaF, color: .secondaryLabel, alignment: .right)

        let y0: CGFloat = 96
        ctx.draw(text: "From", in: CGRect(x: 36, y: y0, width: 200, height: 14), font: .systemFont(ofSize: 12, weight: .semibold), color: theme.primary)
        ctx.draw(text: company.name, in: CGRect(x: 36, y: y0+16, width: 260, height: 16), font: .systemFont(ofSize: 12), color: .label)

        ctx.draw(text: "Bill To", in: CGRect(x: 320, y: y0, width: 200, height: 14), font: .systemFont(ofSize: 12, weight: .semibold), color: theme.primary)
        ctx.draw(text: customer.name, in: CGRect(x: 320, y: y0+16, width: r.width-356, height: 16), font: .systemFont(ofSize: 12), color: .label)

        let after = ItemsTable().draw(context: ctx, yStart: y0+48, invoice: invoice, currency: currency, theme: theme)

        let f = UIFont.systemFont(ofSize: 12, weight: .semibold)
        ctx.draw(text: "TOTAL", in: CGRect(x: r.width-36-240, y: after+10, width: 120, height: 20), font: f, color: theme.subtleText)
        ctx.draw(text: Money.fmt(invoice.subtotal, code: currency), in: CGRect(x: r.width-36-120, y: after+10, width: 120, height: 20), font: f, color: .label, alignment: .right)
    }
}

private struct ClassicTemplate: Template {
    let theme: TemplateTheme
    func draw(in ctx: CGContext, page r: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        ctx.stroke(r.insetBy(dx: 18, dy: 18), color: theme.line, width: 1)

        if let logo {
            ctx.draw(logo: logo, fit: CGRect(x: 36, y: 30, width: 160, height: 60))
        } else {
            ctx.draw(text: company.name, in: CGRect(x: 36, y: 42, width: 260, height: 28), font: .systemFont(ofSize: 24, weight: .bold), color: theme.primary)
        }

        ctx.draw(text: "INVOICE", in: CGRect(x: r.width-36-200, y: 42, width: 200, height: 28), font: .systemFont(ofSize: 24, weight: .heavy), color: theme.primary, alignment: .right)
        ctx.draw(text: "No. \(invoice.number)", in: CGRect(x: r.width-36-200, y: 72, width: 200, height: 16), font: .systemFont(ofSize: 12), color: .secondaryLabel, alignment: .right)

        ctx.draw(text: "Bill To:", in: CGRect(x: 36, y: 120, width: 80, height: 16), font: .systemFont(ofSize: 12, weight: .semibold), color: .label)
        ctx.draw(text: customer.name, in: CGRect(x: 36, y: 138, width: r.width/2-72, height: 16), font: .systemFont(ofSize: 12), color: .label)

        let after = ItemsTable().draw(context: ctx, yStart: 170, invoice: invoice, currency: currency, theme: theme)

        let f = UIFont.systemFont(ofSize: 12)
        ctx.draw(text: "Subtotal:", in: CGRect(x: r.width-36-200, y: after+8, width: 100, height: 18), font: f, color: .secondaryLabel)
        ctx.draw(text: Money.fmt(invoice.subtotal, code: currency), in: CGRect(x: r.width-36-100, y: after+8, width: 100, height: 18), font: f, color: .label, alignment: .right)
        ctx.draw(text: "Total:", in: CGRect(x: r.width-36-200, y: after+28, width: 100, height: 18), font: .systemFont(ofSize: 12, weight: .semibold), color: .label)
        ctx.draw(text: Money.fmt(invoice.subtotal, code: currency), in: CGRect(x: r.width-36-100, y: after+28, width: 100, height: 18), font: .systemFont(ofSize: 12, weight: .semibold), color: .label, alignment: .right)
    }
}
