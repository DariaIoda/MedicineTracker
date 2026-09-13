import Foundation

/// Формат файла обмена со списком вещей одной коробки.
struct ContainerExport: Codable, Equatable {
    struct ExportedItem: Codable, Equatable {
        let name: String
        let quantity: Int
        let typeID: String
        let category: String
        let note: String

        enum CodingKeys: String, CodingKey {
            case name, quantity, category, note
            case typeID = "type_id"
        }
    }

    let format: String
    let version: Int
    let exportedAt: Date
    let containerCode: String
    let containerName: String
    let roomName: String
    let items: [ExportedItem]

    enum CodingKeys: String, CodingKey {
        case format, version, items
        case exportedAt = "exported_at"
        case containerCode = "container_code"
        case containerName = "container_name"
        case roomName = "room_name"
    }
}

enum ExportFormat: String, CaseIterable, Identifiable {
    case json
    case csv

    var id: String { rawValue }
    var title: String { self == .json ? "JSON (для импорта)" : "CSV (для таблиц)" }
}

/// Формирует отчуждаемый файл со списком вещей контейнера.
struct ContainerExporter {
    let catalog: ItemTypeCatalog
    var now: () -> Date = Date.init

    func makeExport(for container: StorageContainer) -> ContainerExport {
        ContainerExport(
            format: "inventory-qr-container",
            version: 1,
            exportedAt: now(),
            containerCode: container.code,
            containerName: container.name,
            roomName: container.room?.name ?? "",
            items: container.sortedItems.map {
                .init(name: $0.name, quantity: $0.quantity, typeID: $0.typeID,
                      category: catalog.type(id: $0.typeID).category, note: $0.note)
            }
        )
    }

    func data(for container: StorageContainer, format: ExportFormat) throws -> Data {
        let export = makeExport(for: container)
        switch format {
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(export)
        case .csv:
            var lines = ["Код;Контейнер;Комната;Вещь;Количество;Тип имущества;Заметка"]
            for item in export.items {
                lines.append([export.containerCode, export.containerName, export.roomName,
                              item.name, String(item.quantity), item.category, item.note]
                    .map(Self.csvField).joined(separator: ";"))
            }
            // BOM нужен, чтобы Excel правильно определил кодировку UTF-8
            return Data("\u{FEFF}".utf8) + Data(lines.joined(separator: "\r\n").utf8)
        }
    }

    /// Записывает файл во временную папку и возвращает его адрес для ShareLink.
    func writeFile(for container: StorageContainer, format: ExportFormat) throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("Export", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent("\(container.code).inventory.\(format.rawValue)")
        try data(for: container, format: format).write(to: url, options: .atomic)
        return url
    }

    static func csvField(_ value: String) -> String {
        guard value.contains(where: { $0 == ";" || $0 == "\"" || $0 == "\n" }) else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
