import Combine
import Foundation
import Observation

@Observable
final class ScannerViewModel {
    enum State: Equatable {
        case scanning
        case conflictFound(Interaction)
        case safeToAdd(String)
        case noTextFound
    }
    
    private let repository: MedicineRepository
    private let catalog: InteractionCatalog
    private(set) var state: State = .scanning
    
    @ObservationIgnored private let scanSubject = PassthroughSubject<String, Never>()
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    
    init(repository: MedicineRepository, catalog: InteractionCatalog) {
        self.repository = repository
        self.catalog = catalog
        
        scanSubject
            .removeDuplicates()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] text in self?.analyze(scannedName: text) }
            .store(in: &cancellables)
    }
    
    func handle(scannedValue text: String) {
        if text.trimmingCharacters(in: .whitespaces).isEmpty {
            state = .noTextFound
        } else {
            scanSubject.send(text)
        }
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