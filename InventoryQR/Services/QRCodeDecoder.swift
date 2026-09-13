import CoreImage
import UIKit
import Vision

/// Распознавание QR-кода на неподвижном изображении (используется mock-сканером).
protocol QRCodeDecoding {
    func decode(_ image: UIImage) -> String?
}

/// Основной путь — Vision; если он недоступен (в части симуляторов нейросетевые
/// ревизии VNDetectBarcodesRequest не работают), используется CIDetector.
struct VisionQRCodeDecoder: QRCodeDecoding {
    func decode(_ image: UIImage) -> String? {
        guard let cgImage = image.cgImage else { return nil }
        return decodeWithVision(cgImage) ?? decodeWithCoreImage(cgImage)
    }

    private func decodeWithVision(_ cgImage: CGImage) -> String? {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        #if targetEnvironment(simulator)
        request.revision = VNDetectBarcodesRequestRevision1
        #endif
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
        guard (try? handler.perform([request])) != nil else { return nil }
        return request.results?.compactMap(\.payloadStringValue).first
    }

    private func decodeWithCoreImage(_ cgImage: CGImage) -> String? {
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil,
                                  options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let features = detector?.features(in: CIImage(cgImage: cgImage)) ?? []
        return features.compactMap { ($0 as? CIQRCodeFeature)?.messageString }.first
    }
}
