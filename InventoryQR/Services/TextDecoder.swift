import UIKit
import Vision

protocol TextDecoding {
    func decode(_ image: UIImage) -> String?
}

struct VisionTextDecoder: TextDecoding {
    func decode(_ image: UIImage) -> String? {
        guard let cgImage = image.cgImage else { return nil }
        
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
        
        guard let observations = request.results else { return nil }
        
        let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
        return recognizedText.isEmpty ? nil : recognizedText
    }
}