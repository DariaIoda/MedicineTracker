import SwiftUI
import UIKit

/// Программный mock камеры для симулятора: набор «снимков» наклеек с QR-кодами.
/// Выбранный снимок распознаётся тем же декодером Vision, что работает с изображениями.
struct MockScannerView: View {
    let decoder: QRCodeDecoding
    let onCode: (String) -> Void

    @State private var failedName: String?

    static let sampleNames = ["label_box_0001", "label_box_0004", "label_box_0005",
                              "label_box_9999", "label_foreign"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Label("Камера недоступна в симуляторе. Выберите снимок наклейки — QR-код будет распознан с изображения.",
                      systemImage: "camera.metering.unknown")
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
                            .accessibilityIdentifier("mock_\(name)")
                        }
                    }
                }

                if let failedName {
                    Label("На снимке \(failedName) QR-код не найден", systemImage: "exclamationmark.triangle")
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
