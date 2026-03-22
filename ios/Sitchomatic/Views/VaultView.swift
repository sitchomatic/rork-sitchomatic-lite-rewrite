import SwiftUI

struct VaultView: View {
    @State private var joeVM = LoginViewModel.joe
    @State private var ignitionVM = LoginViewModel.ignition
    @State private var exportHistory: [ExportRecord] = []
    private let persistence = PersistenceService.shared

    private var allCredentials: [LoginCredential] {
        joeVM.credentials + ignitionVM.credentials
    }

    private var allWorking: [LoginCredential] {
        joeVM.workingCredentials + ignitionVM.workingCredentials
    }

    private var allTempDisabled: [LoginCredential] {
        joeVM.tempDisabledCredentials + ignitionVM.tempDisabledCredentials
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .font(.title2)
                            .foregroundStyle(.indigo)
                        VStack(alignment: .leading) {
                            Text("Vault Storage")
                                .font(.headline)
                            Text("\(allCredentials.count) credentials stored (\(joeVM.credentials.count) Joe, \(ignitionVM.credentials.count) Ignition)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Quick Export") {
                Button {
                    let text = allWorking.map(\.exportFormat).joined(separator: "\n")
                    UIPasteboard.general.string = text
                    recordExport(type: "Working Logins", count: allWorking.count, format: "email:password")
                } label: {
                    Label("Copy All Working Logins (\(allWorking.count))", systemImage: "checkmark.circle.fill")
                }
                .disabled(allWorking.isEmpty)

                Button {
                    let text = joeVM.exportWorking()
                    UIPasteboard.general.string = text
                    recordExport(type: "Joe Working", count: joeVM.workingCredentials.count, format: "email:password")
                } label: {
                    Label("Copy Joe Fortune Working (\(joeVM.workingCredentials.count))", systemImage: "bolt.shield.fill")
                }
                .disabled(joeVM.workingCredentials.isEmpty)

                Button {
                    let text = ignitionVM.exportWorking()
                    UIPasteboard.general.string = text
                    recordExport(type: "Ignition Working", count: ignitionVM.workingCredentials.count, format: "email:password")
                } label: {
                    Label("Copy Ignition Working (\(ignitionVM.workingCredentials.count))", systemImage: "flame.fill")
                }
                .disabled(ignitionVM.workingCredentials.isEmpty)

                Button {
                    let text = allCredentials.map(\.exportFormat).joined(separator: "\n")
                    UIPasteboard.general.string = text
                    recordExport(type: "All Credentials", count: allCredentials.count, format: "email:password")
                } label: {
                    Label("Copy All Credentials (\(allCredentials.count))", systemImage: "doc.on.doc.fill")
                }
                .disabled(allCredentials.isEmpty)

                Button {
                    let text = allTempDisabled.map(\.exportFormat).joined(separator: "\n")
                    UIPasteboard.general.string = text
                    recordExport(type: "Temp Disabled", count: allTempDisabled.count, format: "email:password")
                } label: {
                    Label("Copy Temp Disabled (\(allTempDisabled.count))", systemImage: "clock.fill")
                }
                .disabled(allTempDisabled.isEmpty)
            }

            Section("Export as JSON") {
                Button {
                    let json = exportJSON()
                    UIPasteboard.general.string = json
                    recordExport(type: "Full JSON", count: allCredentials.count, format: "JSON")
                } label: {
                    Label("Copy Full JSON Export", systemImage: "curlybraces")
                }
            }

            if !exportHistory.isEmpty {
                Section("Export History") {
                    ForEach(exportHistory) { record in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.type).font(.subheadline)
                                Text("\(record.count) items • \(record.format)").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(record.exportedAt.formatted(.dateTime.hour().minute()))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Vault & Export")
        .onAppear {
            exportHistory = persistence.loadExportHistory()
            joeVM.reloadCredentials()
            ignitionVM.reloadCredentials()
        }
    }

    private func recordExport(type: String, count: Int, format: String) {
        let record = ExportRecord(type: type, count: count, format: format)
        exportHistory.insert(record, at: 0)
        if exportHistory.count > 50 { exportHistory = Array(exportHistory.prefix(50)) }
        persistence.saveExportHistory(exportHistory)
    }

    private func exportJSON() -> String {
        var allCreds: [[String: Any]] = []
        for (siteName, creds) in [("Joe Fortune", joeVM.credentials), ("Ignition Casino", ignitionVM.credentials)] {
            for cred in creds {
                allCreds.append([
                    "site": siteName,
                    "username": cred.username,
                    "password": cred.password,
                    "status": cred.status.rawValue,
                    "addedAt": ISO8601DateFormatter().string(from: cred.addedAt),
                    "testCount": cred.testResults.count
                ])
            }
        }
        let data = try? JSONSerialization.data(withJSONObject: allCreds, options: .prettyPrinted)
        return data.flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
    }
}
