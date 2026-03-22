import SwiftUI

struct WorkingLoginsView: View {
    let vm: LoginViewModel
    @State private var showExportSheet: Bool = false

    var body: some View {
        List {
            if vm.workingCredentials.isEmpty {
                Section {
                    ContentUnavailableView {
                        Label("No Working Logins", systemImage: "checkmark.shield")
                    } description: {
                        Text("Run a batch to find working credentials")
                    }
                }
            } else {
                Section("\(vm.workingCredentials.count) working") {
                    ForEach(vm.workingCredentials) { cred in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(cred.username)
                                    .font(.system(.subheadline, design: .monospaced))
                                    .lineLimit(1)
                                Text(cred.password)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                UIPasteboard.general.string = cred.exportFormat
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Working Logins")
        .toolbar {
            if !vm.workingCredentials.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showExportSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSheet(text: vm.exportWorking(), title: "Working Logins")
        }
    }
}

struct ExportSheet: View {
    let text: String
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("\(text.components(separatedBy: "\n").count) entries")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ScrollView {
                    Text(text)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 8))

                HStack(spacing: 16) {
                    Button {
                        UIPasteboard.general.string = text
                    } label: {
                        Label("Copy All", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Export \(title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
