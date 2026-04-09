import Foundation

struct UPIGenerateResponse: Codable {
    let upiIntentUrl: String
    let shareUrl: String
    let qrCodeDataUrl: String
}

class UPIAPIService {
    private let baseURL = "https://pokerhostapp-upi-api.vercel.app/api/generate"

    func generateUPILinks(pa: String, pn: String, am: Decimal, tn: String, tr: String) async throws -> UPIGenerateResponse {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "pa", value: pa),
            URLQueryItem(name: "pn", value: pn),
            URLQueryItem(name: "am", value: "\(am)"),
            URLQueryItem(name: "tn", value: tn),
            URLQueryItem(name: "tr", value: tr)
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        print("[UPI API] Calling: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        print("[UPI API] Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            print("[UPI API] Error body: \(body)")
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(UPIGenerateResponse.self, from: data)
    }
}
