import Foundation
import Combine

class RegistrationViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var phone: String = ""
    @Published var upiHandle: String = ""

    @Published var nameError: String = ""
    @Published var phoneError: String = ""
    @Published var upiError: String = ""
    @Published var errorMessage: String = ""

    @Published var isRegistered: Bool = false

    private let hostService: HostServiceProtocol

    init(hostService: HostServiceProtocol) {
        self.hostService = hostService
        self.isRegistered = hostService.isRegistered()
    }

    func register() {
        clearErrors()

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUPI = upiHandle.trimmingCharacters(in: .whitespacesAndNewlines)

        var hasError = false

        if trimmedName.isEmpty {
            nameError = "Name is required"
            hasError = true
        }
        if trimmedPhone.isEmpty {
            phoneError = "Phone number is required"
            hasError = true
        }
        if !trimmedUPI.isEmpty && !isValidUPIHandle(trimmedUPI) {
            upiError = "UPI handle must be in format name@provider"
            hasError = true
        }

        if hasError { return }

        let upi: String? = trimmedUPI.isEmpty ? nil : trimmedUPI

        do {
            _ = try hostService.registerHost(name: trimmedName, city: "", phone: trimmedPhone, upiHandle: upi)
            isRegistered = true
        } catch {
            errorMessage = "Registration failed. Please try again."
        }
    }

    private func clearErrors() {
        nameError = ""
        phoneError = ""
        upiError = ""
        errorMessage = ""
    }

    private func isValidUPIHandle(_ handle: String) -> Bool {
        let parts = handle.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && !parts[0].isEmpty && !parts[1].isEmpty
    }
}
