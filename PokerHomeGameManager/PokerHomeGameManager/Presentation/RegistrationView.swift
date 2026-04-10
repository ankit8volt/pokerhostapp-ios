import SwiftUI

struct RegistrationView: View {
    @StateObject private var viewModel: RegistrationViewModel
    @State private var showCelebration = false

    init(hostService: HostServiceProtocol) {
        _viewModel = StateObject(wrappedValue: RegistrationViewModel(hostService: hostService))
    }

    var body: some View {
        ZStack {
            List {
            Section {
                VStack(spacing: 8) {
                    Text("♠️ ♥️ ♣️ ♦️")
                        .font(.system(size: 40))
                    Text("Stackr")
                        .font(.largeTitle.bold())
                        .foregroundColor(.pokerGold)
                    Text("Set up your host profile")
                        .font(.subheadline)
                        .foregroundColor(.pokerChip.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .listRowBackground(Color.pokerDarkGreen)
            }

            Section {
                TextField("Name", text: $viewModel.name)
                    .textContentType(.name)
                    .accessibilityIdentifier("registration_name_field")
                if !viewModel.nameError.isEmpty {
                    Text(viewModel.nameError).font(.caption).foregroundColor(.pokerRed)
                }

                HStack {
                    Text("+91").foregroundColor(.secondary)
                    TextField("Phone Number (without country code)", text: $viewModel.phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .accessibilityIdentifier("registration_phone_field")
                }
                if !viewModel.phoneError.isEmpty {
                    Text(viewModel.phoneError).font(.caption).foregroundColor(.pokerRed)
                }

                VStack(alignment: .leading, spacing: 4) {
                    TextField("UPI Handle (e.g. name@upi)", text: $viewModel.upiHandle)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .accessibilityIdentifier("registration_upi_field")
                    Text("Required to collect payments via UPI")
                        .font(.caption2).foregroundColor(.pokerGold)
                }
                if !viewModel.upiError.isEmpty {
                    Text(viewModel.upiError).font(.caption).foregroundColor(.pokerRed)
                }
            } header: {
                Text("Host Details").foregroundColor(.pokerGold)
            }

            if !viewModel.errorMessage.isEmpty {
                Section {
                    Text(viewModel.errorMessage).foregroundColor(.pokerRed)
                }
            }

            Section {
                Button {
                    viewModel.register()
                    if viewModel.isRegistered {
                        showCelebration = true
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Register").font(.headline).foregroundColor(.black)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.pokerGold)
                .accessibilityIdentifier("registration_register_button")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.pokerDarkGreen)
        .navigationBarHidden(true)
        .scrollDismissesKeyboard(.interactively)

            // Celebration overlay
            if showCelebration {
                CelebrationOverlay(
                    message: "Welcome to Stackr! 🎉",
                    icon: "🃏"
                ) {
                    showCelebration = false
                    NotificationCenter.default.post(name: .hostRegistered, object: nil)
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
}
