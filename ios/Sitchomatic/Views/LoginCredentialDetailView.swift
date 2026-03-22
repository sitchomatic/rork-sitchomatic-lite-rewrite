import SwiftUI

struct LoginCredentialDetailView: View {
    let credential: LoginCredential
    let vm: LoginViewModel

    var body: some View {
        List {
            Section("Account Info") {
                LabeledContent("Username", value: credential.username)
                LabeledContent("Password", value: credential.password)
                LabeledContent("Status", value: credential.status.rawValue)
                LabeledContent("Added", value: credential.addedAt.formatted(.dateTime.month().day().hour().minute()))
                if let tested = credential.lastTestedAt {
                    LabeledContent("Last Tested", value: tested.formatted(.dateTime.month().day().hour().minute()))
                }
            }

            if !credential.notes.isEmpty {
                Section("Notes") {
                    Text(credential.notes)
                        .font(.subheadline)
                }
            }

            if !credential.testResults.isEmpty {
                Section("Test History (\(credential.testResults.count))") {
                    ForEach(credential.testResults) { result in
                        HStack {
                            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(result.success ? .green : .red)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.success ? "Success" : "Failed")
                                    .font(.subheadline.bold())
                                if let detail = result.responseDetail {
                                    Text(detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if let error = result.errorMessage {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                            Spacer()
                            Text(String(format: "%.1fs", result.duration))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Section {
                Button("Copy Username") {
                    UIPasteboard.general.string = credential.username
                }
                Button("Copy Password") {
                    UIPasteboard.general.string = credential.password
                }
                Button("Copy email:password") {
                    UIPasteboard.general.string = credential.exportFormat
                }
            }

            Section {
                Button("Remove Credential", role: .destructive) {
                    vm.removeCredential(credential)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(credential.username)
        .navigationBarTitleDisplayMode(.inline)
    }
}
