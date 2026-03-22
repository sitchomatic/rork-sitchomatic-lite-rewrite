import SwiftUI

struct LoginMoreMenuView: View {
    @Bindable var vm: LoginViewModel
    @State private var showAddURLSheet: Bool = false

    var body: some View {
        List {
            speedSection
            automationToolsSection
            urlsSection
            accountToolsSection
            dataSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("More")
        .sheet(isPresented: $showAddURLSheet) {
            AddCustomSiteSheet { site in
                vm.addCustomSite(site)
                showAddURLSheet = false
            }
        }
    }

    private var speedSection: some View {
        Section {
            SpeedToggleView(selectedSpeed: $vm.speedMode)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        } header: {
            Label("Speed Mode", systemImage: "gauge.with.dots.needle.50percent")
        }
    }

    private var automationToolsSection: some View {
        Section {
            Button {
                withAnimation { vm.speedMode = .speedDemon }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Color.red.opacity(0.12)).frame(width: 40, height: 40)
                        Image(systemName: "flame.fill").foregroundStyle(.red)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Speed Demon 🔥").font(.subheadline.bold())
                        Text("Maximum speed, minimal delays").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }

            Button {
                withAnimation { vm.speedMode = .slowDebug }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Color.indigo.opacity(0.12)).frame(width: 40, height: 40)
                        Image(systemName: "ladybug.fill").foregroundStyle(.indigo)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Slow Debug 🐞").font(.subheadline.bold())
                        Text("Very slow + auto-screenshots + logging").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }

            VStack(spacing: 8) {
                HStack {
                    Text("Post Page Settle Delay")
                        .font(.subheadline)
                    Spacer()
                    Text("\(vm.postPageSettleDelayMs)ms")
                        .font(.system(.caption, design: .monospaced, weight: .bold))
                        .foregroundStyle(.cyan)
                }
                Slider(value: Binding(
                    get: { Double(vm.postPageSettleDelayMs) },
                    set: { vm.postPageSettleDelayMs = Int($0) }
                ), in: 0...10000, step: 250)
                .tint(.cyan)
            }
        } header: {
            Label("Automation Tools", systemImage: "wrench.and.screwdriver")
        }
    }

    private var urlsSection: some View {
        Section {
            ForEach(BuiltInSite.allCases, id: \.rawValue) { site in
                HStack(spacing: 12) {
                    Image(systemName: site.icon)
                        .foregroundStyle(site == .joe ? .green : .orange)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(site.displayName).font(.subheadline.bold())
                        Text(site.rawValue).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.left.and.right.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            ForEach(vm.customSites) { site in
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .foregroundStyle(.purple)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(site.name).font(.subheadline.bold())
                        Text(site.domain).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        vm.removeCustomSite(site)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            Button {
                showAddURLSheet = true
            } label: {
                Label("Add URL", systemImage: "plus.circle.fill")
            }
        } header: {
            Label("URLs & Endpoints", systemImage: "link")
        }
    }

    private var accountToolsSection: some View {
        Section {
            NavigationLink {
                TempDisabledView(vm: vm)
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Color.orange.opacity(0.12)).frame(width: 40, height: 40)
                        Image(systemName: "clock.fill").foregroundStyle(.orange)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Temp Disabled").font(.subheadline.bold())
                        Text("\(vm.tempDisabledCredentials.count) accounts").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }

            NavigationLink {
                PermDisabledView(vm: vm)
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Color.red.opacity(0.12)).frame(width: 40, height: 40)
                        Image(systemName: "xmark.octagon.fill").foregroundStyle(.red)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Perm Disabled").font(.subheadline.bold())
                        Text("\(vm.permDisabledCredentials.count) accounts").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Label("Account Tools", systemImage: "person.2")
        }
    }

    private var dataSection: some View {
        Section {
            Button {
                UIPasteboard.general.string = vm.exportWorking()
            } label: {
                Label("Copy Working Logins", systemImage: "doc.on.doc")
            }
            .disabled(vm.workingCredentials.isEmpty)

            Button {
                UIPasteboard.general.string = vm.credentials.map(\.exportFormat).joined(separator: "\n")
            } label: {
                Label("Copy All Credentials", systemImage: "doc.on.doc.fill")
            }
            .disabled(vm.credentials.isEmpty)
        } header: {
            Label("Data & Export", systemImage: "square.and.arrow.up")
        }
    }
}

struct AddCustomSiteSheet: View {
    @State private var name: String = ""
    @State private var domain: String = ""
    @State private var emailSelector: String = ""
    @State private var passwordSelector: String = ""
    @State private var submitSelector: String = ""
    let onAdd: (CustomSite) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Site Info") {
                    TextField("Site Name", text: $name)
                    TextField("Domain (e.g. example.com)", text: $domain)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }
                Section("Selectors") {
                    TextField("Email Selector (e.g. #email)", text: $emailSelector)
                        .textInputAutocapitalization(.never)
                    TextField("Password Selector (e.g. #password)", text: $passwordSelector)
                        .textInputAutocapitalization(.never)
                    TextField("Submit Selector (e.g. #submit)", text: $submitSelector)
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle("Add Custom URL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let site = CustomSite(name: name, domain: domain, emailSelector: emailSelector, passwordSelector: passwordSelector, submitSelector: submitSelector)
                        onAdd(site)
                    }
                    .disabled(name.isEmpty || domain.isEmpty || emailSelector.isEmpty || passwordSelector.isEmpty || submitSelector.isEmpty)
                }
            }
        }
    }
}

struct TempDisabledView: View {
    let vm: LoginViewModel

    var body: some View {
        List {
            if vm.tempDisabledCredentials.isEmpty {
                ContentUnavailableView("No Temp Disabled", systemImage: "clock", description: Text("No temporarily disabled accounts found"))
            } else {
                ForEach(vm.tempDisabledCredentials) { cred in
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill").foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(cred.username).font(.system(.subheadline, design: .monospaced))
                            if let tested = cred.lastTestedAt {
                                Text(tested.formatted(.relative(presentation: .named))).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Temp Disabled")
    }
}

struct PermDisabledView: View {
    let vm: LoginViewModel

    var body: some View {
        List {
            if vm.permDisabledCredentials.isEmpty {
                ContentUnavailableView("No Perm Disabled", systemImage: "xmark.octagon", description: Text("No permanently disabled accounts found"))
            } else {
                ForEach(vm.permDisabledCredentials) { cred in
                    HStack(spacing: 12) {
                        Image(systemName: "xmark.octagon.fill").foregroundStyle(.red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(cred.username).font(.system(.subheadline, design: .monospaced))
                            if let tested = cred.lastTestedAt {
                                Text(tested.formatted(.relative(presentation: .named))).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Perm Disabled")
    }
}
