import SwiftUI

struct LoginCredentialsListView: View {
    let vm: LoginViewModel
    @State private var showImportSheet: Bool = false
    @State private var importText: String = ""
    @State private var searchText: String = ""
    @State private var filterStatus: CredentialStatus?

    private var filteredCredentials: [LoginCredential] {
        var result = vm.credentials
        if let filter = filterStatus {
            result = result.filter { $0.status == filter }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.username.localizedStandardContains(searchText) }
        }
        return result
    }

    var body: some View {
        List {
            Section {
                filterBar
            }

            if filteredCredentials.isEmpty {
                Section {
                    ContentUnavailableView {
                        Label("No Credentials", systemImage: "person.text.rectangle")
                    } description: {
                        Text("Import credentials to get started")
                    }
                }
            } else {
                Section("\(filteredCredentials.count) credentials") {
                    ForEach(filteredCredentials) { cred in
                        NavigationLink(value: cred.id) {
                            CredentialRow(credential: cred)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            vm.removeCredential(filteredCredentials[index])
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Credentials")
        .searchable(text: $searchText, prompt: "Search username...")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showImportSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    Button("Clear All", role: .destructive) {
                        vm.clearAllCredentials()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showImportSheet) {
            ImportCredentialsSheet(importText: $importText) {
                vm.addCredentials(importText)
                importText = ""
                showImportSheet = false
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: filterStatus == nil) {
                    filterStatus = nil
                }
                ForEach(CredentialStatus.allCases, id: \.rawValue) { status in
                    FilterChip(title: status.rawValue, isSelected: filterStatus == status) {
                        filterStatus = filterStatus == status ? nil : status
                    }
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
}

struct CredentialRow: View {
    let credential: LoginCredential

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: credential.status.icon)
                .foregroundStyle(statusColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(credential.username)
                    .font(.system(.subheadline, design: .monospaced))
                    .lineLimit(1)
                Text(credential.status.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !credential.testResults.isEmpty {
                Text("\(credential.testResults.count) tests")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var statusColor: Color {
        switch credential.status {
        case .working: return .green
        case .tempDisabled: return .orange
        case .permDisabled: return .red
        case .noAccount: return .gray
        case .unsure: return .yellow
        case .untested: return .secondary
        case .blacklisted: return .red
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.tertiarySystemGroupedBackground))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct ImportCredentialsSheet: View {
    @Binding var importText: String
    let onImport: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Paste credentials (one per line)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Formats: email:password, email|password, email;password")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                TextEditor(text: $importText)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 200)
                    .clipShape(.rect(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separator), lineWidth: 0.5)
                    )

                if !importText.isEmpty {
                    let parsed = LoginCredential.smartParse(importText)
                    Text("\(parsed.count) credentials detected")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            .padding()
            .navigationTitle("Import Credentials")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") { onImport() }
                        .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
