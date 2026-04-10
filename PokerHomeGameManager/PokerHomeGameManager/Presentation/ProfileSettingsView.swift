import SwiftUI

struct ProfileSettingsView: View {
    private let hostService: HostServiceProtocol
    @State private var name = ""
    @State private var phone = ""
    @State private var upiHandle = ""
    @State private var errorMessage = ""
    @State private var successMessage = ""

    init(hostService: HostServiceProtocol) {
        self.hostService = hostService
    }

    var body: some View {
        List {
            Section {
                TextField("Name", text: $name).textContentType(.name)
                HStack {
                    Text("+91").foregroundColor(.secondary)
                    TextField("Phone Number", text: $phone)
                        .textContentType(.telephoneNumber).keyboardType(.phonePad)
                }
                VStack(alignment: .leading, spacing: 4) {
                    TextField("UPI Handle (e.g. name@upi)", text: $upiHandle)
                        .autocapitalization(.none).keyboardType(.emailAddress)
                    Text("Required to collect payments via UPI")
                        .font(.caption2).foregroundColor(.pokerGold)
                }
            } header: {
                Text("Profile").foregroundColor(.pokerGold)
            }

            if !errorMessage.isEmpty {
                Section { Text(errorMessage).foregroundColor(.pokerRed) }
            }
            if !successMessage.isEmpty {
                Section { Text(successMessage).foregroundColor(.green) }
            }

            Section {
                Button { saveProfile() } label: {
                    HStack { Spacer(); Text("Save Changes").font(.headline).foregroundColor(.black); Spacer() }
                        .padding(.vertical, 8)
                }
                .listRowBackground(Color.pokerGold)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.pokerDarkGreen)
        .navigationTitle("Profile Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.pokerDarkGreen, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .scrollDismissesKeyboard(.interactively)
        .onAppear { loadProfile() }
    }

    private func loadProfile() {
        if let host = hostService.getHost() {
            name = host.name ?? ""
            phone = host.phone ?? ""
            upiHandle = host.upiHandle ?? ""
        }
    }

    private func saveProfile() {
        errorMessage = ""
        successMessage = ""
        let upi: String? = upiHandle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : upiHandle
        do {
            _ = try hostService.updateHost(name: name, city: nil, phone: phone, upiHandle: upi)
            successMessage = "Profile updated ✓"
        } catch {
            errorMessage = "Failed to update. Check required fields."
        }
    }
}
