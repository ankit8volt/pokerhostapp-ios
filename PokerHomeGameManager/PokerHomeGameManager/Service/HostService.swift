import Foundation
import CoreData

enum ValidationError: Error, Equatable {
    case missingRequiredFields([String])
    case hostNotFound
    case invalidSessionParameters(String)
    case invalidPlayerName
}

class HostService: HostServiceProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func registerHost(name: String, city: String, phone: String, upiHandle: String?) throws -> Host {
        var missingFields: [String] = []
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingFields.append("name")
        }
        if city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingFields.append("city")
        }
        if phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingFields.append("phone")
        }
        if !missingFields.isEmpty {
            throw ValidationError.missingRequiredFields(missingFields)
        }

        let host = Host(context: context)
        host.id = UUID()
        host.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        host.city = city.trimmingCharacters(in: .whitespacesAndNewlines)
        host.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        host.upiHandle = upiHandle?.trimmingCharacters(in: .whitespacesAndNewlines)
        host.createdAt = Date()

        try context.save()
        return host
    }

    func getHost() -> Host? {
        let request: NSFetchRequest<Host> = Host.fetchRequest()
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    func updateHost(name: String?, city: String?, phone: String?, upiHandle: String?) throws -> Host {
        guard let host = getHost() else {
            throw ValidationError.hostNotFound
        }

        if let name = name {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                throw ValidationError.missingRequiredFields(["name"])
            }
            host.name = trimmed
        }
        if let city = city {
            let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                throw ValidationError.missingRequiredFields(["city"])
            }
            host.city = trimmed
        }
        if let phone = phone {
            let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                throw ValidationError.missingRequiredFields(["phone"])
            }
            host.phone = trimmed
        }
        host.upiHandle = upiHandle?.trimmingCharacters(in: .whitespacesAndNewlines)

        try context.save()
        return host
    }

    func isRegistered() -> Bool {
        return getHost() != nil
    }
}
