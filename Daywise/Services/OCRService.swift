import Vision
import UIKit

struct OCRService {
    struct OCRResult {
        var name: String?
        var price: Double?
    }

    func recognize(image: UIImage) async -> OCRResult {
        guard let cgImage = image.cgImage else { return OCRResult() }

        let texts: [String] = await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLanguages = ["zh-Hans", "en-US"]
            request.recognitionLevel = .accurate

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])

            return (request.results ?? []).compactMap {
                $0.topCandidates(1).first?.string
            }
        }.value

        return parseOCRText(texts)
    }

    private func parseOCRText(_ texts: [String]) -> OCRResult {
        var result = OCRResult()

        let pricePattern = #"[¥￥]\s*(\d+(?:\.\d{1,2})?)"#
        let priceRegex = try? NSRegularExpression(pattern: pricePattern)

        for text in texts where result.price == nil {
            let range = NSRange(text.startIndex..., in: text)
            if let match = priceRegex?.firstMatch(in: text, range: range),
               let priceRange = Range(match.range(at: 1), in: text) {
                result.price = Double(text[priceRange])
            }
        }

        for text in texts {
            let trimmed = text.trimmingCharacters(in: .whitespaces)
            guard trimmed.count >= 2, trimmed.count <= 30 else { continue }
            let hasPriceSymbol = trimmed.contains("¥") || trimmed.contains("￥")
            let looksLikeDate = trimmed.contains("-") && trimmed.filter(\.isNumber).count >= 4
            if !hasPriceSymbol && !looksLikeDate {
                result.name = trimmed
                break
            }
        }

        return result
    }
}
