import Foundation

protocol UPIServiceProtocol {
    func canOpenUPI() -> Bool
    func generateCollectURL(payeeUPI: String, amount: Decimal, note: String) -> URL?
    func generatePayURL(recipientUPI: String, amount: Decimal, note: String) -> URL?
    func openUPIApp(with url: URL) -> Bool
}
