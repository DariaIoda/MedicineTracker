import Combine
import Foundation
import Observation

@Observable
final class ScannerViewModel {
    enum State: Equatable {
        case scanning
        case conflictFound(Interaction)
        case safeToAdd(String)
    }
    
    private let repository: MedicineRepository
    private let catalog: InteractionCatalog
    private(set) var state: State = .scanning
    
    // Брокер сообщений Combine для обработки потока распознанных текстов
    @ObservationIgnored private let scanSubject = PassthroughSubject<String, Never>()
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    
    init(repository: MedicineRepository, catalog: InteractionCatalog) {
        self.repository = repository
        self.catalog = catalog
        setupCombinePipeline()
    }
    
    private func setupCombinePipeline() {
        scanSubject
            .removeDuplicates()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main) // Защита от дублирующих запросов
            .sink { [weak self] scannedText in
                self?.analyze(scannedName: scannedText)
            }
            .store(in: &cancellables)
    }
    
    func handle(scannedValue text: String) {
        // Публикуем событие обнаружения текста в брокер Combine
        scanSubject.send(text)
    }
    
    private func analyze(scannedName: String) {
        let currentMedicines = repository.medicines().map { $0.name }
        
        if let conflict = catalog.checkConflict(scannedName: scannedName, currentMedicines: currentMedicines) {
            state = .conflictFound(conflict)
        } else {
            state = .safeToAdd(scannedName)
        }
    }
    
    func reset() {
        state = .scanning
    }
}