import SwiftUI

struct DebugLogView: View {
    @State private var logger = DebugLogger.shared
    @State private var filterCategory: LogCategory?
    @State private var searchText: String = ""

    private var filteredEntries: [LogEntry] {
        var result = logger.entries
        if let cat = filterCategory {
            result = result.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.message.localizedStandardContains(searchText) }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            filterBar

            if filteredEntries.isEmpty {
                ContentUnavailableView("No Logs", systemImage: "doc.text.magnifyingglass", description: Text("Logs will appear here during automation"))
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(filteredEntries.reversed()) { entry in
                            HStack(alignment: .top, spacing: 6) {
                                Circle()
                                    .fill(levelColor(entry.level))
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 5)

                                Text(entry.formatted)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(levelColor(entry.level))
                                    .textSelection(.enabled)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .background(Color.black)
        .navigationTitle("Debug Log")
        .searchable(text: $searchText, prompt: "Search logs...")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Copy All") {
                        UIPasteboard.general.string = logger.exportText
                    }
                    Button("Clear Logs", role: .destructive) {
                        logger.clear()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: filterCategory == nil) {
                    filterCategory = nil
                }
                ForEach([LogCategory.login, .bpoint, .network, .system, .persistence], id: \.rawValue) { cat in
                    FilterChip(title: cat.rawValue, isSelected: filterCategory == cat) {
                        filterCategory = filterCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGray6).opacity(0.2))
    }

    private func levelColor(_ level: LogLevel) -> Color {
        switch level {
        case .info: return .white.opacity(0.7)
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .critical: return .red
        }
    }
}
