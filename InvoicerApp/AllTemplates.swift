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

///Second PArt
// MARK: - Accounting Detailed Template (унифицирован, без спец. слоганов)

struct AccountingDetailedTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent

        // фон
        R.fillRect(context: context, rect: page, color: .white)

        // Header c «бухгалтерской» сеткой
        let header = CGRect(x: 0, y: 0, width: page.width, height: 130)
        R.fillRect(context: context, rect: header, color: primary.withAlphaComponent(0.07))
        context.setStrokeColor(accent.withAlphaComponent(0.20).cgColor)
        context.setLineWidth(0.5)
        for i in 0..<25 {
            let x = CGFloat(i * 25)
            context.move(to: CGPoint(x: x, y: header.minY))
            context.addLine(to: CGPoint(x: x, y: header.maxY))
        }
        for i in 0..<10 {
            let y = CGFloat(i * 13)
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: page.width, y: y))
        }
        context.strokePath()

        // Логотип с рамкой
        let logoRect = CGRect(x: left + 7, y: 28, width: 75, height: 75)
        R.strokeRect(context: context, rect: logoRect, color: primary, width: 2)
        R.drawLogo(logo, in: logoRect, context: context, corner: 0, stroke: nil)

        // Компания (оставляем место под правый invoice-box)
        let compX = logoRect.maxX + 16
        let compW = (right - compX) - 190
        var cy = CGFloat(36)
        for (i, line) in companyLines(company).enumerated() {
            let f: UIFont = (i == 0) ? .systemFont(ofSize: 28, weight: .semibold) : .systemFont(ofSize: 12, weight: .medium)
            let col: UIColor = (i == 0) ? primary : .black
            R.draw(R.text(line, font: f, color: col), in: CGRect(x: compX, y: cy, width: compW, height: i == 0 ? 30 : 16))
            cy += (i == 0 ? 30 : 16)
            if cy > header.maxY - 14 { break }
        }
        // (убран узкоспециализированный подзаголовок)

        // Инфобокс инвойса (справа)
        let invBox = CGRect(x: right - 180, y: 35, width: 170, height: 80)
        R.fillRect(context: context, rect: invBox, color: accent.withAlphaComponent(0.10))
        R.strokeRect(context: context, rect: invBox, color: accent, width: 2)

        let dateFmt = BaseRenderer.date
        let due = extractDueDate(from: invoice) ?? invoice.issueDate

        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 19, weight: .semibold), color: accent),
               in: CGRect(x: invBox.minX + 8, y: invBox.minY + 6, width: invBox.width - 16, height: 22))
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 15, weight: .medium), color: primary),
               in: CGRect(x: invBox.minX + 8, y: invBox.minY + 28, width: invBox.width - 16, height: 18))
        R.draw(R.text("Issue: \(dateFmt.string(from: invoice.issueDate))", font: .systemFont(ofSize: 12, weight: .regular), color: .black),
               in: CGRect(x: invBox.minX + 8, y: invBox.minY + 46, width: invBox.width - 16, height: 16))
        R.draw(R.text("Due:   \(dateFmt.string(from: due))", font: .systemFont(ofSize: 12, weight: .regular), color: .black),
               in: CGRect(x: invBox.minX + 8, y: invBox.minY + 62, width: invBox.width - 16, height: 16))

        // BILL TO (с рамкой)
        let bill = CGRect(x: left, y: header.maxY + 18, width: min(380, right - left), height: 110)
        R.fillRect(context: context, rect: bill, color: primary.withAlphaComponent(0.05))
        R.strokeRect(context: context, rect: bill, color: primary, width: 1)
        R.draw(R.text("BILL TO:", font: .systemFont(ofSize: 16, weight: .semibold), color: primary),
               in: CGRect(x: bill.minX + 10, y: bill.minY + 8, width: bill.width - 20, height: 18))

        var by = bill.minY + 30
        for s in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(s, font: .systemFont(ofSize: 14, weight: .regular), color: .black),
                   in: CGRect(x: bill.minX + 10, y: by, width: bill.width - 20, height: 20))
            by += 20
        }

        // Таблица (пагинация)
        let tableTop = bill.maxY + 18
        let headers = ["Description", "Quantity", "Unit Price", "Total"]
        let specs: [CGFloat] = [0.58, 0.14, 0.14, 0.14]

        let res = R.drawTablePaged(
            context: context, page: page,
            left: left, right: right, top: tableTop, safeBottom: P.bottom,
            headers: headers, colSpecs: specs, items: invoice.items,
            currencyCode: currency,
            headerBg: { rect in self.R.fillRect(context: context, rect: rect, color: primary) },
            headerCell: { _, t, x, w, top, _ in
                self.R.draw(self.R.text(t, font: .systemFont(ofSize: 13, weight: .semibold), color: .white),
                            in: CGRect(x: x + 10, y: top + 10, width: w - 14, height: 18))
            },
            rowBg: { i, rect in if i % 2 == 0 { self.R.fillRect(context: context, rect: rect, color: accent.withAlphaComponent(0.06)) } },
            rowCell: { _, v, x, w, y, _ in
                self.R.draw(self.R.text(v, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                            in: CGRect(x: x + 10, y: y + 6, width: w - 14, height: 20))
            },
            rowH: 30, headerH: 35,
            continuationNoteColor: accent
        )

        guard !res.hasMore else { return }

        // ИТОГИ (справа)
        let subtotal = R.subtotal(invoice.items)
        let totalsW: CGFloat = 190
        let tx = right - totalsW
        var ty = R.placeBlock(below: res.lastY + 12, desiredHeight: 70, page: page, safeBottom: P.bottom)

        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 12, weight: .regular), color: .black),
               in: CGRect(x: tx, y: ty, width: 100, height: 18))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 12, weight: .semibold), color: .black),
               in: CGRect(x: tx + 100, y: ty, width: 90, height: 18))
        ty += 20

        let totalBar = CGRect(x: tx, y: ty, width: totalsW, height: 50)
        R.fillRect(context: context, rect: totalBar, color: accent)
        let total = subtotal
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 17, weight: .semibold), color: .white),
               in: CGRect(x: totalBar.minX + 10, y: totalBar.minY + 14, width: 80, height: 22))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 17, weight: .semibold), color: .white),
               in: CGRect(x: totalBar.minX + 90, y: totalBar.minY + 14, width: 90, height: 22))

        // Левый столбец: Payment Instructions / Notes
        var infoTop = res.lastY + 12
        let infoWidth = (tx - left) - 16

        if let pi = extractPaymentInfo(from: invoice) {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 86)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.35), width: 1)
            R.draw(R.text("PAYMENT INSTRUCTIONS", font: .systemFont(ofSize: 12, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 8, width: box.width - 16, height: 16))
            R.draw(R.text(pi, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 26, width: box.width - 16, height: box.height - 36))
            infoTop = box.maxY + 10
        }
        if let notes = invoice.paymentNotes, !notes.isEmpty {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 76)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.35), width: 1)
            R.draw(R.text("NOTES", font: .systemFont(ofSize: 12, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 8, width: box.width - 16, height: 16))
            R.draw(R.text(notes, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 26, width: box.width - 16, height: box.height - 36))
        }

        // Footer — дженерик
        let fy = page.height - P.bottom
        R.draw(R.text("Thank you for your business.", font: .systemFont(ofSize: 11, weight: .regular), color: .gray),
               in: CGRect(x: left, y: fy - 16, width: right - left, height: 16))
    }
}

// MARK: - Consulting Professional Template (унифицирован, без спец. слоганов)

struct ConsultingProfessionalTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let secondary = theme.secondary
        let accent = theme.accent

        // фон
        R.fillRect(context: context, rect: page, color: .white)

        // Header с «профессиональными» линиями
        let header = CGRect(x: 0, y: 0, width: page.width, height: 125)
        R.fillRect(context: context, rect: header, color: primary.withAlphaComponent(0.08))
        context.setStrokeColor(accent.withAlphaComponent(0.25).cgColor)
        context.setLineWidth(1)
        for i in 0..<12 {
            let y = CGFloat(i * 10)
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: page.width, y: y))
        }
        context.strokePath()

        // Лого
        let logoRect = CGRect(x: left + 8, y: 32, width: 70, height: 70)
        R.strokeRect(context: context, rect: logoRect, color: primary, width: 2)
        R.drawLogo(logo, in: logoRect, context: context, corner: 0, stroke: nil)

        // Компания (много строк), без узкого слогана
        let compX = logoRect.maxX + 16
        let compW = (right - compX) - 180
        var cy = CGFloat(40)
        for (i, line) in companyLines(company).enumerated() {
            let f: UIFont = (i == 0) ? .systemFont(ofSize: 27, weight: .semibold) : .systemFont(ofSize: 12, weight: .regular)
            let col: UIColor = (i == 0) ? primary : .black
            R.draw(R.text(line, font: f, color: col), in: CGRect(x: compX, y: cy, width: compW, height: i == 0 ? 28 : 16))
            cy += (i == 0 ? 28 : 16)
            if cy > header.maxY - 22 { break }
        }
        // (убран узкоспециализированный слоган)

        // Инфобокс инвойса (справа)
        let inv = CGRect(x: right - 165, y: 38, width: 155, height: 75)
        R.fillRect(context: context, rect: inv, color: accent.withAlphaComponent(0.10))
        R.strokeRect(context: context, rect: inv, color: accent, width: 2)

        let dateFmt = BaseRenderer.date
        let due = extractDueDate(from: invoice) ?? invoice.issueDate

        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 18, weight: .semibold), color: accent),
               in: CGRect(x: inv.minX + 8, y: inv.minY + 6, width: inv.width - 16, height: 20))
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 14, weight: .medium), color: primary),
               in: CGRect(x: inv.minX + 8, y: inv.minY + 26, width: inv.width - 16, height: 18))
        R.draw(R.text("Issue: \(dateFmt.string(from: invoice.issueDate))", font: .systemFont(ofSize: 12, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 8, y: inv.minY + 44, width: inv.width - 16, height: 16))
        R.draw(R.text("Due:   \(dateFmt.string(from: due))", font: .systemFont(ofSize: 12, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 8, y: inv.minY + 60, width: inv.width - 16, height: 16))

        // BILL TO
        let bill = CGRect(x: left, y: header.maxY + 18, width: min(360, right - left), height: 100)
        R.fillRect(context: context, rect: bill, color: primary.withAlphaComponent(0.04))
        R.strokeRect(context: context, rect: bill, color: primary, width: 1)
        R.draw(R.text("BILL TO:", font: .systemFont(ofSize: 15, weight: .semibold), color: primary),
               in: CGRect(x: bill.minX + 10, y: bill.minY + 8, width: bill.width - 20, height: 18))

        var by = bill.minY + 28
        for s in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(s, font: .systemFont(ofSize: 13, weight: .regular), color: .black),
                   in: CGRect(x: bill.minX + 10, y: by, width: bill.width - 20, height: 18))
            by += 18
        }

        // Таблица
        let tableTop = bill.maxY + 16
        let headers = ["Description", "Quantity", "Unit Price", "Total"]
        let specs: [CGFloat] = [0.58, 0.14, 0.14, 0.14]

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
            rowBg: { i, rect in if i % 2 == 0 { self.R.fillRect(context: context, rect: rect, color: accent.withAlphaComponent(0.05)) } },
            rowCell: { _, v, x, w, y, _ in
                self.R.draw(self.R.text(v, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                            in: CGRect(x: x + 10, y: y + 6, width: w - 14, height: 18))
            },
            rowH: 28, headerH: 35,
            continuationNoteColor: accent
        )

        guard !res.hasMore else { return }

        // Totals (справа)
        let subtotal = R.subtotal(invoice.items)
        let totalsW: CGFloat = 180
        let tx = right - totalsW
        var ty = R.placeBlock(below: res.lastY + 10, desiredHeight: 70, page: page, safeBottom: P.bottom)

        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: tx, y: ty, width: 90, height: 18))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 11, weight: .semibold), color: .black),
               in: CGRect(x: tx + 90, y: ty, width: 90, height: 18))
        ty += 18

        let totalBar = CGRect(x: tx, y: ty, width: totalsW, height: 50)
        R.fillRect(context: context, rect: totalBar, color: accent)
        let total = subtotal
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 16, weight: .semibold), color: .white),
               in: CGRect(x: totalBar.minX + 10, y: totalBar.minY + 14, width: 80, height: 20))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 16, weight: .semibold), color: .white),
               in: CGRect(x: totalBar.minX + 92, y: totalBar.minY + 14, width: 78, height: 20))

        // Левый столбец: Payment Instructions / Notes
        var infoTop = res.lastY + 12
        let infoWidth = (tx - left) - 16

        if let pi = extractPaymentInfo(from: invoice) {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 76)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.3), width: 1)
            R.draw(R.text("PAYMENT INSTRUCTIONS", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 16))
            R.draw(R.text(pi, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: box.height - 28))
            infoTop = box.maxY + 10
        }
        if let notes = invoice.paymentNotes, !notes.isEmpty {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 76)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.3), width: 1)
            R.draw(R.text("NOTES", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 16))
            R.draw(R.text(notes, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: box.height - 28))
        }

        // Footer — дженерик
        let fy = page.height - P.bottom
        R.draw(R.text("Thank you for your business.", font: .systemFont(ofSize: 10, weight: .regular), color: .gray),
               in: CGRect(x: left, y: fy - 14, width: right - left, height: 14))
    }
}


// MARK: - Photography Clean Template (унифицирован)

struct PhotographyCleanTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let accent = theme.accent

        // Фон
        R.fillRect(context: context, rect: page, color: .white)

        // Волнистые полосы слева (декор)
        func wave(_ color: UIColor, x: CGFloat, w: CGFloat, alpha: CGFloat) {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x, y: 0))
            path.addCurve(to: CGPoint(x: x + w, y: 0),
                          controlPoint1: CGPoint(x: x + w * 0.25, y: 60),
                          controlPoint2: CGPoint(x: x + w * 0.75, y: -60))
            path.addLine(to: CGPoint(x: x + w, y: page.height))
            path.addCurve(to: CGPoint(x: x, y: page.height),
                          controlPoint1: CGPoint(x: x + w * 0.75, y: page.height - 80),
                          controlPoint2: CGPoint(x: x + w * 0.25, y: page.height + 80))
            path.close()
            color.withAlphaComponent(alpha).setFill()
            path.fill()
        }
        wave(primary, x: left - 76, w: 160, alpha: 0.12)
        wave(accent,  x: left - 26, w: 120, alpha: 0.10)
        wave(primary.withAlphaComponent(0.6), x: left + 34, w: 90, alpha: 0.08)

        // Заголовок + логотип
        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 36, weight: .heavy), color: primary),
               in: CGRect(x: left, y: P.top - 4, width: 320, height: 44))
        let logoRect = CGRect(x: right - 72, y: P.top - 6, width: 60, height: 60)
        R.strokeRect(context: context, rect: logoRect, color: primary, width: 2)
        R.drawLogo(logo, in: logoRect, context: context, corner: 0, stroke: nil)

        // Блок компании (слева)
        var cy = P.top + 60
        for (i, line) in companyLines(company).enumerated() {
            let f: UIFont = (i == 0) ? .systemFont(ofSize: 16, weight: .semibold) : .systemFont(ofSize: 11, weight: .regular)
            R.draw(R.text(line, font: f, color: .black),
                   in: CGRect(x: left, y: cy, width: min(280, right - left), height: i == 0 ? 22 : 16))
            cy += (i == 0 ? 22 : 16)
        }

        // BILL TO (левая колонка) + мета инвойса (правая колонка)
        let colGap: CGFloat = 14
        let colW = (right - left - colGap) / 2
        let blockTop = cy + 24

        R.draw(R.text("BILL TO", font: .systemFont(ofSize: 12, weight: .bold), color: primary),
               in: CGRect(x: left, y: blockTop, width: colW, height: 16))
        let billLines = [customer.name, customer.address.oneLine, customer.email].filter{ !$0.isEmpty }
        var by = blockTop + 18
        for s in billLines {
            R.draw(R.text(s, font: .systemFont(ofSize: 12), color: .black),
                   in: CGRect(x: left, y: by, width: colW, height: 18))
            by += 18
        }

        let df = BaseRenderer.date
        let due = extractDueDate(from: invoice) ?? invoice.issueDate
        R.draw(R.text("INVOICE #", font: .systemFont(ofSize: 12, weight: .bold), color: primary),
               in: CGRect(x: left + colW + colGap, y: blockTop, width: 100, height: 16))
        R.draw(R.text(invoice.number, font: .systemFont(ofSize: 12), color: .black),
               in: CGRect(x: left + colW + colGap + 90, y: blockTop, width: colW - 90, height: 16))

        R.draw(R.text("INVOICE DATE", font: .systemFont(ofSize: 12, weight: .bold), color: primary),
               in: CGRect(x: left + colW + colGap, y: blockTop + 18, width: 120, height: 16))
        R.draw(R.text(df.string(from: invoice.issueDate), font: .systemFont(ofSize: 12), color: .black),
               in: CGRect(x: left + colW + colGap + 90, y: blockTop + 18, width: colW - 90, height: 16))

        R.draw(R.text("DUE DATE", font: .systemFont(ofSize: 12, weight: .bold), color: primary),
               in: CGRect(x: left + colW + colGap, y: blockTop + 36, width: 120, height: 16))
        R.draw(R.text(df.string(from: due), font: .systemFont(ofSize: 12), color: .black),
               in: CGRect(x: left + colW + colGap + 90, y: blockTop + 36, width: colW - 90, height: 16))

        // Разделитель
        R.strokeLine(context: context, from: CGPoint(x: left, y: blockTop + 70), to: CGPoint(x: right, y: blockTop + 70), color: primary.withAlphaComponent(0.4), width: 1)

        // Таблица (пагинация)
        let tTop = blockTop + 82
        let headers = ["QTY", "DESCRIPTION", "UNIT PRICE", "AMOUNT"]
        let specs: [CGFloat] = [0.12, 0.58, 0.15, 0.15]

        let res = R.drawTablePaged(
            context: context, page: page,
            left: left, right: right, top: tTop, safeBottom: P.bottom,
            headers: headers, colSpecs: specs, items: invoice.items, currencyCode: currency,
            headerBg: { rect in
                // просто линия вместо окрашивания
                self.R.strokeLine(context: context, from: CGPoint(x: rect.minX, y: rect.maxY),
                                  to: CGPoint(x: rect.maxX, y: rect.maxY),
                                  color: primary.withAlphaComponent(0.4), width: 1)
            },
            headerCell: { _, t, x, w, top, _ in
                self.R.draw(self.R.text(t, font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                            in: CGRect(x: x + 6, y: top, width: w - 12, height: 18))
            },
            rowBg: { i, rect in
                if i % 2 == 0 { self.R.fillRect(context: context, rect: rect, color: accent.withAlphaComponent(0.06)) }
            },
            rowCell: { c, v, x, w, y, _ in
                let alignRight = (c == 2 || c == 3)
                self.R.draw(self.R.text(v, font: .systemFont(ofSize: 11), color: .black),
                            in: CGRect(x: x + 6, y: y + 2, width: w - 12, height: 18),
                            align: alignRight ? .right : .left)
            },
            rowH: 24, headerH: 20, continuationNoteColor: accent
        )

        guard !res.hasMore else { return }

        // Итоги
        let subtotal = R.subtotal(invoice.items)
        R.strokeLine(context: context, from: CGPoint(x: left, y: res.lastY + 6), to: CGPoint(x: right, y: res.lastY + 6), color: primary.withAlphaComponent(0.4), width: 1)

        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 11), color: .darkGray),
               in: CGRect(x: right - 180, y: res.lastY + 12, width: 100, height: 18), align: .right)
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 11), color: .black),
               in: CGRect(x: right - 80, y: res.lastY + 12, width: 80, height: 18), align: .right)

        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 14, weight: .bold), color: primary),
               in: CGRect(x: right - 180, y: res.lastY + 34, width: 100, height: 22), align: .right)
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 14, weight: .bold), color: primary),
               in: CGRect(x: right - 80, y: res.lastY + 34, width: 80, height: 22), align: .right)

        // Инструкции и заметки (слева)
        var infoTop = res.lastY + 18
        if let pi = extractPaymentInfo(from: invoice) {
            let box = CGRect(x: left, y: infoTop, width: right - left - 220, height: 70)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.3), width: 1)
            R.draw(R.text("PAYMENT INSTRUCTIONS", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 16))
            R.draw(R.text(pi, font: .systemFont(ofSize: 11), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: 48))
            infoTop = box.maxY + 8
        }
        if let notes = invoice.paymentNotes, !notes.isEmpty {
            let box = CGRect(x: left, y: infoTop, width: right - left - 220, height: 70)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.3), width: 1)
            R.draw(R.text("NOTES", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 16))
            R.draw(R.text(notes, font: .systemFont(ofSize: 11), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: 48))
        }

        // Footer — дженерик
        let fy = page.height - P.bottom
        R.draw(R.text("Thank you for your business.", font: .systemFont(ofSize: 10), color: .gray),
               in: CGRect(x: left, y: fy - 14, width: right - left, height: 14), align: .left)
    }
}

// MARK: - Fashion Elegant Template (унифицирован)

struct FashionElegantTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let accent = theme.accent

        R.fillRect(context: context, rect: page, color: .white)

        // Заголовок по центру
        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 28, weight: .bold), color: .black),
               in: CGRect(x: left, y: P.top, width: right - left, height: 36), align: .center)

        // Компания слева + Лого справа
        var cy = P.top + 44
        for (i, line) in companyLines(company).enumerated() {
            let f: UIFont = (i == 0) ? .systemFont(ofSize: 16, weight: .semibold) : .systemFont(ofSize: 12, weight: .regular)
            R.draw(R.text(line, font: f, color: .black),
                   in: CGRect(x: left, y: cy, width: right - left - 120, height: i == 0 ? 20 : 16))
            cy += (i == 0 ? 22 : 18)
        }
        R.drawLogo(logo, in: CGRect(x: right - 56, y: P.top + 8, width: 48, height: 48), context: context, corner: 0, stroke: nil)

        // Bill To / Invoice meta
        let top = max(cy, P.top + 86)
        let mid = (left + right) / 2 + 10

        R.draw(R.text("Bill To", font: .systemFont(ofSize: 12, weight: .semibold), color: .black),
               in: CGRect(x: left, y: top, width: 200, height: 16))
        let bill = [customer.name, customer.address.oneLine, customer.email].filter{!$0.isEmpty}
        var by = top + 18
        for s in bill {
            R.draw(R.text(s, font: .systemFont(ofSize: 12), color: .black),
                   in: CGRect(x: left, y: by, width: 260, height: 18))
            by += 18
        }

        R.draw(R.text("Invoice No :", font: .systemFont(ofSize: 12, weight: .semibold), color: .black),
               in: CGRect(x: mid, y: top, width: 120, height: 16))
        R.draw(R.text(invoice.number, font: .systemFont(ofSize: 12), color: .black),
               in: CGRect(x: mid + 120, y: top, width: 160, height: 16))

        let df = BaseRenderer.date
        R.draw(R.text("Invoice Date :", font: .systemFont(ofSize: 12, weight: .semibold), color: .black),
               in: CGRect(x: mid, y: top + 20, width: 120, height: 16))
        R.draw(R.text(df.string(from: invoice.issueDate), font: .systemFont(ofSize: 12), color: .black),
               in: CGRect(x: mid + 120, y: top + 20, width: 160, height: 16))

        // Разделительная линия
        R.strokeLine(context: context, from: CGPoint(x: left, y: by + 12), to: CGPoint(x: right, y: by + 12), color: .lightGray, width: 1)

        // Таблица — синяя шапка
        let tableTop = by + 24
        let headers = ["Sl.", "Description", "Qty", "Rate", "Amount"]
        let widths: [CGFloat] = [50, (right-left) - 50 - 80 - 120 - 120, 80, 120, 120]
        R.fillRect(context: context, rect: CGRect(x: left, y: tableTop, width: right - left, height: 28), color: primary)

        var x = left
        for (i, h) in headers.enumerated() {
            R.draw(R.text(h, font: .systemFont(ofSize: 12, weight: .semibold), color: .white),
                   in: CGRect(x: x + 8, y: tableTop + 6, width: widths[i] - 16, height: 16))
            x += widths[i]
        }

        // Ряды
        var rowY = tableTop + 28
        for (index, it) in invoice.items.enumerated() {
            R.strokeLine(context: context, from: CGPoint(x: left, y: rowY), to: CGPoint(x: right, y: rowY), color: UIColor(white: 0.9, alpha: 1), width: 0.6)
            x = left
            R.draw(R.text("\(index+1)", font: .systemFont(ofSize: 12), color: .black),
                   in: CGRect(x: x + 8, y: rowY + 6, width: widths[0] - 16, height: 16))
            x += widths[0]
            R.draw(R.text(it.description, font: .systemFont(ofSize: 12), color: .black),
                   in: CGRect(x: x + 8, y: rowY + 6, width: widths[1] - 16, height: 16))
            x += widths[1]
            R.draw(R.text("\(it.quantity)", font: .systemFont(ofSize: 12), color: .black),
                   in: CGRect(x: x + 8, y: rowY + 6, width: widths[2] - 16, height: 16))
            x += widths[2]
            R.draw(R.text(R.cur(it.rate, code: currency), font: .systemFont(ofSize: 12), color: .black),
                   in: CGRect(x: x, y: rowY + 6, width: widths[3] - 8, height: 16), align: .right)
            x += widths[3]
            R.draw(R.text(R.cur(it.total, code: currency), font: .systemFont(ofSize: 12, weight: .semibold), color: .black),
                   in: CGRect(x: x, y: rowY + 6, width: widths[4] - 8, height: 16), align: .right)
            rowY += 28
        }
        R.strokeLine(context: context, from: CGPoint(x: left, y: rowY), to: CGPoint(x: right, y: rowY), color: .lightGray, width: 1)

        // Сводка справа
        let subtotal = R.subtotal(invoice.items)
        let boxX = right - 260
        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 12), color: .black),
               in: CGRect(x: boxX, y: rowY + 12, width: 120, height: 18))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 12), color: .black),
               in: CGRect(x: right - 120, y: rowY + 12, width: 120, height: 18), align: .right)

        R.draw(R.text("Total", font: .systemFont(ofSize: 14, weight: .semibold), color: .black),
               in: CGRect(x: boxX, y: rowY + 36, width: 120, height: 20))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 14, weight: .semibold), color: .black),
               in: CGRect(x: right - 120, y: rowY + 36, width: 120, height: 20), align: .right)

        R.strokeLine(context: context, from: CGPoint(x: boxX, y: rowY + 62), to: CGPoint(x: right, y: rowY + 62), color: .lightGray, width: 1)

        // Инструкции оплаты
        var infoTop = rowY + 20
        if let pi = extractPaymentInfo(from: invoice) {
            R.draw(R.text("PAYMENT INSTRUCTIONS", font: .systemFont(ofSize: 12, weight: .semibold), color: .black),
                   in: CGRect(x: left, y: infoTop, width: 300, height: 18))
            R.draw(R.text(pi, font: .systemFont(ofSize: 12), color: .darkGray),
                   in: CGRect(x: left, y: infoTop + 18, width: right - left, height: 60))
            infoTop += 82
        }
        if let notes = invoice.paymentNotes, !notes.isEmpty {
            R.draw(R.text("NOTES", font: .systemFont(ofSize: 12, weight: .semibold), color: .black),
                   in: CGRect(x: left, y: infoTop, width: 300, height: 18))
            R.draw(R.text(notes, font: .systemFont(ofSize: 12), color: .darkGray),
                   in: CGRect(x: left, y: infoTop + 18, width: right - left, height: 60))
        }

        // Footer — дженерик
        let fy = page.height - P.bottom
        R.draw(R.text("Thank you for your business.", font: .systemFont(ofSize: 10), color: .gray),
               in: CGRect(x: left, y: fy - 14, width: right - left, height: 14))
    }
}

// MARK: - Design Studio Template (унифицирован) — ИСПРАВЛЕНО: многострочный блок компании

struct DesignStudioTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let accent = theme.accent

        R.fillRect(context: context, rect: page, color: .white)

        // Верхняя панель: логотип + многострочный блок компании + номер справа
        R.drawLogo(logo, in: CGRect(x: left, y: P.top, width: 72, height: 72), context: context, corner: 0, stroke: nil)

        let compX = left + 88
        let compW = (right - compX) - 200
        var cy = P.top + 6
        for (i, line) in companyLines(company).enumerated() {
            let f: UIFont = (i == 0) ? .systemFont(ofSize: 20, weight: .semibold) : .systemFont(ofSize: 11, weight: .regular)
            let col: UIColor = (i == 0) ? primary : .black
            R.draw(R.text(line, font: f, color: col),
                   in: CGRect(x: compX, y: cy, width: compW, height: i == 0 ? 22 : 16))
            cy += (i == 0 ? 22 : 16)
            if cy > P.top + 72 { break } // ограничиваем по высоте блока логотипа
        }

        R.draw(R.text("Invoice \(invoice.number)", font: .systemFont(ofSize: 16, weight: .bold), color: .black),
               in: CGRect(x: right - 180, y: P.top + 10, width: 180, height: 20), align: .right)

        // Оранжевые карточки мета-инфо
        let df = BaseRenderer.date
        let due = extractDueDate(from: invoice) ?? invoice.issueDate
        let cardH: CGFloat = 48
        let labels = ["Invoice No.", "Issue date", "Due date", "Total due (\(currency))"]
        let values = [
            invoice.number,
            df.string(from: invoice.issueDate),
            df.string(from: due),
            R.cur(R.subtotal(invoice.items), code: currency)
        ]
        let cardW = (right - left) / 4 - 6
        for i in 0..<4 {
            let x = left + CGFloat(i) * (cardW + 8)
            let r = CGRect(x: x, y: P.top + 90, width: cardW, height: cardH)
            let fill = UIColor.systemOrange.withAlphaComponent(i == 3 ? 0.9 : 0.75)
            R.fillRect(context: context, rect: r, color: fill)
            R.draw(R.text(labels[i], font: .systemFont(ofSize: 11, weight: .semibold), color: .white),
                   in: CGRect(x: r.minX + 10, y: r.minY + 6, width: r.width - 20, height: 16))
            R.draw(R.text(values[i], font: .systemFont(ofSize: 14, weight: .bold), color: .white),
                   in: CGRect(x: r.minX + 10, y: r.minY + 22, width: r.width - 20, height: 20))
        }

        // BILL TO слева
        R.draw(R.text("BILL TO", font: .systemFont(ofSize: 12, weight: .semibold), color: primary),
               in: CGRect(x: left, y: P.top + 160, width: 200, height: 16))
        let bill = [customer.name, customer.address.oneLine, customer.email].filter{!$0.isEmpty}
        var by = P.top + 178
        for s in bill {
            R.draw(R.text(s, font: .systemFont(ofSize: 12), color: .black),
                   in: CGRect(x: left, y: by, width: right - left - 220, height: 18))
            by += 18
        }

        // Таблица
        let tTop: CGFloat = P.top + 230
        R.strokeLine(context: context, from: CGPoint(x: left, y: tTop), to: CGPoint(x: right, y: tTop), color: .lightGray, width: 1)
        let headers = ["Description", "Quantity", "Unit price (\(currency))", "Amount (\(currency))"]
        let specs: [CGFloat] = [0.56, 0.14, 0.15, 0.15]

        let res = R.drawTablePaged(
            context: context, page: page,
            left: left, right: right, top: tTop + 4, safeBottom: P.bottom,
            headers: headers, colSpecs: specs, items: invoice.items, currencyCode: currency,
            headerBg: { _ in }, // только тонкая линия сверху
            headerCell: { _, t, x, w, top, _ in
                self.R.draw(self.R.text(t, font: .systemFont(ofSize: 12, weight: .semibold), color: .darkGray),
                            in: CGRect(x: x + 8, y: top + 2, width: w - 16, height: 18))
            },
            rowBg: { i, rect in
                if i % 2 == 1 { self.R.fillRect(context: context, rect: rect, color: UIColor(white: 0.97, alpha: 1)) }
            },
            rowCell: { c, v, x, w, y, _ in
                let rightAlign = (c == 1 || c == 2 || c == 3)
                let isAmount = (c == 3)
                self.R.draw(self.R.text(v, font: .systemFont(ofSize: 12, weight: isAmount ? .semibold : .regular), color: .black),
                            in: CGRect(x: x + 8, y: y, width: w - 16, height: 18),
                            align: rightAlign ? .right : .left)
            },
            rowH: 24, headerH: 24, continuationNoteColor: accent
        )

        guard !res.hasMore else { return }

        // Итоговая тёмная плашка TOTAL справа
        let total = R.subtotal(invoice.items)
        let totalBox = CGRect(x: right - 260, y: res.lastY + 12, width: 260, height: 46)
        R.fillRect(context: context, rect: totalBox, color: UIColor(white: 0.2, alpha: 1))
        R.draw(R.text("TOTAL DUE (\(currency))", font: .systemFont(ofSize: 11, weight: .semibold), color: .white),
               in: CGRect(x: totalBox.minX + 12, y: totalBox.minY + 8, width: 150, height: 14))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 16, weight: .bold), color: .white),
               in: CGRect(x: totalBox.minX + 12, y: totalBox.minY + 22, width: totalBox.width - 24, height: 18), align: .right)

        // Инструкции/заметки слева
        var infoTop = res.lastY + 12
        if let pi = extractPaymentInfo(from: invoice) {
            let box = CGRect(x: left, y: infoTop, width: right - left - 280, height: 72)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.35), width: 1)
            R.draw(R.text("PAYMENT INSTRUCTIONS", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 16))
            R.draw(R.text(pi, font: .systemFont(ofSize: 11), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: 50))
            infoTop = box.maxY + 8
        }
        if let notes = invoice.paymentNotes, !notes.isEmpty {
            let box = CGRect(x: left, y: infoTop, width: right - left - 280, height: 72)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.35), width: 1)
            R.draw(R.text("NOTES", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 16))
            R.draw(R.text(notes, font: .systemFont(ofSize: 11), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: 50))
        }

        // Footer — дженерик
        let fy = page.height - P.bottom
        R.draw(R.text("Thank you for your business.", font: .systemFont(ofSize: 10), color: .gray),
               in: CGRect(x: left, y: fy - 14, width: right - left, height: 14))
    }
}

// MARK: - Artistic Bold Template (унифицирован) — ИСПРАВЛЕНО: многострочный блок компании

struct ArtisticBoldTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let accent = theme.accent

        // Фон
        R.fillRect(context: context, rect: page, color: .white)

        // Тёмный хедер с диагональным акцентом
        let header = CGRect(x: 0, y: 0, width: page.width, height: 120)
        R.fillRect(context: context, rect: header, color: UIColor(white: 0.12, alpha: 1))
        let stripe = UIBezierPath()
        stripe.move(to: CGPoint(x: page.width * 0.55, y: 0))
        stripe.addLine(to: CGPoint(x: page.width, y: 0))
        stripe.addLine(to: CGPoint(x: page.width, y: 120))
        stripe.addLine(to: CGPoint(x: page.width * 0.45, y: 120))
        stripe.close()
        accent.withAlphaComponent(0.6).setFill()
        stripe.fill()

        // Заголовок "INVOICE"
        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 28, weight: .black), color: .white),
               in: CGRect(x: left, y: 24, width: 260, height: 32))

        // Лого справа
        R.drawLogo(logo, in: CGRect(x: right - 70, y: 25, width: 45, height: 45), context: context, corner: 0, stroke: nil)

        // Многострочный блок компании на тёмном фоне
        let compMaxW = right - left - 160
        var chy = 58.0
        for (i, line) in companyLines(company).enumerated() {
            let f: UIFont = (i == 0) ? .systemFont(ofSize: 14, weight: .semibold)
                                     : .systemFont(ofSize: 13, weight: .regular)
            let col: UIColor = UIColor(white: 0.92, alpha: 1)
            R.draw(R.text(line, font: f, color: col),
                   in: CGRect(x: left, y: chy, width: compMaxW, height: i == 0 ? 20 : 18))
            chy += (i == 0 ? 20 : 18)
            if chy > header.maxY - 14 { break } // не вылезаем за тёмный хедер
        }

        // Метаданные справа под хедером
        let top = 136.0
        R.draw(R.text("Invoice #", font: .systemFont(ofSize: 12, weight: .semibold), color: .darkGray),
               in: CGRect(x: right - 220, y: top, width: 90, height: 16), align: .right)
        R.draw(R.text(invoice.number, font: .systemFont(ofSize: 12), color: .black),
               in: CGRect(x: right - 120, y: top, width: 120, height: 16), align: .right)

        let df = BaseRenderer.date
        R.draw(R.text("Date", font: .systemFont(ofSize: 12, weight: .semibold), color: .darkGray),
               in: CGRect(x: right - 220, y: top + 18, width: 90, height: 16), align: .right)
        R.draw(R.text(df.string(from: invoice.issueDate), font: .systemFont(ofSize: 12), color: .black),
               in: CGRect(x: right - 120, y: top + 18, width: 120, height: 16), align: .right)

        // Bill To (карточка)
        let billBox = CGRect(x: left, y: top, width: 300, height: 90)
        R.fillRect(context: context, rect: billBox, color: primary.withAlphaComponent(0.06))
        R.strokeRect(context: context, rect: billBox, color: primary, width: 1)
        R.draw(R.text("BILL TO", font: .systemFont(ofSize: 12, weight: .bold), color: primary),
               in: CGRect(x: billBox.minX + 10, y: billBox.minY + 8, width: billBox.width - 20, height: 16))
        let bill = [customer.name, customer.address.oneLine, customer.email].filter{!$0.isEmpty}
        var by = billBox.minY + 28
        for s in bill {
            R.draw(R.text(s, font: .systemFont(ofSize: 12), color: .black),
                   in: CGRect(x: billBox.minX + 10, y: by, width: billBox.width - 20, height: 18))
            by += 18
        }

        // Таблица — зебра
        let tTop = billBox.maxY + 20
        let headers = ["Description", "Qty", "Rate", "Amount"]
        let specs: [CGFloat] = [0.58, 0.12, 0.15, 0.15]

        let res = R.drawTablePaged(
            context: context, page: page,
            left: left, right: right, top: tTop, safeBottom: P.bottom,
            headers: headers, colSpecs: specs, items: invoice.items, currencyCode: currency,
            headerBg: { rect in
                self.R.fillRect(context: context, rect: rect, color: UIColor(white: 0.96, alpha: 1))
            },
            headerCell: { _, t, x, w, top, _ in
                self.R.draw(self.R.text(t, font: .systemFont(ofSize: 12, weight: .bold), color: .black),
                            in: CGRect(x: x + 8, y: top + 8, width: w - 16, height: 16))
            },
            rowBg: { i, rect in
                if i % 2 == 0 { self.R.fillRect(context: context, rect: rect, color: UIColor(white: 0.985, alpha: 1)) }
            },
            rowCell: { c, v, x, w, y, _ in
                let isQty = (c == 1)
                let isRate = (c == 2)
                let isAmt = (c == 3)
                let alignRight = isQty || isRate || isAmt
                let font = UIFont.systemFont(ofSize: 11, weight: isAmt ? .semibold : .regular)
                let color: UIColor = isAmt ? primary : .black
                self.R.draw(self.R.text(v, font: font, color: color),
                            in: CGRect(x: x + 8, y: y + 5, width: w - 16, height: 16),
                            align: alignRight ? .right : .left)
            },
            rowH: 26, headerH: 32, continuationNoteColor: accent
        )

        guard !res.hasMore else { return }

        // Карточка TOTAL справа
        let total = R.subtotal(invoice.items)
        let totalCard = CGRect(x: right - 240, y: res.lastY + 12, width: 240, height: 60)
        R.fillRect(context: context, rect: totalCard, color: primary)
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 13, weight: .bold), color: .white),
               in: CGRect(x: totalCard.minX + 12, y: totalCard.minY + 12, width: 100, height: 18))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 17, weight: .black), color: .white),
               in: CGRect(x: totalCard.minX + 12, y: totalCard.minY + 30, width: totalCard.width - 24, height: 22), align: .right)

        // Инструкции/заметки слева
        var infoTop = res.lastY + 12
        if let pi = extractPaymentInfo(from: invoice) {
            let box = CGRect(x: left, y: infoTop, width: right - left - 260, height: 74)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.35), width: 1)
            R.draw(R.text("PAYMENT INSTRUCTIONS", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 16))
            R.draw(R.text(pi, font: .systemFont(ofSize: 11), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: 52))
            infoTop = box.maxY + 8
        }
        if let notes = invoice.paymentNotes, !notes.isEmpty {
            let box = CGRect(x: left, y: infoTop, width: right - left - 260, height: 74)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.35), width: 1)
            R.draw(R.text("NOTES", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 16))
            R.draw(R.text(notes, font: .systemFont(ofSize: 11), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: 52))
        }

        // Footer — дженерик
        let fy = page.height - P.bottom
        R.draw(R.text("Thank you for your business.", font: .systemFont(ofSize: 10), color: .gray),
               in: CGRect(x: left, y: fy - 14, width: right - left, height: 14))
    }
}


struct CleanModernTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let accent = theme.accent
        let dateFmt = BaseRenderer.date
        let dueDate = extractDueDate(from: invoice) ?? invoice.issueDate

        R.fillRect(context: context, rect: page, color: .white)

        // Header band
        let headerH: CGFloat = 110
        let header = CGRect(x: 0, y: 0, width: page.width, height: headerH)
        R.fillRect(context: context, rect: header, color: primary.withAlphaComponent(0.06))

        // Logo
        let logoRect = CGRect(x: left, y: 20, width: 84, height: 84)
        R.drawLogo(logo, in: logoRect, context: context, corner: 12, stroke: primary.withAlphaComponent(0.15))

        // Company (all lines)
        let compX = logoRect.maxX + 14
        let compW = (right - compX) - 180
        var cy = CGFloat(24)
        for (i, line) in companyLines(company).enumerated() {
            let f: UIFont = (i == 0) ? .systemFont(ofSize: 26, weight: .black) : .systemFont(ofSize: 11, weight: .regular)
            let col: UIColor = (i == 0) ? primary : .black.withAlphaComponent(0.85)
            let h: CGFloat = (i == 0) ? 30 : 16
            R.draw(R.text(line, font: f, color: col, kern: i == 0 ? 0.4 : 0.2),
                   in: CGRect(x: compX, y: cy, width: compW, height: h))
            cy += h
            if cy > header.maxY - 8 { break }
        }

        // Invoice box (right)
        let inv = CGRect(x: right - 180, y: 28, width: 170, height: 78)
        R.fillRect(context: context, rect: inv, color: accent.withAlphaComponent(0.10))
        R.strokeRect(context: context, rect: inv, color: accent, width: 1)

        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 18, weight: .medium), color: accent),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 6, width: inv.width - 20, height: 18))
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 14, weight: .semibold), color: primary),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 26, width: inv.width - 20, height: 16))
        R.draw(R.text("Issue: \(dateFmt.string(from: invoice.issueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 44, width: inv.width - 20, height: 14))
        R.draw(R.text("Due:   \(dateFmt.string(from: dueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 60, width: inv.width - 20, height: 14))

        // BILL TO
        let bill = CGRect(x: left, y: header.maxY + 16, width: min(380, right - left), height: 102)
        R.fillRect(context: context, rect: bill, color: primary.withAlphaComponent(0.03))
        R.strokeRect(context: context, rect: bill, color: primary, width: 1)
        R.draw(R.text("BILL TO:", font: .systemFont(ofSize: 13, weight: .bold), color: primary),
               in: CGRect(x: bill.minX + 10, y: bill.minY + 8, width: bill.width - 20, height: 16))

        var by = bill.minY + 28
        for s in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(s, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: bill.minX + 10, y: by, width: bill.width - 20, height: 18))
            by += 18
        }

        // Table (paged)
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
                self.R.draw(self.R.text(t, font: .systemFont(ofSize: 12, weight: .bold), color: .white),
                            in: CGRect(x: x + 10, y: top + 9, width: w - 16, height: 18))
            },
            rowBg: { i, rect in if i % 2 == 0 {
                self.R.fillRect(context: context, rect: rect, color: UIColor.black.withAlphaComponent(0.04))
            }},
            rowCell: { _, v, x, w, y, _ in
                self.R.draw(self.R.text(v, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                            in: CGRect(x: x + 10, y: y + 6, width: w - 16, height: 18))
            },
            rowH: 28, headerH: 34,
            continuationNoteColor: accent
        )

        // If not last page — stop here
        guard res.hasMore == false else { return }

        // Totals (safe placement)
        let subtotal = R.subtotal(invoice.items)
        let totalsW: CGFloat = 220
        let tx = right - totalsW
        var ty = R.placeBlock(below: res.lastY + 10, desiredHeight: 72, page: page, safeBottom: P.bottom)

        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: tx, y: ty, width: 110, height: 16))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 11, weight: .semibold), color: .black),
               in: CGRect(x: tx + 110, y: ty, width: 110, height: 16))
        ty += 18

        R.strokeLine(context: context, from: CGPoint(x: tx, y: ty + 4), to: CGPoint(x: right, y: ty + 4), color: accent, width: 1)
        ty += 10

        let totalBar = CGRect(x: tx, y: ty, width: totalsW, height: 44)
        R.fillRect(context: context, rect: totalBar, color: accent)
        let total = subtotal
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 16, weight: .bold), color: .white),
               in: CGRect(x: totalBar.minX + 10, y: totalBar.minY + 10, width: 80, height: 22))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 16, weight: .bold), color: .white),
               in: CGRect(x: totalBar.minX + 96, y: totalBar.minY + 10, width: 110, height: 22))

        // Payment Info / Notes (left column)
        var infoTop = res.lastY + 10
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

// MARK: - Simple Minimal (refactored)

struct SimpleMinimalTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let accent = theme.accent
        let dateFmt = BaseRenderer.date
        let dueDate = extractDueDate(from: invoice) ?? invoice.issueDate

        R.fillRect(context: context, rect: page, color: .white)

        // Minimal header line
        R.strokeLine(context: context, from: CGPoint(x: left, y: P.top), to: CGPoint(x: right, y: P.top), color: primary.withAlphaComponent(0.4), width: 0.8)

        // Company lines (left)
        var cy = P.top + 10
        for (i, line) in companyLines(company).enumerated() {
            let f: UIFont = (i == 0) ? .systemFont(ofSize: 24, weight: .thin) : .systemFont(ofSize: 11, weight: .regular)
            R.draw(R.text(line, font: f, color: .black, kern: i == 0 ? 0.6 : 0.2),
                   in: CGRect(x: left, y: cy, width: right - left - 180, height: (i == 0) ? 26 : 16))
            cy += (i == 0) ? 28 : 16
            if cy > P.top + 62 { break }
        }

        // Invoice chip (right)
        let inv = CGRect(x: right - 170, y: P.top + 10, width: 160, height: 70)
        R.fillRect(context: context, rect: inv, color: accent.withAlphaComponent(0.10))
        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 14, weight: .medium), color: accent),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 6, width: inv.width - 20, height: 16))
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 12, weight: .regular), color: primary),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 24, width: inv.width - 20, height: 14))
        R.draw(R.text("Issue: \(dateFmt.string(from: invoice.issueDate))", font: .systemFont(ofSize: 10, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 40, width: inv.width - 20, height: 14))
        R.draw(R.text("Due:   \(dateFmt.string(from: dueDate))", font: .systemFont(ofSize: 10, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 54, width: inv.width - 20, height: 14))

        R.strokeLine(context: context, from: CGPoint(x: left, y: P.top + 88), to: CGPoint(x: right, y: P.top + 88), color: primary.withAlphaComponent(0.25), width: 0.6)

        // BILL TO
        let bill = CGRect(x: left, y: P.top + 102, width: min(380, right - left), height: 96)
        R.draw(R.text("BILL TO:", font: .systemFont(ofSize: 11, weight: .medium), color: primary),
               in: CGRect(x: bill.minX, y: bill.minY, width: bill.width, height: 14))

        var by = bill.minY + 18
        for s in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(s, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: left, y: by, width: bill.width, height: 16))
            by += 18
        }

        // Table
        let tableTop = by + 10
        let headers = ["Item", "Qty", "Rate", "Total"]
        let specs: [CGFloat] = [0.60, 0.12, 0.14, 0.14]

        let res = R.drawTablePaged(
            context: context, page: page,
            left: left, right: right, top: tableTop, safeBottom: P.bottom,
            headers: headers, colSpecs: specs, items: invoice.items,
            currencyCode: currency,
            headerBg: { _ in },
            headerCell: { _, h, x, w, top, _ in
                self.R.draw(self.R.text(h, font: .systemFont(ofSize: 10, weight: .light), color: .gray, kern: 0.4),
                            in: CGRect(x: x, y: top, width: w, height: 16))
                self.R.strokeLine(context: context, from: CGPoint(x: left, y: top + 18), to: CGPoint(x: right, y: top + 18), color: accent, width: 0.6)
            },
            rowBg: { _, _ in },
            rowCell: { _, t, x, w, y, _ in
                self.R.draw(self.R.text(t, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                            in: CGRect(x: x, y: y + 4, width: w, height: 18))
            },
            rowH: 24, headerH: 22,
            continuationNoteColor: accent
        )

        guard res.hasMore == false else { return }

        // Totals
        let subtotal = R.subtotal(invoice.items)
        let totalsW: CGFloat = 180
        let tx = right - totalsW
        var ty = R.placeBlock(below: res.lastY + 8, desiredHeight: 56, page: page, safeBottom: P.bottom)

        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 10, weight: .light), color: .gray),
               in: CGRect(x: tx, y: ty, width: 90, height: 16))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 10, weight: .regular), color: .black),
               in: CGRect(x: tx + 90, y: ty, width: 90, height: 16))
        ty += 14

        R.strokeLine(context: context, from: CGPoint(x: tx, y: ty + 4), to: CGPoint(x: right, y: ty + 4), color: accent, width: 0.6)
        ty += 8

        let totalBar = CGRect(x: tx, y: ty, width: totalsW, height: 36)
        R.fillRect(context: context, rect: totalBar, color: accent)
        let total = subtotal
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 14, weight: .medium), color: .white),
               in: CGRect(x: totalBar.minX + 8, y: totalBar.minY + 8, width: 80, height: 18))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 14, weight: .medium), color: .white),
               in: CGRect(x: totalBar.minX + 88, y: totalBar.minY + 8, width: 84, height: 18))

        // Payment / Notes
        var infoTop = res.lastY + 8
        let infoWidth = (tx - left) - 16
        if let pi = extractPaymentInfo(from: invoice) {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 68)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.25), width: 1)
            R.draw(R.text("PAYMENT INSTRUCTIONS", font: .systemFont(ofSize: 10, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 12))
            R.draw(R.text(pi, font: .systemFont(ofSize: 10, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 20, width: box.width - 16, height: 44))
            infoTop = box.maxY + 8
        }
        if let notes = invoice.paymentNotes, !notes.isEmpty {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 68)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.25), width: 1)
            R.draw(R.text("NOTES", font: .systemFont(ofSize: 10, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 12))
            R.draw(R.text(notes, font: .systemFont(ofSize: 10, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 20, width: box.width - 16, height: 44))
        }

        // Footer
        let fy = page.height - P.bottom
        R.draw(R.text("Thank you.", font: .systemFont(ofSize: 9, weight: .light), color: .gray),
               in: CGRect(x: left, y: fy - 12, width: right - left, height: 12))
    }
}

// MARK: - Corporate Formal (refactored)

struct FixedCorporateFormalTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let accent = theme.accent
        let dateFmt = BaseRenderer.date
        let dueDate = extractDueDate(from: invoice) ?? invoice.issueDate

        R.fillRect(context: context, rect: page, color: .white)

        // Header box
        let headerRect = CGRect(x: left, y: P.top, width: right - left, height: 100)
        R.fillRect(context: context, rect: headerRect, color: primary.withAlphaComponent(0.05))
        R.strokeRect(context: context, rect: headerRect, color: primary, width: 1.5)

        // Logo
        let logoRect = CGRect(x: headerRect.minX + 14, y: headerRect.minY + 14, width: 68, height: 68)
        R.drawLogo(logo, in: logoRect, context: context, corner: 8, stroke: primary.withAlphaComponent(0.5))

        // Company (all lines)
        let compX = logoRect.maxX + 14
        let compW = headerRect.width - 180 - (compX - headerRect.minX)
        var cy = headerRect.minY + 16
        for (i, line) in companyLines(company).enumerated() {
            let f: UIFont = (i == 0) ? .systemFont(ofSize: 24, weight: .black) : .systemFont(ofSize: 11, weight: .regular)
            let col: UIColor = (i == 0) ? primary : .black
            R.draw(R.text(line, font: f, color: col),
                   in: CGRect(x: compX, y: cy, width: compW, height: i == 0 ? 26 : 16))
            cy += (i == 0 ? 26 : 16)
            if cy > headerRect.maxY - 8 { break }
        }

        // Invoice box (right)
        let inv = CGRect(x: headerRect.maxX - 180, y: headerRect.minY + 12, width: 170, height: 76)
        R.fillRect(context: context, rect: inv, color: primary.withAlphaComponent(0.08))
        R.strokeRect(context: context, rect: inv, color: primary, width: 1)
        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 18, weight: .black), color: primary),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 6, width: inv.width - 20, height: 20))
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 12, weight: .semibold), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 26, width: inv.width - 20, height: 16))
        R.draw(R.text("Issue: \(dateFmt.string(from: invoice.issueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 44, width: inv.width - 20, height: 14))
        R.draw(R.text("Due:   \(dateFmt.string(from: dueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 60, width: inv.width - 20, height: 14))

        R.strokeLine(context: context,
                     from: CGPoint(x: headerRect.minX, y: headerRect.maxY + 12),
                     to: CGPoint(x: headerRect.maxX, y: headerRect.maxY + 12),
                     color: accent, width: 1)

        // BILL TO
        let billRect = CGRect(x: headerRect.minX, y: headerRect.maxY + 24, width: min(360, right - left), height: 96)
        R.fillRect(context: context, rect: billRect, color: primary.withAlphaComponent(0.03))
        R.strokeRect(context: context, rect: billRect, color: primary, width: 1)
        R.draw(R.text("BILL TO", font: .systemFont(ofSize: 11, weight: .bold), color: primary),
               in: CGRect(x: billRect.minX + 10, y: billRect.minY + 8, width: billRect.width - 20, height: 16))
        var by = billRect.minY + 28
        for s in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(s, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: billRect.minX + 10, y: by, width: billRect.width - 20, height: 18))
            by += 18
        }

        // Table
        let tableTop = billRect.maxY + 14
        let headers = ["Description", "Quantity", "Unit Price", "Amount"]
        let specs: [CGFloat] = [0.58, 0.12, 0.14, 0.16]

        let res = R.drawTablePaged(
            context: context, page: page,
            left: left, right: right, top: tableTop, safeBottom: P.bottom,
            headers: headers, colSpecs: specs, items: invoice.items,
            currencyCode: currency,
            headerBg: { rect in self.R.fillRect(context: context, rect: rect, color: primary) },
            headerCell: { _, t, x, w, top, _ in
                self.R.draw(self.R.text(t, font: .systemFont(ofSize: 12, weight: .bold), color: .white),
                            in: CGRect(x: x + 12, y: top + 9, width: w - 16, height: 18))
            },
            rowBg: { i, rect in if i % 2 == 0 { self.R.fillRect(context: context, rect: rect, color: primary.withAlphaComponent(0.03)) } },
            rowCell: { _, v, x, w, y, _ in
                self.R.draw(self.R.text(v, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                            in: CGRect(x: x + 12, y: y + 6, width: w - 16, height: 18))
            },
            rowH: 30, headerH: 36,
            continuationNoteColor: accent
        )

        guard res.hasMore == false else { return }

        // Totals
        let subtotal = R.subtotal(invoice.items)
        let totalsW: CGFloat = 240
        let tx = right - totalsW
        var ty = R.placeBlock(below: res.lastY + 10, desiredHeight: 78, page: page, safeBottom: P.bottom)

        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: tx, y: ty, width: 120, height: 16))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 11, weight: .semibold), color: .black),
               in: CGRect(x: tx + 120, y: ty, width: 120, height: 16))
        ty += 18

        R.strokeLine(context: context, from: CGPoint(x: tx, y: ty + 4), to: CGPoint(x: right, y: ty + 4), color: accent, width: 1)
        ty += 10

        let totalBar = CGRect(x: tx, y: ty, width: totalsW, height: 46)
        R.fillRect(context: context, rect: totalBar, color: primary)
        let total = subtotal
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 16, weight: .bold), color: .white),
               in: CGRect(x: totalBar.minX + 10, y: totalBar.minY + 10, width: 90, height: 22))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 16, weight: .bold), color: .white),
               in: CGRect(x: totalBar.minX + 110, y: totalBar.minY + 10, width: 120, height: 22))

        // Payment / Notes
        var infoTop = res.lastY + 10
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
        R.draw(R.text("Thank you for your business. Payment terms: Net 30 days.", font: .systemFont(ofSize: 10, weight: .regular), color: .gray),
               in: CGRect(x: left, y: fy - 14, width: right - left, height: 14))
    }
}

// MARK: - Creative Vibrant (refactored)

struct FixedCreativeVibrantTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let accent = theme.accent
        let dateFmt = BaseRenderer.date
        let dueDate = extractDueDate(from: invoice) ?? invoice.issueDate

        R.fillRect(context: context, rect: page, color: .white)

        // Decorative header
        let header = CGRect(x: 0, y: 0, width: page.width, height: 120)
        R.fillRect(context: context, rect: header, color: primary.withAlphaComponent(0.12))
        R.fillRect(context: context, rect: CGRect(x: 0, y: header.height/2, width: page.width, height: header.height/2), color: accent.withAlphaComponent(0.08))

        // playful dots
        context.setFillColor(accent.withAlphaComponent(0.25).cgColor)
        for i in 0..<6 {
            let d: CGFloat = 18
            context.fillEllipse(in: CGRect(x: CGFloat(24 + i*60), y: 24 + CGFloat(i % 2)*10, width: d, height: d))
        }

        // Logo + company
        let logoRect = CGRect(x: left, y: 34, width: 54, height: 54)
        R.drawLogo(logo, in: logoRect, context: context, corner: 27, stroke: accent)

        let compX = logoRect.maxX + 14
        let compW = (right - compX) - 170
        var cy = CGFloat(32)
        for (i, line) in companyLines(company).enumerated() {
            let f: UIFont = (i == 0) ? .systemFont(ofSize: 24, weight: .black) : .systemFont(ofSize: 11, weight: .regular)
            let col: UIColor = (i == 0) ? primary : .black
            R.draw(R.text(line, font: f, color: col),
                   in: CGRect(x: compX, y: cy, width: compW, height: i == 0 ? 26 : 16))
            cy += (i == 0 ? 26 : 16)
            if cy > header.maxY - 8 { break }
        }

        // Invoice box
        let inv = CGRect(x: right - 170, y: 36, width: 160, height: 74)
        R.fillRect(context: context, rect: inv, color: accent.withAlphaComponent(0.12))
        R.strokeRect(context: context, rect: inv, color: accent, width: 1)
        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 16, weight: .bold), color: accent),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 6, width: inv.width - 20, height: 18))
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 13, weight: .semibold), color: primary),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 24, width: inv.width - 20, height: 16))
        R.draw(R.text("Issue: \(dateFmt.string(from: invoice.issueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 42, width: inv.width - 20, height: 14))
        R.draw(R.text("Due:   \(dateFmt.string(from: dueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 56, width: inv.width - 20, height: 14))

        // BILL TO chip
        let bill = CGRect(x: left, y: header.maxY + 16, width: min(380, right - left), height: 96)
        R.fillRect(context: context, rect: CGRect(x: bill.minX, y: bill.minY, width: 64, height: 22), color: primary.withAlphaComponent(0.1))
        R.draw(R.text("BILL TO", font: .systemFont(ofSize: 11, weight: .bold), color: primary),
               in: CGRect(x: bill.minX + 8, y: bill.minY + 3, width: 56, height: 16))
        var by = bill.minY + 28
        for s in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(s, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: bill.minX, y: by, width: bill.width, height: 18))
            by += 18
        }

        // Table
        let tableTop = by + 12
        let headers = ["Item", "Qty", "Rate", "Total"]
        let specs: [CGFloat] = [0.55, 0.13, 0.14, 0.18]

        let res = R.drawTablePaged(
            context: context, page: page,
            left: left, right: right, top: tableTop, safeBottom: P.bottom,
            headers: headers, colSpecs: specs, items: invoice.items,
            currencyCode: currency,
            headerBg: { rect in self.R.fillRect(context: context, rect: rect, color: accent) },
            headerCell: { _, t, x, w, top, _ in
                self.R.draw(self.R.text(t, font: .systemFont(ofSize: 11, weight: .bold), color: .white),
                            in: CGRect(x: x + 10, y: top + 9, width: w - 14, height: 16))
            },
            rowBg: { i, rect in if i % 2 == 0 { self.R.fillRect(context: context, rect: rect, color: primary.withAlphaComponent(0.06)) } },
            rowCell: { c, v, x, w, y, _ in
                let f = (c == 3) ? UIFont.systemFont(ofSize: 11, weight: .bold) : UIFont.systemFont(ofSize: 11, weight: .medium)
                let col: UIColor = (c == 3) ? primary : .black
                self.R.draw(self.R.text(v, font: f, color: col),
                            in: CGRect(x: x + 10, y: y + 6, width: w - 14, height: 18))
            },
            rowH: 26, headerH: 34,
            continuationNoteColor: accent
        )

        guard res.hasMore == false else { return }

        // Totals
        let subtotal = R.subtotal(invoice.items)
        let totalsW: CGFloat = 200
        let tx = right - totalsW
        var ty = R.placeBlock(below: res.lastY + 10, desiredHeight: 66, page: page, safeBottom: P.bottom)

        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: tx, y: ty, width: 100, height: 16))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 11, weight: .semibold), color: .black),
               in: CGRect(x: tx + 100, y: ty, width: 100, height: 16))
        ty += 18

        R.strokeLine(context: context, from: CGPoint(x: tx, y: ty + 4), to: CGPoint(x: right, y: ty + 4), color: accent, width: 1)
        ty += 8

        let totalBar = CGRect(x: tx, y: ty, width: totalsW, height: 40)
        R.fillRect(context: context, rect: totalBar, color: accent)
        let total = subtotal
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 15, weight: .bold), color: .white),
               in: CGRect(x: totalBar.minX + 10, y: totalBar.minY + 9, width: 90, height: 20))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 15, weight: .bold), color: .white),
               in: CGRect(x: totalBar.minX + 100, y: totalBar.minY + 9, width: 100, height: 20))

        // Payment / Notes
        var infoTop = res.lastY + 10
        let infoWidth = (tx - left) - 16
        if let pi = extractPaymentInfo(from: invoice) {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 72)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.3), width: 1)
            R.draw(R.text("PAYMENT INSTRUCTIONS", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 14))
            R.draw(R.text(pi, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: 50))
            infoTop = box.maxY + 10
        }
        if let notes = invoice.paymentNotes, !notes.isEmpty {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 72)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.3), width: 1)
            R.draw(R.text("NOTES", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 14))
            R.draw(R.text(notes, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: 50))
        }

        // Footer
        let fy = page.height - P.bottom
        R.draw(R.text("✨ Thank you for choosing our creative services! ✨", font: .systemFont(ofSize: 9, weight: .regular), color: .gray),
               in: CGRect(x: left, y: fy - 14, width: right - left, height: 14))
    }
}

// MARK: - Executive Luxury (refactored)

struct FixedExecutiveLuxuryTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let accent = theme.accent
        let dateFmt = BaseRenderer.date
        let dueDate = extractDueDate(from: invoice) ?? invoice.issueDate

        R.fillRect(context: context, rect: page, color: .white)

        // Lux frame header
        let header = CGRect(x: 0, y: 0, width: page.width, height: 130)
        R.fillRect(context: context, rect: header, color: primary.withAlphaComponent(0.05))
        R.strokeRect(context: context, rect: header, color: accent, width: 3)

        R.drawLogo(logo, in: CGRect(x: left + 8, y: 26, width: 78, height: 78), context: context, corner: 12, stroke: accent)

        // Company
        let compX = left + 100
        let compW = page.width - compX - 190
        var cy = CGFloat(38)
        for (i, line) in companyLines(company).enumerated() {
            let f: UIFont = (i == 0) ? .systemFont(ofSize: 28, weight: .bold) : .systemFont(ofSize: 12, weight: .medium)
            let col: UIColor = (i == 0) ? primary : .black
            R.draw(R.text(line, font: f, color: col),
                   in: CGRect(x: compX, y: cy, width: compW, height: i == 0 ? 32 : 18))
            cy += (i == 0 ? 34 : 18)
            if cy > header.maxY - 8 { break }
        }

        // Invoice panel (right)
        let metaX = right - 170
        let inv = CGRect(x: metaX, y: 38, width: 160, height: 74)
        R.fillRect(context: context, rect: inv, color: accent.withAlphaComponent(0.12))
        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 18, weight: .bold), color: accent),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 6, width: inv.width - 20, height: 20))
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 14, weight: .semibold), color: primary),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 26, width: inv.width - 20, height: 16))
        R.draw(R.text("Issue: \(dateFmt.string(from: invoice.issueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 44, width: inv.width - 20, height: 14))
        R.draw(R.text("Due:   \(dateFmt.string(from: dueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 60, width: inv.width - 20, height: 14))

        // BILL TO
        let bill = CGRect(x: left, y: header.maxY + 20, width: 360, height: 96)
        R.fillRect(context: context, rect: bill, color: primary.withAlphaComponent(0.03))
        R.strokeRect(context: context, rect: bill, color: primary, width: 1.2)
        R.draw(R.text("BILL TO:", font: .systemFont(ofSize: 14, weight: .bold), color: primary),
               in: CGRect(x: bill.minX + 12, y: bill.minY + 10, width: bill.width - 24, height: 20))
        var by = bill.minY + 32
        for s in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(s, font: .systemFont(ofSize: 13, weight: .medium), color: .black),
                   in: CGRect(x: bill.minX + 12, y: by, width: bill.width - 24, height: 18))
            by += 20
        }

        // Table
        let top = bill.maxY + 18
        let headers = ["Description", "Qty", "Unit Price", "Total"]
        let specs: [CGFloat] = [0.55, 0.15, 0.15, 0.15]

        let res = R.drawTablePaged(
            context: context, page: page,
            left: left, right: right, top: top, safeBottom: P.bottom,
            headers: headers, colSpecs: specs, items: invoice.items,
            currencyCode: currency,
            headerBg: { rect in self.R.fillRect(context: context, rect: rect, color: primary) },
            headerCell: { _, t, x, w, top, _ in
                self.R.draw(self.R.text(t, font: .systemFont(ofSize: 12, weight: .bold), color: .white),
                            in: CGRect(x: x + 12, y: top + 10, width: w - 16, height: 18))
            },
            rowBg: { i, rect in if i % 2 == 0 { self.R.fillRect(context: context, rect: rect, color: accent.withAlphaComponent(0.06)) } },
            rowCell: { c, v, x, w, y, _ in
                let font = (c == 3) ? UIFont.systemFont(ofSize: 12, weight: .bold) : UIFont.systemFont(ofSize: 12, weight: .medium)
                let col = (c == 3) ? accent : .black
                self.R.draw(self.R.text(v, font: font, color: col),
                            in: CGRect(x: x + 12, y: y + 8, width: w - 16, height: 18))
            },
            rowH: 32, headerH: 36,
            continuationNoteColor: accent
        )

        guard res.hasMore == false else { return }

        // Totals
        let subtotal = R.subtotal(invoice.items)
        let totalsW: CGFloat = 220
        let tx = right - totalsW
        var ty = R.placeBlock(below: res.lastY + 12, desiredHeight: 80, page: page, safeBottom: P.bottom)

        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: tx, y: ty, width: 110, height: 16))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 11, weight: .semibold), color: .black),
               in: CGRect(x: tx + 110, y: ty, width: 110, height: 16))
        ty += 18

        R.strokeLine(context: context, from: CGPoint(x: tx, y: ty + 4), to: CGPoint(x: right, y: ty + 4), color: accent, width: 1)
        ty += 10

        let bar = CGRect(x: tx, y: ty, width: totalsW, height: 48)
        R.fillRect(context: context, rect: bar, color: accent)
        let total = subtotal
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 16, weight: .bold), color: .white),
               in: CGRect(x: bar.minX + 10, y: bar.minY + 12, width: 90, height: 22))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 16, weight: .bold), color: .white),
               in: CGRect(x: bar.minX + 110, y: bar.minY + 12, width: 100, height: 22))

        // Payment / Notes
        var infoTop = res.lastY + 12
        let infoWidth = (tx - left) - 16
        if let pi = extractPaymentInfo(from: invoice) {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 80)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.35), width: 1)
            R.draw(R.text("PAYMENT INSTRUCTIONS", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 14))
            R.draw(R.text(pi, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: 56))
            infoTop = box.maxY + 10
        }
        if let notes = invoice.paymentNotes, !notes.isEmpty {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 80)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.35), width: 1)
            R.draw(R.text("NOTES", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 14))
            R.draw(R.text(notes, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: 56))
        }

        // Footer
        let fy = page.height - P.bottom
        R.draw(R.text("Thank you for your business. Premium service guaranteed.", font: .systemFont(ofSize: 10, weight: .regular), color: .gray),
               in: CGRect(x: left, y: fy - 14, width: right - left, height: 14))
    }
}

// MARK: - Tech Modern (refactored)

struct FixedTechModernTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let accent = theme.accent
        let dateFmt = BaseRenderer.date
        let dueDate = extractDueDate(from: invoice) ?? invoice.issueDate

        R.fillRect(context: context, rect: page, color: .white)

        // Tech header bars
        let header = CGRect(x: 0, y: 0, width: page.width, height: 118)
        R.fillRect(context: context, rect: header, color: primary.withAlphaComponent(0.08))
        context.setFillColor(accent.withAlphaComponent(0.16).cgColor)
        for i in 0..<5 {
            let w: CGFloat = 56
            context.fill(CGRect(x: CGFloat(20 + i*110), y: 0, width: w, height: header.height))
        }

        // Logo + Company
        R.drawLogo(logo, in: CGRect(x: left, y: 28, width: 60, height: 60), context: context, corner: 10, stroke: .white)
        let compX = left + 76
        let compW = page.width - compX - 190
        var cy = CGFloat(34)
        for (i, line) in companyLines(company).enumerated() {
            let f: UIFont = (i == 0) ? .systemFont(ofSize: 24, weight: .bold) : .systemFont(ofSize: 12, weight: .regular)
            let col: UIColor = (i == 0) ? primary : .black
            R.draw(R.text(line, font: f, color: col),
                   in: CGRect(x: compX, y: cy, width: compW, height: i == 0 ? 26 : 18))
            cy += (i == 0 ? 28 : 18)
            if cy > header.maxY - 8 { break }
        }

        // Invoice block
        let metaX = right - 170
        let inv = CGRect(x: metaX, y: 34, width: 160, height: 70)
        R.fillRect(context: context, rect: inv, color: accent.withAlphaComponent(0.12))
        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 16, weight: .bold), color: accent),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 6, width: inv.width - 20, height: 18))
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 14, weight: .semibold), color: primary),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 24, width: inv.width - 20, height: 16))
        R.draw(R.text("Issue: \(dateFmt.string(from: invoice.issueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 42, width: inv.width - 20, height: 14))
        R.draw(R.text("Due:   \(dateFmt.string(from: dueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 56, width: inv.width - 20, height: 14))

        // BILL TO
        let billTop = header.maxY + 18
        R.draw(R.text("BILL TO:", font: .systemFont(ofSize: 13, weight: .bold), color: primary),
               in: CGRect(x: left, y: billTop, width: 200, height: 18))
        var by = billTop + 20
        for s in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(s, font: .systemFont(ofSize: 12, weight: .medium), color: .black),
                   in: CGRect(x: left, y: by, width: page.width * 0.55, height: 18))
            by += 20
        }

        // Table
        let top = by + 14
        let headers = ["Description", "Qty", "Rate", "Amount"]
        let specs: [CGFloat] = [0.58, 0.12, 0.14, 0.16]

        let res = R.drawTablePaged(
            context: context, page: page,
            left: left, right: right, top: top, safeBottom: P.bottom,
            headers: headers, colSpecs: specs, items: invoice.items,
            currencyCode: currency,
            headerBg: { rect in self.R.fillRect(context: context, rect: rect, color: primary) },
            headerCell: { _, t, x, w, top, _ in
                self.R.draw(self.R.text(t, font: .systemFont(ofSize: 12, weight: .bold), color: .white),
                            in: CGRect(x: x + 10, y: top + 9, width: w - 14, height: 18))
            },
            rowBg: { i, rect in if i % 2 == 0 { self.R.fillRect(context: context, rect: rect, color: accent.withAlphaComponent(0.06)) } },
            rowCell: { c, v, x, w, y, _ in
                let font = (c == 3) ? UIFont.systemFont(ofSize: 11, weight: .bold) : UIFont.systemFont(ofSize: 11, weight: .medium)
                let col = (c == 3) ? primary : .black
                self.R.draw(self.R.text(v, font: font, color: col),
                            in: CGRect(x: x + 10, y: y + 6, width: w - 14, height: 18))
            },
            rowH: 28, headerH: 34,
            continuationNoteColor: accent
        )

        guard res.hasMore == false else { return }

        // Totals
        let subtotal = R.subtotal(invoice.items)
        let totalsW: CGFloat = 200
        let tx = right - totalsW
        var ty = R.placeBlock(below: res.lastY + 10, desiredHeight: 66, page: page, safeBottom: P.bottom)

        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: tx, y: ty, width: 100, height: 16))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 11, weight: .semibold), color: .black),
               in: CGRect(x: tx + 100, y: ty, width: 100, height: 16))
        ty += 18

        R.strokeLine(context: context, from: CGPoint(x: tx, y: ty + 4), to: CGPoint(x: right, y: ty + 4), color: accent, width: 1)
        ty += 8

        let bar = CGRect(x: tx, y: ty, width: totalsW, height: 40)
        R.fillRect(context: context, rect: bar, color: accent)
        let total = subtotal
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 16, weight: .bold), color: .white),
               in: CGRect(x: bar.minX + 10, y: bar.minY + 8, width: 90, height: 20))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 16, weight: .bold), color: .white),
               in: CGRect(x: bar.minX + 100, y: bar.minY + 8, width: 100, height: 20))

        // Payment / Notes
        var infoTop = res.lastY + 10
        let infoWidth = (tx - left) - 16
        if let pi = extractPaymentInfo(from: invoice) {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 72)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.3), width: 1)
            R.draw(R.text("PAYMENT INSTRUCTIONS", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 14))
            R.draw(R.text(pi, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: 50))
            infoTop = box.maxY + 10
        }
        if let notes = invoice.paymentNotes, !notes.isEmpty {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 72)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.3), width: 1)
            R.draw(R.text("NOTES", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 14))
            R.draw(R.text(notes, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: 50))
        }

        // Footer
        let fy = page.height - P.bottom
        R.draw(R.text("Powered by technology. Innovation delivered.", font: .systemFont(ofSize: 10, weight: .regular), color: .gray),
               in: CGRect(x: left, y: fy - 14, width: right - left, height: 14))
    }
}
// MARK: - RealEstate Warm (refactored to ConsultingElegant-style)

struct RealEstateWarmTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let accent = theme.accent
        let dateFmt = BaseRenderer.date
        let dueDate = extractDueDate(from: invoice) ?? invoice.issueDate

        R.fillRect(context: context, rect: page, color: .white)

        // Cozy header
        let header = CGRect(x: 0, y: 0, width: page.width, height: 125)
        R.fillRect(context: context, rect: header, color: primary.withAlphaComponent(0.10))
        context.setFillColor(accent.withAlphaComponent(0.18).cgColor)
        for i in 0..<6 {
            let d: CGFloat = 12
            context.fillEllipse(in: CGRect(x: CGFloat(i * 100 + 20), y: 16, width: d, height: d))
        }

        // Logo
        R.drawLogo(logo, in: CGRect(x: left + 6, y: 34, width: 70, height: 70), context: context, corner: 10, stroke: accent)

        // Company lines
        let compX = left + 90
        let compW = (right - compX) - 180
        var cy = CGFloat(40)
        for (i, line) in companyLines(company).enumerated() {
            let f: UIFont = (i == 0) ? .systemFont(ofSize: 26, weight: .semibold) : .systemFont(ofSize: 12, weight: .regular)
            let col: UIColor = (i == 0) ? primary : .black
            R.draw(R.text(line, font: f, color: col),
                   in: CGRect(x: compX, y: cy, width: compW, height: i == 0 ? 28 : 16))
            cy += (i == 0 ? 28 : 16)
            if cy > header.maxY - 8 { break }
        }
        R.draw(R.text("REAL ESTATE SERVICES", font: .systemFont(ofSize: 12, weight: .medium), color: accent),
               in: CGRect(x: compX, y: min(cy, header.maxY - 22), width: compW, height: 18))

        // Invoice box
        let inv = CGRect(x: right - 180, y: 40, width: 170, height: 78)
        R.fillRect(context: context, rect: inv, color: accent.withAlphaComponent(0.10))
        R.strokeRect(context: context, rect: inv, color: accent, width: 1)
        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 18, weight: .semibold), color: accent),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 6, width: inv.width - 20, height: 22))
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 14, weight: .medium), color: primary),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 26, width: inv.width - 20, height: 16))
        R.draw(R.text("Issue: \(dateFmt.string(from: invoice.issueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 44, width: inv.width - 20, height: 14))
        R.draw(R.text("Due:   \(dateFmt.string(from: dueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 60, width: inv.width - 20, height: 14))

        // BILL TO block
        let bill = CGRect(x: left, y: header.maxY + 16, width: min(380, right - left), height: 102)
        R.fillRect(context: context, rect: bill, color: primary.withAlphaComponent(0.06))
        R.strokeRect(context: context, rect: bill, color: primary, width: 1)
        R.draw(R.text("BILL TO:", font: .systemFont(ofSize: 14, weight: .semibold), color: primary),
               in: CGRect(x: bill.minX + 10, y: bill.minY + 8, width: bill.width - 20, height: 16))

        var by = bill.minY + 28
        for s in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(s, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                   in: CGRect(x: bill.minX + 10, y: by, width: bill.width - 20, height: 18))
            by += 18
        }

        // Table (paged)
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
                self.R.draw(self.R.text(t, font: .systemFont(ofSize: 12, weight: .semibold), color: .white),
                            in: CGRect(x: x + 10, y: top + 9, width: w - 14, height: 18))
            },
            rowBg: { i, rect in if i % 2 == 0 { self.R.fillRect(context: context, rect: rect, color: accent.withAlphaComponent(0.08)) } },
            rowCell: { _, v, x, w, y, _ in
                self.R.draw(self.R.text(v, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                            in: CGRect(x: x + 10, y: y + 6, width: w - 16, height: 18))
            },
            rowH: 28, headerH: 34,
            continuationNoteColor: accent
        )

        guard res.hasMore == false else { return }

        // Totals (safe placement)
        let subtotal = R.subtotal(invoice.items)
        let totalsW: CGFloat = 210
        let tx = right - totalsW
        var ty = R.placeBlock(below: res.lastY + 10, desiredHeight: 70, page: page, safeBottom: P.bottom)

        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: tx, y: ty, width: 105, height: 16))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 11, weight: .semibold), color: .black),
               in: CGRect(x: tx + 105, y: ty, width: 105, height: 16))
        ty += 18

        R.strokeLine(context: context, from: CGPoint(x: tx, y: ty + 4), to: CGPoint(x: right, y: ty + 4), color: accent, width: 1)
        ty += 8

        let bar = CGRect(x: tx, y: ty, width: totalsW, height: 44)
        R.fillRect(context: context, rect: bar, color: accent)
        let total = subtotal
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 16, weight: .semibold), color: .white),
               in: CGRect(x: bar.minX + 10, y: bar.minY + 10, width: 90, height: 22))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 16, weight: .semibold), color: .white),
               in: CGRect(x: bar.minX + 100, y: bar.minY + 10, width: 100, height: 22))

        // Payment / Notes (left column)
        var infoTop = res.lastY + 10
        let infoWidth = (tx - left) - 16
        if let pi = extractPaymentInfo(from: invoice) {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 74)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.3), width: 1)
            R.draw(R.text("PAYMENT INSTRUCTIONS", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 14))
            R.draw(R.text(pi, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: 50))
            infoTop = box.maxY + 8
        }
        if let notes = invoice.paymentNotes, !notes.isEmpty {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 74)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.3), width: 1)
            R.draw(R.text("NOTES", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 14))
            R.draw(R.text(notes, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: 50))
        }

        // Footer
        let fy = page.height - P.bottom
        R.draw(R.text("Warm real estate services. Your home is our priority.", font: .systemFont(ofSize: 10, weight: .regular), color: .gray),
               in: CGRect(x: left, y: fy - 14, width: right - left, height: 14))
    }
}

// MARK: - Insurance Trust (refactored)

struct InsuranceTrustTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let accent = theme.accent
        let dateFmt = BaseRenderer.date
        let dueDate = extractDueDate(from: invoice) ?? invoice.issueDate

        R.fillRect(context: context, rect: page, color: .white)

        // Trust header
        let header = CGRect(x: 0, y: 0, width: page.width, height: 135)
        R.fillRect(context: context, rect: header, color: primary.withAlphaComponent(0.09))
        context.setFillColor(accent.withAlphaComponent(0.18).cgColor)
        for i in 0..<5 {
            context.fillEllipse(in: CGRect(x: CGFloat(i * 120 + 30), y: 24, width: 22, height: 22))
        }

        // Logo + company
        R.drawLogo(logo, in: CGRect(x: left + 6, y: 40, width: 75, height: 75), context: context, corner: 10, stroke: primary)
        let compX = left + 95
        let compW = (right - compX) - 180
        var cy = CGFloat(50)
        for (i, line) in companyLines(company).enumerated() {
            let f: UIFont = (i == 0) ? .systemFont(ofSize: 28, weight: .bold) : .systemFont(ofSize: 12, weight: .regular)
            let col: UIColor = (i == 0) ? primary : .black
            R.draw(R.text(line, font: f, color: col),
                   in: CGRect(x: compX, y: cy, width: compW, height: i == 0 ? 30 : 16))
            cy += (i == 0 ? 30 : 16)
            if cy > header.maxY - 8 { break }
        }
        R.draw(R.text("INSURANCE SERVICES", font: .systemFont(ofSize: 12, weight: .medium), color: accent),
               in: CGRect(x: compX, y: min(cy, header.maxY - 22), width: compW, height: 18))

        // Invoice box
        let inv = CGRect(x: right - 180, y: 50, width: 170, height: 78)
        R.fillRect(context: context, rect: inv, color: accent.withAlphaComponent(0.12))
        R.strokeRect(context: context, rect: inv, color: accent, width: 1)
        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 18, weight: .bold), color: accent),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 6, width: inv.width - 20, height: 22))
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 14, weight: .semibold), color: primary),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 26, width: inv.width - 20, height: 16))
        R.draw(R.text("Issue: \(dateFmt.string(from: invoice.issueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 44, width: inv.width - 20, height: 14))
        R.draw(R.text("Due:   \(dateFmt.string(from: dueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 60, width: inv.width - 20, height: 14))

        // BILL TO
        let bill = CGRect(x: left, y: header.maxY + 16, width: min(390, right - left), height: 106)
        R.fillRect(context: context, rect: bill, color: primary.withAlphaComponent(0.06))
        R.strokeRect(context: context, rect: bill, color: primary, width: 1)
        R.draw(R.text("BILL TO:", font: .systemFont(ofSize: 14, weight: .bold), color: primary),
               in: CGRect(x: bill.minX + 10, y: bill.minY + 8, width: bill.width - 20, height: 18))

        var by = bill.minY + 30
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
                self.R.draw(self.R.text(t, font: .systemFont(ofSize: 12, weight: .bold), color: .white),
                            in: CGRect(x: x + 10, y: top + 9, width: w - 14, height: 18))
            },
            rowBg: { i, rect in if i % 2 == 0 { self.R.fillRect(context: context, rect: rect, color: accent.withAlphaComponent(0.08)) } },
            rowCell: { _, v, x, w, y, _ in
                self.R.draw(self.R.text(v, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                            in: CGRect(x: x + 10, y: y + 6, width: w - 16, height: 18))
            },
            rowH: 29, headerH: 36,
            continuationNoteColor: accent
        )

        guard res.hasMore == false else { return }

        // Totals
        let subtotal = R.subtotal(invoice.items)
        let totalsW: CGFloat = 220
        let tx = right - totalsW
        var ty = R.placeBlock(below: res.lastY + 10, desiredHeight: 74, page: page, safeBottom: P.bottom)

        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: tx, y: ty, width: 110, height: 16))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 11, weight: .semibold), color: .black),
               in: CGRect(x: tx + 110, y: ty, width: 110, height: 16))
        ty += 18

        R.strokeLine(context: context, from: CGPoint(x: tx, y: ty + 4), to: CGPoint(x: right, y: ty + 4), color: accent, width: 1)
        ty += 8

        let bar = CGRect(x: tx, y: ty, width: totalsW, height: 46)
        R.fillRect(context: context, rect: bar, color: accent)
        let total = subtotal
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 16, weight: .bold), color: .white),
               in: CGRect(x: bar.minX + 10, y: bar.minY + 10, width: 90, height: 20))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 16, weight: .bold), color: .white),
               in: CGRect(x: bar.minX + 102, y: bar.minY + 10, width: 108, height: 20))

        // Payment / Notes
        var infoTop = res.lastY + 10
        let infoWidth = (tx - left) - 16
        if let pi = extractPaymentInfo(from: invoice) {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 76)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.3), width: 1)
            R.draw(R.text("PAYMENT INSTRUCTIONS", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 14))
            R.draw(R.text(pi, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: 52))
            infoTop = box.maxY + 8
        }
        if let notes = invoice.paymentNotes, !notes.isEmpty {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 76)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.3), width: 1)
            R.draw(R.text("NOTES", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 14))
            R.draw(R.text(notes, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: 52))
        }

        // Footer
        let fy = page.height - P.bottom
        R.draw(R.text("Trusted insurance services. Your protection is our commitment.", font: .systemFont(ofSize: 10, weight: .regular), color: .gray),
               in: CGRect(x: left, y: fy - 14, width: right - left, height: 14))
    }
}

// MARK: - Banking Secure (refactored)

struct BankingSecureTemplate: SimpleTemplateRenderer {
    let theme: TemplateTheme
    private let R = BaseRenderer()

    func draw(in context: CGContext, page: CGRect, invoice: Invoice, company: Company, customer: Customer, currency: String, logo: UIImage?) {

        let P = R.insets
        let left = P.left
        let right = page.width - P.right
        let primary = theme.primary
        let accent = theme.accent
        let dateFmt = BaseRenderer.date
        let dueDate = extractDueDate(from: invoice) ?? invoice.issueDate

        R.fillRect(context: context, rect: page, color: .white)

        // Secure grid header
        let header = CGRect(x: 0, y: 0, width: page.width, height: 140)
        R.fillRect(context: context, rect: header, color: primary.withAlphaComponent(0.08))
        context.setStrokeColor(accent.withAlphaComponent(0.25).cgColor)
        context.setLineWidth(1)
        for i in 0..<15 {
            let x = CGFloat(i * 40)
            context.move(to: CGPoint(x: x, y: 0)); context.addLine(to: CGPoint(x: x, y: header.height))
        }
        for i in 0..<10 {
            let y = CGFloat(i * 14)
            context.move(to: CGPoint(x: 0, y: y)); context.addLine(to: CGPoint(x: page.width, y: y))
        }
        context.strokePath()

        // Logo + company
        R.drawLogo(logo, in: CGRect(x: left + 6, y: 44, width: 80, height: 80), context: context, corner: 10, stroke: primary)
        let compX = left + 100
        let compW = (right - compX) - 190
        var cy = CGFloat(52)
        for (i, line) in companyLines(company).enumerated() {
            let f: UIFont = (i == 0) ? .systemFont(ofSize: 30, weight: .bold) : .systemFont(ofSize: 12, weight: .regular)
            let col: UIColor = (i == 0) ? primary : .black
            R.draw(R.text(line, font: f, color: col),
                   in: CGRect(x: compX, y: cy, width: compW, height: i == 0 ? 34 : 16))
            cy += (i == 0 ? 34 : 16)
            if cy > header.maxY - 8 { break }
        }
        R.draw(R.text("BANKING SERVICES", font: .systemFont(ofSize: 12, weight: .medium), color: accent),
               in: CGRect(x: compX, y: min(cy, header.maxY - 22), width: compW, height: 18))

        // Invoice box
        let inv = CGRect(x: right - 190, y: 55, width: 180, height: 80)
        R.fillRect(context: context, rect: inv, color: accent.withAlphaComponent(0.10))
        R.strokeRect(context: context, rect: inv, color: accent, width: 1.2)
        R.draw(R.text("INVOICE", font: .systemFont(ofSize: 20, weight: .bold), color: accent),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 8, width: inv.width - 20, height: 22))
        R.draw(R.text("#\(invoice.number)", font: .systemFont(ofSize: 14, weight: .semibold), color: primary),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 28, width: inv.width - 20, height: 16))
        R.draw(R.text("Issue: \(dateFmt.string(from: invoice.issueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 46, width: inv.width - 20, height: 14))
        R.draw(R.text("Due:   \(dateFmt.string(from: dueDate))", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: inv.minX + 10, y: inv.minY + 62, width: inv.width - 20, height: 14))

        // BILL TO
        let bill = CGRect(x: left, y: header.maxY + 18, width: min(400, right - left), height: 110)
        R.fillRect(context: context, rect: bill, color: primary.withAlphaComponent(0.05))
        R.strokeRect(context: context, rect: bill, color: primary, width: 1)
        R.draw(R.text("BILL TO:", font: .systemFont(ofSize: 15, weight: .bold), color: primary),
               in: CGRect(x: bill.minX + 12, y: bill.minY + 10, width: bill.width - 24, height: 18))

        var by = bill.minY + 32
        for s in [customer.name, customer.address.oneLine, customer.email].filter({ !$0.isEmpty }) {
            R.draw(R.text(s, font: .systemFont(ofSize: 13, weight: .regular), color: .black),
                   in: CGRect(x: bill.minX + 12, y: by, width: bill.width - 24, height: 18))
            by += 20
        }

        // Table
        let tableTop = bill.maxY + 16
        let headers = ["Description", "Quantity", "Unit Price", "Amount"]
        let specs: [CGFloat] = [0.58, 0.12, 0.14, 0.16]

        let res = R.drawTablePaged(
            context: context, page: page,
            left: left, right: right, top: tableTop, safeBottom: P.bottom,
            headers: headers, colSpecs: specs, items: invoice.items,
            currencyCode: currency,
            headerBg: { rect in self.R.fillRect(context: context, rect: rect, color: primary) },
            headerCell: { _, t, x, w, top, _ in
                self.R.draw(self.R.text(t, font: .systemFont(ofSize: 12, weight: .bold), color: .white),
                            in: CGRect(x: x + 10, y: top + 10, width: w - 14, height: 18))
            },
            rowBg: { i, rect in if i % 2 == 0 { self.R.fillRect(context: context, rect: rect, color: accent.withAlphaComponent(0.07)) } },
            rowCell: { _, v, x, w, y, _ in
                self.R.draw(self.R.text(v, font: .systemFont(ofSize: 12, weight: .regular), color: .black),
                            in: CGRect(x: x + 10, y: y + 7, width: w - 16, height: 18))
            },
            rowH: 30, headerH: 38,
            continuationNoteColor: accent
        )

        guard res.hasMore == false else { return }

        // Totals
        let subtotal = R.subtotal(invoice.items)
        let totalsW: CGFloat = 230
        let tx = right - totalsW
        var ty = R.placeBlock(below: res.lastY + 12, desiredHeight: 78, page: page, safeBottom: P.bottom)

        R.draw(R.text("Subtotal", font: .systemFont(ofSize: 11, weight: .regular), color: .black),
               in: CGRect(x: tx, y: ty, width: 115, height: 16))
        R.draw(R.text(R.cur(subtotal, code: currency), font: .systemFont(ofSize: 11, weight: .semibold), color: .black),
               in: CGRect(x: tx + 115, y: ty, width: 115, height: 16))
        ty += 18

        R.strokeLine(context: context, from: CGPoint(x: tx, y: ty + 4), to: CGPoint(x: right, y: ty + 4), color: accent, width: 1)
        ty += 10

        let bar = CGRect(x: tx, y: ty, width: totalsW, height: 48)
        R.fillRect(context: context, rect: bar, color: accent)
        let total = subtotal
        R.draw(R.text("TOTAL", font: .systemFont(ofSize: 16, weight: .bold), color: .white),
               in: CGRect(x: bar.minX + 10, y: bar.minY + 12, width: 90, height: 22))
        R.draw(R.text(R.cur(total, code: currency), font: .systemFont(ofSize: 16, weight: .bold), color: .white),
               in: CGRect(x: bar.minX + 110, y: bar.minY + 12, width: 110, height: 22))

        // Payment / Notes
        var infoTop = res.lastY + 12
        let infoWidth = (tx - left) - 16
        if let pi = extractPaymentInfo(from: invoice) {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 80)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.35), width: 1)
            R.draw(R.text("PAYMENT INSTRUCTIONS", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 14))
            R.draw(R.text(pi, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: 56))
            infoTop = box.maxY + 10
        }
        if let notes = invoice.paymentNotes, !notes.isEmpty {
            let box = CGRect(x: left, y: infoTop, width: infoWidth, height: 80)
            R.strokeRect(context: context, rect: box, color: primary.withAlphaComponent(0.35), width: 1)
            R.draw(R.text("NOTES", font: .systemFont(ofSize: 11, weight: .semibold), color: primary),
                   in: CGRect(x: box.minX + 8, y: box.minY + 6, width: box.width - 16, height: 14))
            R.draw(R.text(notes, font: .systemFont(ofSize: 11, weight: .regular), color: .black),
                   in: CGRect(x: box.minX + 8, y: box.minY + 22, width: box.width - 16, height: 56))
        }

        // Footer
        let fy = page.height - P.bottom
        R.draw(R.text("Secure banking services. Your financial security is our priority.", font: .systemFont(ofSize: 10, weight: .regular), color: .gray),
               in: CGRect(x: left, y: fy - 14, width: right - left, height: 14))
    }
}
