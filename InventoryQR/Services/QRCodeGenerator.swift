import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Абстракция генератора QR-кодов (слабая связанность ViewModel и CoreImage).
protocol QRCodeGenerating {
    func makeImage(for text: String, side: CGFloat) -> UIImage?
}

/// Генерация QR-кода средствами CoreImage (фильтр CIQRCodeGenerator).
struct CoreImageQRCodeGenerator: QRCodeGenerating {
    private let context = CIContext()

    func makeImage(for text: String, side: CGFloat) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }

        // Масштабирование без сглаживания, чтобы модули кода оставались чёткими
        let scale = max(1, floor(side / output.extent.width))
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
