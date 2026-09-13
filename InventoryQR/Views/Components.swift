import SwiftUI

/// Заголовок секции комнаты.
struct RoomHeader: View {
    let room: Room

    var body: some View {
        HStack {
            Image(systemName: room.icon)
            Text(room.name)
            Spacer()
            Text("\(room.containers.count) конт. · \(room.itemCount) вещ.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .font(.headline)
        .textCase(nil)
    }
}

/// Строка контейнера в иерархии.
struct ContainerRow: View {
    let container: StorageContainer

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "shippingbox.fill")
                .foregroundStyle(.orange)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(container.name)
                    .font(.body.weight(.semibold))
                Text(container.code)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(container.items.count)")
                .font(.caption.weight(.bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.orange.opacity(0.15), in: Capsule())
        }
    }
}

/// Строка вещи.
struct ItemRow: View {
    let item: Item
    let type: ItemType

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundStyle(.blue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                Text(type.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("× \(item.quantity)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}

/// Результат поиска с указанием местоположения.
struct SearchResultRow: View {
    let item: Item
    let type: ItemType
    let query: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundStyle(.blue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(highlighted(item.name))
                Label(item.path, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("× \(item.quantity)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func highlighted(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        if let range = result.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) {
            result[range].font = .body.bold()
            result[range].foregroundColor = .accentColor
        }
        return result
    }
}

/// Плитка со сводным показателем.
struct StatBadge: View {
    let value: Int
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
            Text("\(value)")
                .font(.title2.weight(.bold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}
