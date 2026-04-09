import UIKit

class UPIService: UPIServiceProtocol {

    func canOpenUPI() -> Bool {
        guard let url = URL(string: "upi://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    /// Generate a UPI intent URL for collecting payment (payee = host)
    func generateCollectURL(payeeUPI: String, amount: Decimal, note: String) -> URL? {
        return buildUPIURL(pa: payeeUPI, pn: nil, amount: amount, note: note)
    }

    /// Generate a UPI intent URL for paying out (payee = player)
    func generatePayURL(recipientUPI: String, amount: Decimal, note: String) -> URL? {
        return buildUPIURL(pa: recipientUPI, pn: nil, amount: amount, note: note)
    }

    @discardableResult
    func openUPIApp(with url: URL) -> Bool {
        guard UIApplication.shared.canOpenURL(url) else { return false }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        return true
    }

    // MARK: - Full UPI URL builder

    /// Builds: upi://pay?pa=<vpa>&pn=<name>&am=<amount>&cu=INR&tn=<note>
    func buildUPIURL(pa: String, pn: String?, amount: Decimal, note: String) -> URL? {
        guard !pa.isEmpty, amount > 0 else { return nil }

        var components = URLComponents()
        components.scheme = "upi"
        components.host = "pay"
        var items = [
            URLQueryItem(name: "pa", value: pa),
            URLQueryItem(name: "am", value: "\(amount)"),
            URLQueryItem(name: "cu", value: "INR"),
            URLQueryItem(name: "tn", value: note)
        ]
        if let pn = pn, !pn.isEmpty {
            items.insert(URLQueryItem(name: "pn", value: pn), at: 1)
        }
        components.queryItems = items
        return components.url
    }
}
