import SwiftUI

struct SessionHistoryView: View {
    @StateObject private var viewModel: HistoryViewModel

    init(sessionService: SessionServiceProtocol) {
        _viewModel = StateObject(wrappedValue: HistoryViewModel(sessionService: sessionService))
    }

    var body: some View {
        List {
            if viewModel.pastSessions.isEmpty {
                Section {
                    Text("No past sessions")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.pokerCardWhite)
                }
            } else {
                ForEach(viewModel.pastSessions, id: \.id) { session in
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(session.venue ?? "No venue")
                                    .font(.subheadline.bold())
                                Spacer()
                                if let date = session.sessionDate {
                                    Text(date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            if let summary = viewModel.summary(for: session) {
                                HStack {
                                    Label("\(summary.playerCount)", systemImage: "person.2")
                                    Spacer()
                                    Label("\(summary.totalBuyIns)", systemImage: "arrow.down.circle")
                                    Spacer()
                                    Text("₹\(summary.totalCollected)")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        .listRowBackground(Color.pokerCardWhite)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.pokerDarkGreen)
        .navigationTitle("Session History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.pokerDarkGreen, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear { viewModel.loadPastSessions() }
    }
}
