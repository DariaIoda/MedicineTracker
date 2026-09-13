import Combine
import Foundation
import Observation

/// ViewModel экспорта содержимого коробки в файл.
@Observable
final class ExportViewModel {
    private let repository: InventoryRepository
    private let exporter: ContainerExporter
    let containerID: UUID

    var format: ExportFormat = .json
    private(set) var fileURL: URL?
    private(set) var previewText = ""
    private(set) var fileSize = 0
    private(set) var errorMessage: String?

    init(containerID: UUID, repository: InventoryRepository, exporter: ContainerExporter) {
        self.containerID = containerID
        self.repository = repository
        self.exporter = exporter
    }

    var containerCode: String { repository.container(id: containerID)?.code ?? "" }
    var itemCount: Int { repository.container(id: containerID)?.items.count ?? 0 }
    var fileSizeText: String { ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file) }

    func prepare() {
        guard let container = repository.container(id: containerID) else {
            errorMessage = InventoryError.notFound.localizedDescription
            return
        }
        do {
            let url = try exporter.writeFile(for: container, format: format)
            let data = try Data(contentsOf: url)
            fileURL = url
            fileSize = data.count
            previewText = String(decoding: data, as: UTF8.self).replacingOccurrences(of: "\u{FEFF}", with: "")
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// Поиск «на лету» с задержкой ввода и отбрасыванием повторов средствами Combine.
@Observable
final class DebouncedSearch {
    private(set) var appliedQuery = ""
    @ObservationIgnored private let subject = PassthroughSubject<String, Never>()
    @ObservationIgnored private var cancellable: AnyCancellable?

    init(delay: RunLoop.SchedulerTimeType.Stride = .milliseconds(250)) {
        cancellable = subject
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .debounce(for: delay, scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] in self?.appliedQuery = $0 }
    }

    func send(_ text: String) {
        subject.send(text)
    }
}
