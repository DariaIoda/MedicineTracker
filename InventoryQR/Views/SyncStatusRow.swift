import SwiftUI

/// Строка состояния загрузки начальных данных с сервера.
struct SyncStatusRow: View {
    let state: InventorySyncService.State
    let retry: () -> Void

    var body: some View {
        Section {
            HStack(spacing: 12) {
                icon
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.semibold))
                    if let subtitle {
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if case .failed = state {
                    Button("Повторить", action: retry)
                        .buttonStyle(.bordered)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("syncStatus")
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch state {
        case .idle, .loading:
            ProgressView()
        case .synced:
            Image(systemName: "checkmark.icloud").foregroundStyle(.green)
        case .failed:
            Image(systemName: "exclamationmark.icloud").foregroundStyle(.orange)
        }
    }

    private var title: String {
        switch state {
        case .idle, .loading: return "Загрузка данных с сервера…"
        case .synced: return "Данные с сервера загружены"
        case .failed: return "Сервер недоступен — показаны сохранённые данные"
        }
    }

    private var subtitle: String? {
        switch state {
        case .synced(let report, let date):
            let time = date.formatted(date: .omitted, time: .shortened)
            return "Добавлено: \(report.inserted), обновлено: \(report.updated) · \(time)"
        case .failed(let message):
            return message
        default:
            return nil
        }
    }
}
