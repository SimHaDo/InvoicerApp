import Foundation
import UIKit

// MARK: - Safe helpers (no KVC, no crashes)

// Due Date via reflection (optional)
fileprivate func extractDueDate(from invoice: Invoice) -> Date? {
    for c in Mirror(reflecting: invoice).children {
        if c.label == "dueDate", let d = c.value as? Date { return d }
    }
    return nil
}

// ---- Payment Info extractor ----

// 1) tiny utils
fileprivate func _nonEmptyString(_ any: Any) -> String? {
    if let s = any as? String {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
    if let a = any as? NSAttributedString {
        let t = a.string.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
    return nil
}

fileprivate func _formatKV(_ dict: [String:String]) -> String {
    dict.compactMap { k, v in
        let vv = v.trimmingCharacters(in: .whitespacesAndNewlines)
        return vv.isEmpty ? nil : "\(k): \(vv)"
    }
    .sorted()
    .joined(separator: "\n")
}

// 2) pretty print for your PaymentMethod model
fileprivate func _renderPaymentMethod(_ pm: Any) -> String? {
    // Try your concrete type first
    if let m = pm as? PaymentMethod {
        switch m.type {
        case .bankIBAN(let iban, let swift, let beneficiary):
            return [
                "Bank • IBAN/SWIFT",
                beneficiary.flatMap { $0.isEmpty ? nil : "Beneficiary: \($0)" },
                "IBAN: \(iban)",
                "SWIFT/BIC: \(swift)"
            ]
            .compactMap { $0 }
            .joined(separator: "\n")

        case .bankUS(let account, let routing, let bankName):
            return [
                "Bank • US ACH/Wire",
                bankName.flatMap { $0.isEmpty ? nil : "Bank: \($0)" },
                "Account: \(account)",
                "Routing: \(routing)"
            ]
            .compactMap { $0 }
            .joined(separator: "\n")

        case .paypal(let email):
            return "PayPal\nEmail: \(email)"

        case .cardLink(let url):
            return "Payment Link\nURL: \(url)"

        case .crypto(let kind, let address, let memo):
            // CryptoKind.label ожидается в твоей модели
            let asset = (kind as AnyObject).value(forKey: "label") as? String ?? "Crypto"
            return [
                "Crypto • \(asset)",
                "Address: \(address)",
                memo.flatMap { $0.isEmpty ? nil : "Memo/Tag: \($0)" }
            ]
            .compactMap { $0 }
            .joined(separator: "\n")

        case .other(let name, let details):
            return [
                name.isEmpty ? "Other" : name,
                details
            ]
            .compactMap { $0.isEmpty ? nil : $0 }
            .joined(separator: "\n")
        }
    }

    // generic fallbacks
    if let s = _nonEmptyString(pm) { return s }
    if let d = pm as? [String:String] { return _formatKV(d) }
    if let arr = pm as? [[String:String]] {
        return arr.map(_formatKV).filter { !$0.isEmpty }.joined(separator: "\n\n")
    }
    if let arrPM = pm as? [PaymentMethod] {
        let blocks = arrPM.compactMap { _renderPaymentMethod($0) }
        return blocks.isEmpty ? nil : blocks.joined(separator: "\n\n")
    }
    return nil
}

/// Universal payment info extractor.
/// Supports: `paymentInfo`, `paymentInstructions`, `paymentTerms`,
/// `paymentMethod(s)`, `payments`, etc. (camel/snake case, any Optional).
fileprivate func extractPaymentInfo(from invoice: Invoice) -> String? {
    // normalized key set (lowercased, '_' removed)
    let keys: Set<String> = [
        "paymentinfo","paymentinfos",
        "paymentinstruction","paymentinstructions",
        "paymentterm","paymentterms",
        "paymentmethod","paymentmethods",
        "payments","payinfo","instructions"
    ]

    func normalized(_ raw: String) -> String {
        raw.lowercased().replacingOccurrences(of: "_", with: "")
    }

    let mirror = Mirror(reflecting: invoice)

    // 1) direct fields on Invoice
    for child in mirror.children {
        guard let label = child.label else { continue }
        let key = normalized(label)
        guard keys.contains(key) else { continue }

        let valueMirror = Mirror(reflecting: child.value)
        let value: Any
        if valueMirror.displayStyle == .optional {
            guard let some = valueMirror.children.first?.value else { continue }
            value = some
        } else {
            value = child.value
        }

        if let txt = _renderPaymentMethod(value) { return txt }
    }

    // 2) nested dictionaries like "meta" / "details"
    for child in mirror.children {
        if let dict = child.value as? [String: Any] {
            for (k, v) in dict { if keys.contains(normalized(k)), let txt = _renderPaymentMethod(v) { return txt } }
        }
    }
    return nil
}

// multi-line company block (neutral, generic)
fileprivate func companyLines(_ company: Company) -> [String] {
    var lines: [String] = []
    if !company.name.isEmpty { lines.append(company.name) }
    if !company.address.oneLine.isEmpty { lines.append(company.address.oneLine) }
    if !company.email.isEmpty { lines.append(company.email) }
    // try phone if present
    for c in Mirror(reflecting: company).children {
        if c.label?.lowercased() == "phone", let p = c.value as? String, !p.isEmpty {
            lines.append(p)
        }
    }
    return lines
}

// MARK: - All Geometric Abstract Template

struct AllGeometricAbstractTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let accent = theme.accent

        // Background
        R.fillRect(context: context, rect: page, color: .white)

        // Header
        let headerRect = CGRect(x: 0, y: 0, width: page.width, height: 132)
        R.fillRect(context: context, rect: headerRect, color: primary.withAlphaComponent(0.08))

        // Decor dots
        context.setFillColor(accent.withAlphaComponent(0.12).cgColor)
        for i in 0..<8 {
            let d: CGFloat = 36
            context.fillEllipse(in: CGRect(x: CGFloat(24 + i*80), y: 22, width: d, height: d))
        }

        // Logo
        let logoRect = CGRect(x: left + 8, y: 40, width: 72, height: 72)
        R.drawLogo(logo, in: logoRect, context: context, corner: 12, stroke: accent)

        // Company block (keeps space for invoice box)
        let compX = logoRect.maxX + 16
        let compW = (right - compX) - 200
        let compRect = CGRect(x: compX, y: 36, width: compW, height: 84)
        var cy = compRect.minY
        for (i, line) in companyLines(company).enumerated() {
            let f: UIFont = (i == 0) ? .systemFont(ofSize: 22, weight: .bold) : .systemFont(ofSize: 12, weight: .regular)
            let col: UIColor = (i == 0) ? primary : .black
            R.draw(R.text(line, font: f, color: col), in: CGRect(x: compRect.minX, y: cy, width: compRect.width, height: i == 0 ? 26 : 16))
            cy += (i == 0 ? 26 : 16)
            if cy > compRect.maxY - 14 { break }
        }

        // Invoice box (right)
        let invBoxW: CGFloat = 190
        let invBox = CGRect(x: right - invBoxW, y: 36, width: invBoxW, height: 92)
        R.fillRect(context: context, rect: invBox, color: accent.withAlphaComponent(0.10))
        R.strokeRect(context: context, rect: invBox, color: accent, width: 2)

        let dateFmt = BaseRenderer.date
        let dueDate = extractDueDate(from: invoice) ?? invoice.issueDate

        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 16, weight: .semibold), color: accent),
               in: CGRect(x: invBox.minX + 10, y: invBox.minY + 8, width: invBox.width - 20, height: 18))
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 13, weight: .semibold), color: primary),
               in: CGRect(x: invBox.minX + 10, y: invBox.minY + 28, width: invBox.width - 20, height: 16))
        R.draw(R.text("Issue Date: \(dateFmt.string(from: invoice.issueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: invBox.minX + 10, y: invBox.minY + 46, width: invBox.width - 20, height: 14))
        R.draw(R.text("Due Date: \(dateFmt.string(from: dueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: invBox.minX + 10, y: invBox.minY + 62, width: invBox.width - 20, height: 14))

        // BILL TO
        let billRect = CGRect(x: left, y: headerRect.maxY + 16, width: min(360, right - left), height: 106)
        R.fillRect(context: context, rect: billRect, color: primary.withAlphaComponent(0.06))
        R.strokeRect(context: context, rect: billRect, color: primary, width: 1)

        R.draw(R.text("BILL TO:", font: .systemFont(ofSize: 13, weight: .semibold), color: primary),
               in: CGRect(x: billRect.minX + 10, y: billRect.minY + 8, width: billRect.width - 20, height: 16))

        var by = billRect.minY + 28
        for s in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(s, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: billRect.minX + 10, y: by, width: billRect.width - 20, height: 18))
            by += 18
        }

        // Table (paged)
        let tableTop = billRect.maxY + 14
        let headers = ["Description", "Qty", "Unit Price", "Amount"]
        let specs: [CGFloat] = [0.58, 0.12, 0.14, 0.16]

        let res = R.drawTablePaged(
            context: context, page: page,
            left: left, right: right, top: tableTop, safeBottom: P.bottom,
            headers: headers, colSpecs: specs, items: invoice.items,
            currencyCode: currency,
            headerBg: { rect in self.R.fillRect(context: context, rect: rect, color: primary) },
            headerCell: { _, t, x, w, top, _ in
                self.R.draw(self.R.text(t, font: .systemFont(ofSize: 12, weight: .semibold), color: .white),
                            in: CGRect(x: x + 10, y: top + 9, width: w - 14, height: 18))
            },
            rowBg: { i, rect in if i % 2 == 0 { self.R.fillRect(context: context, rect: rect, color: accent.withAlphaComponent(0.06)) } },
            rowCell: { _, v, x, w, y, _ in
                self.R.draw(self.R.text(v, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                            in: CGRect(x: x + 10, y: y + 6, width: w - 14, height: 18))
            },
            rowH: 28, headerH: 35,
            continuationNoteColor: accent.withAlphaComponent(0.9)
        )

        guard res.hasMore == false else { return }

        // Totals (right)
        let subtotal = R.subtotal(invoice.items)
        let totalsW: CGFloat = 210
        let tx = right - totalsW
        var tTop = R.placeBlock(below: res.lastY + 12, desiredHeight: 72, page: page, safeBottom: P.bottom)

        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: tx, y: tTop, width: 100, height: 16))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 11, weight: .semibold), color: .black),
               in: CGRect(x: tx + 100, y: tTop, width: 100, height: 16))
        tTop += 20

        let totalBar = CGRect(x: tx, y: tTop, width: totalsW, height: 40)
        R.fillRect(context: context, rect: totalBar, color: accent)
        let total = subtotal
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 15, weight: .bold), color: .white),
               in: CGRect(x: totalBar.minX + 10, y: totalBar.minY + 10, width: 90, height: 20))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 15, weight: .bold), color: .white),
               in: CGRect(x: totalBar.minX + 100, y: totalBar.minY + 10, width: 100, height: 20))

        // Left column: Payment Instructions / Notes
        var infoTop = res.lastY + 12
        let infoWidth = (tx - left) - 16
        if let pi = extractPaymentInfo(from: invoice) {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 80)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.3), width: 1)
            R.draw(R.text("PAYMENT INSTRUCTIONS", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 14))
            R.draw(R.text(pi, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: box.height - 26))
            infoTop = box.maxY + 10
        }
        if let notes = invoice.paymentNotes, !notes.isEmpty {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 80)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.3), width: 1)
            R.draw(R.text("NOTES", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 14))
            R.draw(R.text(notes, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: box.height - 26))
        }

        // Footer
        let fy = page.height - P.bottom
        R.draw(R.text("Thank you for your business.", font: .systemFont(ofSize: 10, weight: .regular), color: .gray),
               in: CGRect(x: left, y: fy - 14, width: right - left, height: 14))
    }
}

// MARK: - All Vintage Retro Template

struct AllVintageRetroTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let accent = theme.accent

        R.fillRect(context: context, rect: page, color: .white)

        // Header soft retro
        let header = CGRect(x: 0, y: 0, width: page.width, height: 140)
        R.fillRect(context: context, rect: header, color: primary.withAlphaComponent(0.10))
        context.setFillColor(accent.withAlphaComponent(0.18).cgColor)
        for i in 0..<6 { context.fillEllipse(in: CGRect(x: CGFloat(i * 100 + 20), y: 12, width: 16, height: 16)) }

        // Logo
        let logoRect = CGRect(x: left + 10, y: 42, width: 80, height: 80)
        R.drawLogo(logo, in: logoRect, context: context, corner: 10, stroke: accent)

        // Company block
        let compX = logoRect.maxX + 16
        let compW = (right - compX) - 200
        var cy = CGFloat(50)
        for (i, line) in companyLines(company).enumerated() {
            let f: UIFont = (i == 0) ? .systemFont(ofSize: 26, weight: .bold) : .systemFont(ofSize: 12, weight: .regular)
            let col: UIColor = (i == 0) ? primary : .black
            R.draw(R.text(line, font: f, color: col), in: CGRect(x: compX, y: cy, width: compW, height: i == 0 ? 28 : 16))
            cy += (i == 0 ? 28 : 16)
            if cy > 118 { break }
        }

        // Invoice box
        let inv = CGRect(x: right - 190, y: 50, width: 180, height: 80)
        R.fillRect(context: context, rect: inv, color: accent.withAlphaComponent(0.14))
        R.strokeRect(context: context, rect: inv, color: accent, width: 2)

        let dateFmt = BaseRenderer.date
        let dueDate = extractDueDate(from: invoice) ?? invoice.issueDate

        R.draw(R.text("INVOICE  #\(invoice.number)", font: .systemFont(ofSize: 14, weight: .bold), color: accent),
               in: CGRect(x: inv.minX + 8, y: inv.minY + 8, width: inv.width - 16, height: 18))
        R.draw(R.text("Issue: \(dateFmt.string(from: invoice.issueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 8, y: inv.minY + 30, width: inv.width - 16, height: 14))
        R.draw(R.text("Due:   \(dateFmt.string(from: dueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 8, y: inv.minY + 46, width: inv.width - 16, height: 14))

        // BILL TO
        let bill = CGRect(x: left, y: header.maxY + 18, width: min(380, right - left), height: 110)
        R.fillRect(context: context, rect: bill, color: primary.withAlphaComponent(0.07))
        R.strokeRect(context: context, rect: bill, color: primary, width: 1)
        R.draw(R.text("BILL TO:", font: .systemFont(ofSize: 14, weight: .semibold), color: primary),
               in: CGRect(x: bill.minX + 10, y: bill.minY + 8, width: bill.width - 20, height: 16))

        var by = bill.minY + 30
        for s in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(s, font: .systemFont(ofSize: 13, weight: .regular), color: .black),
                   in: CGRect(x: bill.minX + 10, y: by, width: bill.width - 20, height: 18))
            by += 20
        }

        // Table
        let tableTop = bill.maxY + 16
        let headers = ["Description", "Qty", "Unit Price", "Amount"]
        let specs: [CGFloat] = [0.60, 0.12, 0.14, 0.14]

        let res = R.drawTablePaged(
            context: context, page: page,
            left: left, right: right, top: tableTop, safeBottom: P.bottom,
            headers: headers, colSpecs: specs, items: invoice.items,
            currencyCode: currency,
            headerBg: { rect in self.R.fillRect(context: context, rect: rect, color: primary) },
            headerCell: { _, t, x, w, top, _ in
                self.R.draw(self.R.text(t, font: .systemFont(ofSize: 13, weight: .bold), color: .white),
                            in: CGRect(x: x + 12, y: top + 10, width: w - 16, height: 18))
            },
            rowBg: { i, rect in if i % 2 == 0 { self.R.fillRect(context: context, rect: rect, color: accent.withAlphaComponent(0.10)) } },
            rowCell: { _, v, x, w, y, _ in
                self.R.draw(self.R.text(v, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                            in: CGRect(x: x + 12, y: y + 6, width: w - 16, height: 20))
            },
            rowH: 30, headerH: 40,
            continuationNoteColor: accent
        )

        guard res.hasMore == false else { return }

        // Totals
        let subtotal = R.subtotal(invoice.items)
        let totalsW: CGFloat = 180
        let tx = right - totalsW
        var ty = R.placeBlock(below: res.lastY + 12, desiredHeight: 78, page: page, safeBottom: P.bottom)

        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: tx, y: ty, width: 90, height: 16))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 11, weight: .semibold), color: .black),
               in: CGRect(x: tx + 90, y: ty, width: 90, height: 16))
        ty += 22

        let totalBar = CGRect(x: tx, y: ty, width: totalsW, height: 56)
        R.fillRect(context: context, rect: totalBar, color: accent)
        let total = subtotal
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 18, weight: .bold), color: .white),
               in: CGRect(x: totalBar.minX + 10, y: totalBar.minY + 16, width: 80, height: 22))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 18, weight: .bold), color: .white),
               in: CGRect(x: totalBar.minX + 96, y: totalBar.minY + 16, width: 74, height: 22))

        // Payment info / Notes
        var infoTop = res.lastY + 12
        let infoWidth = (tx - left) - 16
        if let pi = extractPaymentInfo(from: invoice) {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 80)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.35), width: 1)
            R.draw(R.text("PAYMENT INSTRUCTIONS", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 14))
            R.draw(R.text(pi, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: box.height - 26))
            infoTop = box.maxY + 10
        }
        if let notes = invoice.paymentNotes, !notes.isEmpty {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 80)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.35), width: 1)
            R.draw(R.text("NOTES", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 14))
            R.draw(R.text(notes, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: box.height - 26))
        }

        // Footer
        let fy = page.height - P.bottom
        R.draw(R.text("Thank you for your business.", font: .systemFont(ofSize: 10, weight: .regular), color: .gray),
               in: CGRect(x: left, y: fy - 14, width: right - left, height: 14))
    }
}

// MARK: - All Business Classic Template

struct AllBusinessClassicTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let accent = theme.accent

        R.fillRect(context: context, rect: page, color: .white)

        // Header classic
        let header = CGRect(x: 0, y: 0, width: page.width, height: 118)
        R.fillRect(context: context, rect: header, color: primary.withAlphaComponent(0.06))
        R.strokeRect(context: context, rect: header, color: primary, width: 1)

        let logoRect = CGRect(x: left + 8, y: 28, width: 70, height: 70)
        R.drawLogo(logo, in: logoRect, context: context, corner: 10, stroke: primary)

        // Company block
        let compX = logoRect.maxX + 16
        let compW = (right - compX) - 190
        var cy = CGFloat(34)
        for (i, line) in companyLines(company).enumerated() {
            let f: UIFont = (i == 0) ? .systemFont(ofSize: 24, weight: .bold) : .systemFont(ofSize: 12, weight: .regular)
            let col: UIColor = (i == 0) ? primary : .black
            R.draw(R.text(line, font: f, color: col), in: CGRect(x: compX, y: cy, width: compW, height: i == 0 ? 24 : 16))
            cy += (i == 0 ? 24 : 16)
            if cy > 112 { break }
        }

        // Invoice box
        let inv = CGRect(x: right - 190, y: 30, width: 180, height: 78)
        R.fillRect(context: context, rect: inv, color: primary.withAlphaComponent(0.08))
        R.strokeRect(context: context, rect: inv, color: primary, width: 1)

        let dateFmt = BaseRenderer.date
        let dueDate = extractDueDate(from: invoice) ?? invoice.issueDate

        R.draw(R.text("INVOICE  #\(invoice.number)", font: .systemFont(ofSize: 14, weight: .semibold), color: primary),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 6, width: inv.width - 20, height: 18))
        R.draw(R.text("Issue: \(dateFmt.string(from: invoice.issueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 26, width: inv.width - 20, height: 14))
        R.draw(R.text("Due:   \(dateFmt.string(from: dueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 42, width: inv.width - 20, height: 14))

        // BILL TO
        let bill = CGRect(x: left, y: header.maxY + 16, width: min(360, right - left), height: 100)
        R.fillRect(context: context, rect: bill, color: primary.withAlphaComponent(0.04))
        R.strokeRect(context: context, rect: bill, color: primary, width: 1)
        R.draw(R.text("BILL TO:", font: .systemFont(ofSize: 13, weight: .semibold), color: primary),
               in: CGRect(x: bill.minX + 10, y: bill.minY + 8, width: bill.width - 20, height: 16))

        var by = bill.minY + 28
        for s in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(s, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: bill.minX + 10, y: by, width: bill.width - 20, height: 18))
            by += 18
        }

        // Table
        let tableTop = bill.maxY + 14
        let headers = ["Description", "Quantity", "Unit Price", "Amount"]
        let specs: [CGFloat] = [0.58, 0.14, 0.14, 0.14]

        let res = R.drawTablePaged(
            context: context, page: page,
            left: left, right: right, top: tableTop, safeBottom: P.bottom,
            headers: headers, colSpecs: specs, items: invoice.items,
            currencyCode: currency,
            headerBg: { rect in self.R.fillRect(context: context, rect: rect, color: primary) },
            headerCell: { _, t, x, w, top, _ in
                self.R.draw(self.R.text(t, font: .systemFont(ofSize: 12, weight: .bold), color: .white),
                            in: CGRect(x: x + 10, y: top + 9, width: w - 14, height: 18))
            },
            rowBg: { i, rect in if i % 2 == 0 { self.R.fillRect(context: context, rect: rect, color: primary.withAlphaComponent(0.05)) } },
            rowCell: { _, v, x, w, y, _ in
                self.R.draw(self.R.text(v, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                            in: CGRect(x: x + 10, y: y + 6, width: w - 14, height: 18))
            },
            rowH: 28, headerH: 35,
            continuationNoteColor: accent
        )

        guard res.hasMore == false else { return }

        // Totals
        let subtotal = R.subtotal(invoice.items)
        let totalsW: CGFloat = 180
        let tx = right - totalsW
        var ty = R.placeBlock(below: res.lastY + 10, desiredHeight: 72, page: page, safeBottom: P.bottom)

        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: tx, y: ty, width: 90, height: 16))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 11, weight: .semibold), color: .black),
               in: CGRect(x: tx + 90, y: ty, width: 90, height: 16))
        ty += 20

        R.strokeLine(context: context, from: CGPoint(x: tx, y: ty + 4), to: CGPoint(x: right, y: ty + 4), color: accent, width: 1)
        ty += 8

        let totalBar = CGRect(x: tx, y: ty, width: totalsW, height: 50)
        R.fillRect(context: context, rect: totalBar, color: primary)
        let total = subtotal
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 16, weight: .bold), color: .white),
               in: CGRect(x: totalBar.minX + 10, y: totalBar.minY + 12, width: 80, height: 22))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 16, weight: .bold), color: .white),
               in: CGRect(x: totalBar.minX + 92, y: totalBar.minY + 12, width: 78, height: 22))

        // Payment info / Notes
        var infoTop = res.lastY + 12
        let infoWidth = (tx - left) - 16
        if let pi = extractPaymentInfo(from: invoice) {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 76)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.35), width: 1)
            R.draw(R.text("PAYMENT INSTRUCTIONS", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 14))
            R.draw(R.text(pi, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: box.height - 26))
            infoTop = box.maxY + 10
        }
        if let notes = invoice.paymentNotes, !notes.isEmpty {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 76)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.35), width: 1)
            R.draw(R.text("NOTES", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 14))
            R.draw(R.text(notes, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: box.height - 26))
        }

        // Footer
        let fy = page.height - P.bottom
        R.draw(R.text("Thank you for your business.", font: .systemFont(ofSize: 10, weight: .regular), color: .gray),
               in: CGRect(x: left, y: fy - 14, width: right - left, height: 14))
    }
}

// MARK: - Enterprise Bold Template

struct EnterpriseBoldTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let accent = theme.accent

        R.fillRect(context: context, rect: page, color: .white)

        // Header: bold bars
        let header = CGRect(x: 0, y: 0, width: page.width, height: 150)
        R.fillRect(context: context, rect: header, color: primary.withAlphaComponent(0.14))
        context.setFillColor(accent.withAlphaComponent(0.22).cgColor)
        for i in 0..<4 {
            let w: CGFloat = 76
            context.fill(CGRect(x: CGFloat(18 + i*150), y: 0, width: w, height: header.height))
        }

        // Logo
        let logoRect = CGRect(x: left + 10, y: 46, width: 90, height: 90)
        R.drawLogo(logo, in: logoRect, context: context, corner: 12, stroke: accent)

        // Company block (multi-line)
        let compX = logoRect.maxX + 20
        let compW = (right - compX) - 240
        var cy = CGFloat(60)
        for (i, line) in companyLines(company).enumerated() {
            let f: UIFont = (i == 0) ? .systemFont(ofSize: 28, weight: .black) : .systemFont(ofSize: 12, weight: .regular)
            let col: UIColor = (i == 0) ? primary : .black
            R.draw(R.text(line, font: f, color: col), in: CGRect(x: compX, y: cy, width: compW, height: i == 0 ? 30 : 16))
            cy += (i == 0 ? 30 : 16)
            if cy > 140 { break }
        }

        // Invoice box (right)
        let invW: CGFloat = 220
        let inv = CGRect(x: right - invW, y: 58, width: invW, height: 86)
        R.fillRect(context: context, rect: inv, color: accent.withAlphaComponent(0.18))
        R.strokeRect(context: context, rect: inv, color: accent, width: 3)

        let dateFmt = BaseRenderer.date
        let dueDate = extractDueDate(from: invoice)

        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 22, weight: .black), color: accent),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 8, width: inv.width - 20, height: 24))
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 15, weight: .bold), color: primary),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 30, width: inv.width - 20, height: 18))
        R.draw(R.text("Issue Date: \(dateFmt.string(from: invoice.issueDate))", font: .systemFont(ofSize: 12, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 48, width: inv.width - 20, height: 16))
        if let dd = dueDate {
            R.draw(R.text("Due Date: \(dateFmt.string(from: dd))", font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: inv.minX + 10, y: inv.minY + 64, width: inv.width - 20, height: 16))
        }

        // BILL TO
        let bill = CGRect(x: left, y: header.maxY + 20, width: min(420, right - left), height: 120)
        R.fillRect(context: context, rect: bill, color: primary.withAlphaComponent(0.08))
        R.strokeRect(context: context, rect: bill, color: primary, width: 2)
        R.draw(R.text("BILL TO:", font: .systemFont(ofSize: 18, weight: .black), color: primary),
               in: CGRect(x: bill.minX + 12, y: bill.minY + 10, width: bill.width - 24, height: 22))

        var by = bill.minY + 40
        for s in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(s, font: .systemFont(ofSize: 15, weight: .regular), color: .black),
                   in: CGRect(x: bill.minX + 12, y: by, width: bill.width - 24, height: 22))
            by += 24
        }

        // Table
        let tableTop = bill.maxY + 20
        let headers = ["Description", "Quantity", "Unit Price", "Amount"]
        let specs: [CGFloat] = [0.55, 0.15, 0.15, 0.15]

        let res = R.drawTablePaged(
            context: context, page: page,
            left: left, right: right, top: tableTop, safeBottom: P.bottom,
            headers: headers, colSpecs: specs, items: invoice.items,
            currencyCode: currency,
            headerBg: { rect in self.R.fillRect(context: context, rect: rect, color: primary) },
            headerCell: { _, t, x, w, top, _ in
                self.R.draw(self.R.text(t, font: .systemFont(ofSize: 14, weight: .black), color: .white),
                            in: CGRect(x: x + 12, y: top + 10, width: w - 16, height: 20))
            },
            rowBg: { i, rect in if i % 2 == 0 { self.R.fillRect(context: context, rect: rect, color: accent.withAlphaComponent(0.10)) } },
            rowCell: { c, v, x, w, y, _ in
                let isAmount = (c == 3)
                let f = UIFont.systemFont(ofSize: 13, weight: isAmount ? .bold : .semibold)
                let col: UIColor = isAmount ? primary : .black
                self.R.draw(self.R.text(v, font: f, color: col),
                            in: CGRect(x: x + 12, y: y + 8, width: w - 16, height: 20))
            },
            rowH: 32, headerH: 45,
            continuationNoteColor: accent
        )

        guard !res.hasMore else { return }

        // Totals
        let subtotal = R.subtotal(invoice.items)
        let totalsW: CGFloat = 220
        let tx = right - totalsW
        var ty = R.placeBlock(below: res.lastY + 12, desiredHeight: 90, page: page, safeBottom: P.bottom)

        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 12, weight: .regular), color: .black),
               in: CGRect(x: tx, y: ty, width: 110, height: 18))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 12, weight: .bold), color: .black),
               in: CGRect(x: tx + 110, y: ty, width: 110, height: 18))
        ty += 22

        let totalBar = CGRect(x: tx, y: ty, width: totalsW, height: 68)
        R.fillRect(context: context, rect: totalBar, color: accent)
        let total = subtotal
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 20, weight: .black), color: .white),
               in: CGRect(x: totalBar.minX + 12, y: totalBar.minY + 22, width: 100, height: 24))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 20, weight: .black), color: .white),
               in: CGRect(x: totalBar.minX + 116, y: totalBar.minY + 22, width: 92, height: 24))

        // Left column: Payment Info / Notes
        var infoTop = res.lastY + 12
        let infoWidth = (tx - left) - 16

        if let pi = extractPaymentInfo(from: invoice) {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 86)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.35), width: 1)
            R.draw(R.text("PAYMENT INSTRUCTIONS", font: .systemFont(ofSize: 12, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 10, y: box.minY + 8, width: box.width - 20, height: 16))
            R.draw(R.text(pi, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 10, y: box.minY + 26, width: box.width - 20, height: box.height - 36))
            infoTop = box.maxY + 10
        }

        if let notes = invoice.paymentNotes, !notes.isEmpty {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 86)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.35), width: 1)
            R.draw(R.text("NOTES", font: .systemFont(ofSize: 12, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 10, y: box.minY + 8, width: box.width - 20, height: 16))
            R.draw(R.text(notes, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 10, y: box.minY + 26, width: box.width - 20, height: box.height - 36))
        }

        // Footer
        let fy = page.height - P.bottom
        R.draw(R.text("Thank you for your business.", font: .systemFont(ofSize: 12, weight: .regular), color: .gray),
               in: CGRect(x: left, y: fy - 18, width: right - left, height: 18))
    }
}

// MARK: - Consulting Elegant Template

struct ConsultingElegantTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let accent = theme.accent

        R.fillRect(context: context, rect: page, color: .white)

        // Header (thin lines)
        let header = CGRect(x: 0, y: 0, width: page.width, height: 128)
        R.fillRect(context: context, rect: header, color: primary.withAlphaComponent(0.05))

        context.setStrokeColor(accent.withAlphaComponent(0.25).cgColor)
        context.setLineWidth(1)
        for i in 0..<9 {
            let y = CGFloat(12 + i * 12)
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: page.width, y: y))
        }
        context.strokePath()

        let logoRect = CGRect(x: left + 8, y: 34, width: 76, height: 76)
        R.drawLogo(logo, in: logoRect, context: context, corner: 10, stroke: accent)

        // Company
        let compX = logoRect.maxX + 16
        let compW = (right - compX) - 180
        var cy = CGFloat(40)
        for (i, line) in companyLines(company).enumerated() {
            let f: UIFont = (i == 0) ? .systemFont(ofSize: 24, weight: .semibold) : .systemFont(ofSize: 12, weight: .regular)
            let col: UIColor = (i == 0) ? primary : .black
            R.draw(R.text(line, font: f, color: col), in: CGRect(x: compX, y: cy, width: compW, height: i == 0 ? 26 : 16))
            cy += (i == 0 ? 26 : 16)
            if cy > 118 { break }
        }

        // Invoice box
        let inv = CGRect(x: right - 180, y: 40, width: 170, height: 78)
        R.fillRect(context: context, rect: inv, color: accent.withAlphaComponent(0.08))
        R.strokeRect(context: context, rect: inv, color: accent, width: 1)

        let dateFmt = BaseRenderer.date
        let dueDate = extractDueDate(from: invoice) ?? invoice.issueDate

        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 18, weight: .medium), color: accent),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 6, width: inv.width - 20, height: 20))
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 14, weight: .regular), color: primary),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 26, width: inv.width - 20, height: 16))
        R.draw(R.text("Issue: \(dateFmt.string(from: invoice.issueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 44, width: inv.width - 20, height: 14))
        R.draw(R.text("Due:   \(dateFmt.string(from: dueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 60, width: inv.width - 20, height: 14))

        // BILL TO
        let bill = CGRect(x: left, y: header.maxY + 16, width: min(380, right - left), height: 102)
        R.fillRect(context: context, rect: bill, color: primary.withAlphaComponent(0.03))
        R.strokeRect(context: context, rect: bill, color: primary, width: 1)
        R.draw(R.text("BILL TO:", font: .systemFont(ofSize: 14, weight: .medium), color: primary),
               in: CGRect(x: bill.minX + 10, y: bill.minY + 8, width: bill.width - 20, height: 16))

        var by = bill.minY + 28
        for s in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(s, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: bill.minX + 10, y: by, width: bill.width - 20, height: 18))
            by += 18
        }

        // Table
        let tableTop = bill.maxY + 14
        let headers = ["Description", "Quantity", "Unit Price", "Amount"]
        let specs: [CGFloat] = [0.58, 0.12, 0.14, 0.16]

        let res = R.drawTablePaged(
            context: context, page: page,
            left: left, right: right, top: tableTop, safeBottom: P.bottom,
            headers: headers, colSpecs: specs, items: invoice.items,
            currencyCode: currency,
            headerBg: { rect in self.R.fillRect(context: context, rect: rect, color: primary) },
            headerCell: { _, t, x, w, top, _ in
                self.R.draw(self.R.text(t, font: .systemFont(ofSize: 13, weight: .medium), color: .white),
                            in: CGRect(x: x + 10, y: top + 9, width: w - 14, height: 18))
            },
            rowBg: { i, rect in if i % 2 == 0 { self.R.fillRect(context: context, rect: rect, color: accent.withAlphaComponent(0.05)) } },
            rowCell: { _, v, x, w, y, _ in
                self.R.draw(self.R.text(v, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                            in: CGRect(x: x + 10, y: y + 6, width: w - 14, height: 18))
            },
            rowH: 28, headerH: 35,
            continuationNoteColor: accent
        )

        guard res.hasMore == false else { return }

        // Totals
        let subtotal = R.subtotal(invoice.items)
        let totalsW: CGFloat = 190
        let tx = right - totalsW
        var ty = R.placeBlock(below: res.lastY + 10, desiredHeight: 70, page: page, safeBottom: P.bottom)

        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: tx, y: ty, width: 92, height: 16))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 11, weight: .semibold), color: .black),
               in: CGRect(x: tx + 92, y: ty, width: 98, height: 16))
        ty += 18

        R.strokeLine(context: context, from: CGPoint(x: tx, y: ty + 4), to: CGPoint(x: right, y: ty + 4), color: accent, width: 1)
        ty += 8

        let totalBar = CGRect(x: tx, y: ty, width: totalsW, height: 50)
        R.fillRect(context: context, rect: totalBar, color: accent)
        let total = subtotal
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 18, weight: .medium), color: .white),
               in: CGRect(x: totalBar.minX + 10, y: totalBar.minY + 14, width: 80, height: 22))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 18, weight: .medium), color: .white),
               in: CGRect(x: totalBar.minX + 92, y: totalBar.minY + 14, width: 88, height: 22))

        // Payment info / Notes
        var infoTop = res.lastY + 12
        let infoWidth = (tx - left) - 16
        if let pi = extractPaymentInfo(from: invoice) {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 76)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.3), width: 1)
            R.draw(R.text("PAYMENT INSTRUCTIONS", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 14))
            R.draw(R.text(pi, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: box.height - 26))
            infoTop = box.maxY + 10
        }
        if let notes = invoice.paymentNotes, !notes.isEmpty {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 76)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.3), width: 1)
            R.draw(R.text("NOTES", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 14))
            R.draw(R.text(notes, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: box.height - 26))
        }

        // Footer
        let fy = page.height - P.bottom
        R.draw(R.text("Thank you for your business.", font: .systemFont(ofSize: 10, weight: .regular), color: .gray),
               in: CGRect(x: left, y: fy - 14, width: right - left, height: 14))
    }
}
