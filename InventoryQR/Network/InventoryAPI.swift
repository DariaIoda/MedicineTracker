import Combine
import Foundation

/// Объекты передачи данных REST API. Имена ключей JSON (snake_case) сопоставляются
/// со свойствами через CodingKeys.
struct RoomDTO: Codable, Equatable {
    let id: String
    let name: String
    let icon: String
}

struct ContainerDTO: Codable, Equatable {
    let id: String
    let name: String
    let code: String
    let roomID: String

    enum CodingKeys: String, CodingKey {
        case id, name, code
        case roomID = "room_id"
    }
}

struct ItemDTO: Codable, Equatable {
    let id: String
    let name: String
    let quantity: Int
    let typeID: String
    let containerID: String
    let note: String?

    enum CodingKeys: String, CodingKey {
        case id, name, quantity, note
        case typeID = "type_id"
        case containerID = "container_id"
    }
}

/// Полный набор начальных данных, полученный с сервера.
struct InventorySnapshot: Equatable {
    let rooms: [RoomDTO]
    let containers: [ContainerDTO]
    let items: [ItemDTO]
}

/// Ошибки сетевого слоя.
enum APIError: LocalizedError, Equatable {
    case transport(String)
    case badStatus(Int)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .transport(let message): return "Нет соединения с сервером: \(message)"
        case .badStatus(let code): return "Сервер вернул ошибку \(code)"
        case .decoding: return "Некорректный ответ сервера"
        }
    }
}

/// Контракт сетевого слоя.
protocol InventoryAPI {
    func fetchSnapshot() -> AnyPublisher<InventorySnapshot, APIError>
}

/// Клиент REST API на URLSession и Combine.
struct InventoryAPIClient: InventoryAPI {
    /// Mock-сервер my-json-server отдаёт db.json из корня GitHub-репозитория как REST API.
    static let defaultBaseURL = URL(string: "https://my-json-server.typicode.com/dezshev/RPiPiP-InventoryQR")!

    let baseURL: URL
    let session: URLSession
    let decoder: JSONDecoder

    init(baseURL: URL = defaultBaseURL, session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
    }

    func fetchSnapshot() -> AnyPublisher<InventorySnapshot, APIError> {
        Publishers.Zip3(
            request([RoomDTO].self, path: "rooms"),
            request([ContainerDTO].self, path: "containers"),
            request([ItemDTO].self, path: "items")
        )
        .map { InventorySnapshot(rooms: $0, containers: $1, items: $2) }
        .eraseToAnyPublisher()
    }

    /// GET-запрос: проверка кода ответа → декодирование JSON → приведение ошибок к APIError.
    func request<T: Decodable>(_ type: T.Type, path: String) -> AnyPublisher<T, APIError> {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent(path))
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.timeoutInterval = 15
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData

        return session.dataTaskPublisher(for: urlRequest)
            .mapError { APIError.transport($0.localizedDescription) }
            .tryMap { data, response -> Data in
                guard let http = response as? HTTPURLResponse else { throw APIError.badStatus(-1) }
                guard (200..<300).contains(http.statusCode) else { throw APIError.badStatus(http.statusCode) }
                return data
            }
            .decode(type: T.self, decoder: decoder)
            .mapError { error -> APIError in
                if let apiError = error as? APIError { return apiError }
                return .decoding(String(describing: error))
            }
            .retry(1)
            .eraseToAnyPublisher()
    }
}
