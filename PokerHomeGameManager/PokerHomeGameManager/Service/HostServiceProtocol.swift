import Foundation
import CoreData

protocol HostServiceProtocol {
    func registerHost(name: String, city: String, phone: String, upiHandle: String?) throws -> Host
    func getHost() -> Host?
    func updateHost(name: String?, city: String?, phone: String?, upiHandle: String?) throws -> Host
    func isRegistered() -> Bool
}
