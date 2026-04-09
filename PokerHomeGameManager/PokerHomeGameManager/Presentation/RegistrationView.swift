import SwiftUI

struct RegistrationView: View {
    @StateObject private var viewModel: RegistrationViewModel

    init(hostService: HostServiceProtocol) {
        _viewModel = StateObject(wrappedValue: RegistrationViewModel(hostService: hostService))
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Text("♠️ ♥️ ♣️ ♦️")
                        .font(.system(size: 40))
                    Text("Poker Home")
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
                if !viewModel.nameError.isEmpty {
                    Text(viewModel.nameError).font(.caption).foregroundColor(.pokerRed)
                }

                TextField("City", text: $viewModel.city)
                    .textContentType(.addressCity)
                if !viewModel.cityError.isEmpty {
                    Text(viewModel.cityError).font(.caption).foregroundColor(.pokerRed)
                }

                TextField("Phone Number", text: $viewModel.phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                if !viewModel.phoneError.isEmpty {
                    Text(viewModel.phoneError).font(.caption).foregroundColor(.pokerRed)
                }

                TextField("UPI Handle (optional)", text: $viewModel.upiHandle)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
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
                } label: {
                    HStack {
                        Spacer()
                        Text("Register").font(.headline).foregroundColor(.black)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.pokerGold)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.pokerDarkGreen)
        .navigationBarHidden(true)
        .scrollDismissesKeyboard(.interactively)
    }
}
