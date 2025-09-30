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
            case .modern:
                ModernTemplate(theme: template.theme)
                    .draw(in: ctx.cgContext,
                          page: pageRect,
                          invoice: invoice,
                          company: company,
                          customer: customer,
                          currency: currencyCode,
                          logo: logo)
            case .minimal:
                MinimalTemplate(theme: template.theme)
                    .draw(in: ctx.cgContext,
                          page: pageRect,
                          invoice: invoice,
                          company: company,
                          customer: customer,
                          currency: currencyCode,
                          logo: logo)
            case .classic:
                ClassicTemplate(theme: template.theme)
                    .draw(in: ctx.cgContext,
                          page: pageRect,
                          invoice: invoice,
                          company: company,
                          customer: customer,
                          currency: currencyCode,
                          logo: logo)
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
    /// Отрисовка логотипа с корректной ориентацией UIImage
    func draw(logo: UIImage, fit rect: CGRect) {
        let sz = logo.size
        guard sz.width > 0, sz.height > 0 else { return }
        let k = min(rect.width / sz.width, rect.height / sz.height)
        let size = CGSize(width: sz.width * k, height: sz.height * k)
        let target = CGRect(
            x: rect.midX - size.width / 2,
            y: rect.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
        saveGState()
        UIGraphicsPushContext(self)  // учитывать orientation
        logo.draw(in: target)
        UIGraphicsPopContext()
        restoreGState()
    }
}

// MARK: - Items table

private struct ItemsTable {
    let inset: CGFloat = 36
    let rowH: CGFloat = 24
    let headerH: CGFloat = 28
    let col1: CGFloat = 260
    let col2: CGFloat = 60
    let col3: CGFloat = 90
    let col4: CGFloat = 90

    func qtyString(_ d: Decimal) -> String { NSDecimalNumber(decimal: d).stringValue }

    func draw(context: CGContext, yStart: CGFloat, invoice: Invoice, currency: String, theme: TemplateTheme) -> CGFloat {
        let startX: CGFloat = inset
        var y = yStart

        context.fill(CGRect(x: startX, y: y, width: Paper.a4.width - inset*2, height: headerH),
                     color: theme.primary.withAlphaComponent(0.08))
        let headerFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
        context.draw(text: "DESCRIPTION", in: CGRect(x: startX+8, y: y+6, width: col1-16, height: headerH), font: headerFont, color: theme.primary)
        context.draw(text: "QTY",         in: CGRect(x: startX+col1, y: y+6, width: col2, height: headerH), font: headerFont, color: theme.primary, alignment: .right)
        context.draw(text: "RATE",        in: CGRect(x: startX+col1+col2, y: y+6, width: col3, height: headerH), font: headerFont, color: theme.primary, alignment: .right)
        context.draw(text: "AMOUNT",      in: CGRect(x: startX+col1+col2+col3, y: y+6, width: col4, height: headerH), font: headerFont, color: theme.primary, alignment: .right)
        y += headerH + 2

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

// MARK: - Payment formatter + block (использует ИМЕННО invoice.paymentMethods/Notes)

private struct PaymentFormatter {
    struct Line { let title: String; let value: String }

    static func lines(from methods: [Any]) -> [Line] {
        methods.compactMap { format(method: $0) }
    }

    private static func format(method: Any) -> Line? {
        let m = Mirror(reflecting: method)
        if let typeChild = m.children.first(where: { $0.label == "type" }) {
            return formatTypeValue(typeChild.value)
        }
        return formatTypeValue(method)
    }

    private static func formatTypeValue(_ v: Any) -> Line {
        let mirror = Mirror(reflecting: v)

        if mirror.displayStyle == .enum {
            let caseName = String(describing: v).components(separatedBy: "(").first ?? "\(v)"
            let lower = caseName.lowercased()
            let payload = extractFields(from: v)

            switch true {
            case lower.contains("bankiban"):
                let value = text(from: payload, preferredOrder: ["iban","bic","beneficiary","name","holder"]) ?? ""
                return .init(title: "Bank (IBAN)", value: value)

            case lower.contains("bankus"):
                let value = text(from: payload, preferredOrder: ["account","routing","name","holder"]) ?? ""
                return .init(title: "Bank (US)", value: value)

            case lower.contains("paypal"):
                let value = text(from: payload, preferredOrder: ["email","id"]) ?? ""
                return .init(title: "PayPal", value: value)

            case lower.contains("cardlink"), lower.contains("card"):
                let value = text(from: payload, preferredOrder: ["url","link"]) ?? ""
                return .init(title: "Card Payment", value: value)

            case lower.contains("crypto"):
                // Монета по множеству возможных ключей
                let symKeyOrder = ["symbol","ticker","coin","currency","code","asset","token","kind"]
                var sym: String?
                for k in symKeyOrder {
                    if let v = payload[k], !v.isEmpty { sym = v.uppercased(); break }
                }
                let title = sym.map { "Crypto (\($0))" } ?? "Crypto"
                // Адрес + memo/tag + сеть
                let value = text(from: payload,
                                 preferredOrder: ["address","memo","tag","destinationtag","paymentid","network","name","holder","beneficiary","note","id","email","details","value"]) ?? ""
                return .init(title: title, value: value)

            default:
                let title = (payload["name"]?.nonEmpty) ?? humanize(caseName)
                let value = payload["details"]?.nonEmpty
                    ?? text(from: payload, preferredOrder: ["value","address","info","note"]) ?? ""
                return .init(title: title, value: value)
            }
        }

        let dict = extractFields(from: v)
        let title = dict["name"]?.nonEmpty ?? dict["method"]?.nonEmpty ?? "Payment"
        let value = dict["details"]?.nonEmpty
            ?? text(from: dict, preferredOrder: ["iban","account","email","url","address"]) ?? ""
        return .init(title: title, value: value)
    }

    private static func extractFields(from any: Any) -> [String:String] {
        var out: [String:String] = [:]
        let mirror = Mirror(reflecting: any)

        if mirror.displayStyle == .enum, let payload = mirror.children.first?.value {
            return extractFields(from: payload)
        }

        for (labelOpt, value) in mirror.children {
            guard let rawLabel = labelOpt else { continue }
            let label = rawLabel.lowercased()

            if let s = value as? String, !s.isEmpty {
                out[label] = s
            } else if let sOpt = value as? String?, let s = sOpt, !s.isEmpty {
                out[label] = s
            } else if let desc = value as? CustomStringConvertible {
                let s = desc.description
                if !s.isEmpty { out[label] = s }
            } else {
                let nested = Mirror(reflecting: value)
                if !nested.children.isEmpty {
                    let nestedMap = extractFields(from: value)
                    for (k, v) in nestedMap where !v.isEmpty { out[k] = v }
                }
            }
        }
        return out
    }

    private static func text(from dict: [String:String], preferredOrder keys: [String]) -> String? {
        var parts: [String] = []
        for k in keys {
            if let v = dict[k], !v.isEmpty {
                switch k {
                case "iban": parts.append("IBAN: \(v)")
                case "bic": parts.append("BIC/SWIFT: \(v)")
                case "account": parts.append("Account: \(v)")
                case "routing": parts.append("Routing: \(v)")
                case "email": parts.append("Email: \(v)")
                case "url", "link": parts.append(v)
                case "address": parts.append(v)
                case "memo": parts.append("Memo: \(v)")
                case "tag": parts.append("Tag: \(v)")
                case "destinationtag": parts.append("Destination tag: \(v)")
                case "paymentid": parts.append("Payment ID: \(v)")
                case "network": parts.append("Network: \(v)")
                case "symbol", "kind", "coin", "ticker", "currency", "code", "asset", "token":
                    break // монету показали в заголовке
                case "beneficiary","name","holder": parts.append(v)
                default: parts.append(v)
                }
            }
        }
        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }

    private static func humanize(_ raw: String) -> String {
        let s1 = raw.replacingOccurrences(of: "_", with: " ")
        var s2 = ""
        for ch in s1 {
            if ch.isUppercase { s2.append(" ") }
            s2.append(ch)
        }
        return s2.trimmingCharacters(in: .whitespaces).capitalized
    }
}

private extension String {
    var nonEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}

/// Блок «Payment Details»: рендерит ИМЕННО invoice.paymentMethods + invoice.paymentNotes.
private struct PaymentBlock {
    static func draw(on ctx: CGContext,
                     page r: CGRect,
                     yStart: CGFloat,
                     theme: TemplateTheme,
                     methods: [PaymentMethod],
                     notes: String?) -> CGFloat {

        let methodsAny: [Any] = methods.map { $0 }
        let lines = PaymentFormatter.lines(from: methodsAny)
        let hasNotes = (notes?.isEmpty == false)

        guard !lines.isEmpty || hasNotes else { return yStart }

        var y = yStart + 14

        let titleFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
        ctx.draw(text: "Payment Details",
                 in: CGRect(x: 36, y: y, width: r.width-72, height: 16),
                 font: titleFont, color: theme.primary)

        y += 20

        if !lines.isEmpty {
            let boxX: CGFloat = 36
            let boxW: CGFloat = r.width - 72
            let rowH: CGFloat = 18
            let leftW: CGFloat = 140

            let boxH = CGFloat(lines.count) * (rowH + 6) + 16
            ctx.fill(CGRect(x: boxX, y: y, width: boxW, height: boxH), color: theme.background)
            ctx.stroke(CGRect(x: boxX, y: y, width: boxW, height: boxH), color: theme.line, width: 1)

            let keyFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
            let valFont = UIFont.systemFont(ofSize: 11)

            var cy = y + 8
            for ln in lines {
                ctx.draw(text: ln.title,
                         in: CGRect(x: boxX + 10, y: cy, width: leftW - 10, height: rowH),
                         font: keyFont, color: theme.subtleText)
                ctx.draw(text: ln.value,
                         in: CGRect(x: boxX + leftW, y: cy, width: boxW - leftW - 12, height: rowH),
                         font: valFont, color: .label)
                cy += rowH + 6
            }
            y = cy + 8
        }

        if let notes, !notes.isEmpty {
            ctx.draw(text: notes,
                     in: CGRect(x: 36, y: y, width: r.width-72, height: 40),
                     font: .systemFont(ofSize: 11),
                     color: theme.subtleText)
            y += 44
        }

        return y
    }
}

// MARK: - Templates

private protocol Template {
    var theme: TemplateTheme { get }
    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?)
}

private struct ModernTemplate: Template {
    let theme: TemplateTheme

    func draw(in ctx: CGContext, page r: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        ctx.fill(CGRect(x: 0, y: 0, width: r.width, height: 8), color: theme.primary)

        let left = CGRect(x: 36, y: 24, width: r.width * 0.5 - 42, height: 120)
        let right = CGRect(x: r.width * 0.5, y: 24, width: r.width * 0.5 - 36, height: 120)

        if let logo { ctx.draw(logo: logo, fit: CGRect(x: left.minX, y: left.minY, width: 140, height: 60)) }
        let hTitle = UIFont.systemFont(ofSize: 28, weight: .bold)
        ctx.draw(text: "INVOICE",
                 in: CGRect(x: right.minX, y: right.minY, width: right.width, height: 34),
                 font: hTitle, color: theme.primary, alignment: .right)

        let infoFont = UIFont.systemFont(ofSize: 11)
        ctx.draw(text: company.name,
                 in: CGRect(x: left.minX, y: left.minY + 70, width: left.width, height: 15),
                 font: infoFont, color: .label)
        ctx.draw(text: company.address.line1,
                 in: CGRect(x: left.minX, y: left.minY + 85, width: left.width, height: 15),
                 font: infoFont, color: .secondaryLabel)

        let meta = [
            ("Number:", invoice.number),
            ("Issue Date:", Dates.display.string(from: invoice.issueDate)),
            ("Due Date:", Dates.display.string(from: invoice.dueDate ?? invoice.issueDate))
        ]
        var my = right.minY + 42
        for (k, v) in meta {
            ctx.draw(text: k,
                     in: CGRect(x: right.minX, y: my, width: 90, height: 14),
                     font: infoFont, color: theme.subtleText, alignment: .right)
            ctx.draw(text: v,
                     in: CGRect(x: right.minX + 100, y: my, width: right.width - 110, height: 14),
                     font: infoFont, color: .label, alignment: .right)
            my += 16
        }

        let billY: CGFloat = 160
        ctx.draw(text: "Bill To",
                 in: CGRect(x: 36, y: billY, width: 200, height: 16),
                 font: .systemFont(ofSize: 12, weight: .semibold), color: theme.primary)
        ctx.draw(text: customer.name,
                 in: CGRect(x: 36, y: billY+18, width: r.width/2-72, height: 16),
                 font: .systemFont(ofSize: 12), color: .label)
        ctx.draw(text: customer.email,
                 in: CGRect(x: 36, y: billY+34, width: r.width/2-72, height: 16),
                 font: .systemFont(ofSize: 11), color: .secondaryLabel)

        let table = ItemsTable()
        let afterTableY = table.draw(context: ctx, yStart: billY+64, invoice: invoice, currency: currency, theme: theme)

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

        // ✅ Используем invoice.paymentMethods и invoice.paymentNotes
        let afterPayments = PaymentBlock.draw(on: ctx,
                                              page: r,
                                              yStart: ty + 8,
                                              theme: theme,
                                              methods: invoice.paymentMethods,
                                              notes: invoice.paymentNotes)

        let footY = max(afterPayments + 10, r.height - 80)
        ctx.fill(CGRect(x: 36, y: footY, width: r.width-72, height: 1), color: theme.line)
        ctx.draw(text: "Thanks for your business!",
                 in: CGRect(x: 36, y: footY+10, width: r.width-72, height: 16),
                 font: .systemFont(ofSize: 11), color: theme.subtleText, alignment: .center)
    }
}

private struct MinimalTemplate: Template {
    let theme: TemplateTheme
    func draw(in ctx: CGContext, page r: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        ctx.fill(CGRect(x: 0, y: 0, width: r.width, height: 40), color: theme.primary.withAlphaComponent(0.06))
        if let logo { ctx.draw(logo: logo, fit: CGRect(x: 36, y: 6, width: 140, height: 28)) }
        ctx.draw(text: "Invoice \(invoice.number)",
                 in: CGRect(x: 36, y: 52, width: r.width-72, height: 26),
                 font: .systemFont(ofSize: 22, weight: .bold), color: .label)

        let metaF = UIFont.systemFont(ofSize: 11)
        let right = r.width - 36
        ctx.draw(text: "Issue: \(Dates.display.string(from: invoice.issueDate))",
                 in: CGRect(x: right-240, y: 56, width: 240, height: 14),
                 font: metaF, color: .secondaryLabel, alignment: .right)
        ctx.draw(text: "Due: \(Dates.display.string(from: invoice.dueDate ?? invoice.issueDate))",
                 in: CGRect(x: right-240, y: 72, width: 240, height: 14),
                 font: metaF, color: .secondaryLabel, alignment: .right)

        let y0: CGFloat = 96
        ctx.draw(text: "From",
                 in: CGRect(x: 36, y: y0, width: 200, height: 14),
                 font: .systemFont(ofSize: 12, weight: .semibold), color: theme.primary)
        ctx.draw(text: company.name,
                 in: CGRect(x: 36, y: y0+16, width: 260, height: 16),
                 font: .systemFont(ofSize: 12), color: .label)

        ctx.draw(text: "Bill To",
                 in: CGRect(x: 320, y: y0, width: 200, height: 14),
                 font: .systemFont(ofSize: 12, weight: .semibold), color: theme.primary)
        ctx.draw(text: customer.name,
                 in: CGRect(x: 320, y: y0+16, width: r.width-356, height: 16),
                 font: .systemFont(ofSize: 12), color: .label)

        let after = ItemsTable().draw(context: ctx, yStart: y0+48, invoice: invoice, currency: currency, theme: theme)

        let f = UIFont.systemFont(ofSize: 12, weight: .semibold)
        ctx.draw(text: "TOTAL",
                 in: CGRect(x: r.width-36-240, y: after+10, width: 120, height: 20),
                 font: f, color: theme.subtleText)
        ctx.draw(text: Money.fmt(invoice.subtotal, code: currency),
                 in: CGRect(x: r.width-36-120, y: after+10, width: 120, height: 20),
                 font: f, color: .label, alignment: .right)

        _ = PaymentBlock.draw(on: ctx,
                              page: r,
                              yStart: after + 36,
                              theme: theme,
                              methods: invoice.paymentMethods,
                              notes: invoice.paymentNotes)
    }
}

private struct ClassicTemplate: Template {
    let theme: TemplateTheme
    func draw(in ctx: CGContext, page r: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {
        ctx.stroke(r.insetBy(dx: 18, dy: 18), color: theme.line, width: 1)

        if let logo {
            ctx.draw(logo: logo, fit: CGRect(x: 36, y: 30, width: 160, height: 60))
        } else {
            ctx.draw(text: company.name,
                     in: CGRect(x: 36, y: 42, width: 260, height: 28),
                     font: .systemFont(ofSize: 24, weight: .bold), color: theme.primary)
        }

        ctx.draw(text: "INVOICE",
                 in: CGRect(x: r.width-36-200, y: 42, width: 200, height: 28),
                 font: .systemFont(ofSize: 24, weight: .heavy), color: theme.primary, alignment: .right)
        ctx.draw(text: "No. \(invoice.number)",
                 in: CGRect(x: r.width-36-200, y: 72, width: 200, height: 16),
                 font: .systemFont(ofSize: 12), color: .secondaryLabel, alignment: .right)

        ctx.draw(text: "Bill To:",
                 in: CGRect(x: 36, y: 120, width: 80, height: 16),
                 font: .systemFont(ofSize: 12, weight: .semibold), color: .label)
        ctx.draw(text: customer.name,
                 in: CGRect(x: 36, y: 138, width: r.width/2-72, height: 16),
                 font: .systemFont(ofSize: 12), color: .label)

        let after = ItemsTable().draw(context: ctx, yStart: 170, invoice: invoice, currency: currency, theme: theme)

        let f = UIFont.systemFont(ofSize: 12)
        ctx.draw(text: "Subtotal:",
                 in: CGRect(x: r.width-36-200, y: after+8, width: 100, height: 18),
                 font: f, color: .secondaryLabel)
        ctx.draw(text: Money.fmt(invoice.subtotal, code: currency),
                 in: CGRect(x: r.width-36-100, y: after+8, width: 100, height: 18),
                 font: f, color: .label, alignment: .right)
        ctx.draw(text: "Total:",
                 in: CGRect(x: r.width-36-200, y: after+28, width: 100, height: 18),
                 font: .systemFont(ofSize: 12, weight: .semibold), color: .label)
        ctx.draw(text: Money.fmt(invoice.subtotal, code: currency),
                 in: CGRect(x: r.width-36-100, y: after+28, width: 100, height: 18),
                 font: .systemFont(ofSize: 12, weight: .semibold), color: .label, alignment: .right)

        _ = PaymentBlock.draw(on: ctx,
                              page: r,
                              yStart: after + 56,
                              theme: theme,
                              methods: invoice.paymentMethods,
                              notes: invoice.paymentNotes)
    }
}
