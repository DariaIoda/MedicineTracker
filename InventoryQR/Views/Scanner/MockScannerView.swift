import SwiftUI
import UIKit

struct MockScannerView: View {
    let decoder: TextDecoding
    let onCode: (String) -> Void
    @State private var failedName: String?
    
    // Имена картинок из Assets, на которых написаны названия лекарств
    static let sampleNames = ["aspirin_label", "ibuprofen_label", "paracetamol_label"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Label("Выберите снимок упаковки — текст будет распознан (OCR).", systemImage: "text.viewfinder")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    ForEach(Self.sampleNames, id: \.self) { name in
                        if let image = Self.loadImage(named: name) {
                            Button {
                                scan(image, name: name)
                            } label: {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary.opacity(0.3)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                if let failedName {
                    Label("На снимке \(failedName) текст не найден", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }
            .padding()
        }
    }
    
    private func scan(_ image: UIImage, name: String) {
        if let value = decoder.decode(image) {
            failedName = nil
            onCode(value)
        } else {
            failedName = name
            onCode("")
        }
    }
    
    static func loadImage(named name: String) -> UIImage? {
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        return UIImage(named: name)
    }
}