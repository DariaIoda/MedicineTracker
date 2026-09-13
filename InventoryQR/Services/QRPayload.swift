import Foundation

/// Формат содержимого QR-метки контейнера: `INVQR:<версия>:<код контейнера>`.
struct QRPayload: Equatable {
    static let prefix = "INVQR"
    static let version = 1

    let containerCode: String

    var stringValue: String { "\(Self.prefix):\(Self.version):\(containerCode)" }

    /// Разбор строки, считанной с QR-кода. Возвращает nil для посторонних кодов.
    static func parse(_ raw: String) -> QRPayload? {
        let parts = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count == 3,
              parts[0] == prefix,
              Int(parts[1]) == version,
              !parts[2].isEmpty else { return nil }
        return QRPayload(containerCode: String(parts[2]))
    }
}
