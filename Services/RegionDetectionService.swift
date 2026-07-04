//
//  RegionDetectionService.swift
//  PhilatelyApp
//

import Foundation
import Vision
import CoreGraphics

enum RegionDetectionService {
    static func detectRegions(in imageURL: URL) async throws -> [Region] {
        let request = VNDetectRectanglesRequest()
        request.minimumConfidence = 0.5
        request.minimumAspectRatio = 0.2
        request.maximumAspectRatio = 1.0
        request.quadratureTolerance = 45

        let handler = VNImageRequestHandler(url: imageURL, options: [:])
        try handler.perform([request])

        guard let observations = request.results as? [VNRectangleObservation], !observations.isEmpty else {
            return []
        }

        let size = try ImageCropService.imageSize(for: imageURL)
        guard size.width > 0, size.height > 0 else { return [] }

        let rects = observations.compactMap { observation -> CGRect? in
            convert(observation: observation, imageSize: size)
        }

        let filtered = filterNestedAndTinyRects(rects, imageSize: size)

        let sorted = filtered.sorted { lhs, rhs in
            if abs(lhs.midY - rhs.midY) > min(lhs.height, rhs.height) * 0.5 {
                return lhs.midY < rhs.midY
            }
            return lhs.midX < rhs.midX
        }

        return sorted.enumerated().map { index, rect in
            Region(index: index + 1, cropRect: rect)
        }
    }

    private static func convert(observation: VNRectangleObservation, imageSize: CGSize) -> CGRect? {
        let minX = min(observation.topLeft.x, observation.bottomLeft.x)
        let maxX = max(observation.topRight.x, observation.bottomRight.x)
        let minYVision = min(observation.bottomLeft.y, observation.bottomRight.y)
        let maxYVision = max(observation.topLeft.y, observation.topRight.y)

        let width = (maxX - minX) * imageSize.width
        let height = (maxYVision - minYVision) * imageSize.height
        guard width > 10, height > 10 else { return nil }

        let x = minX * imageSize.width
        let y = (1 - maxYVision) * imageSize.height
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private static func filterNestedAndTinyRects(_ rects: [CGRect], imageSize: CGSize) -> [CGRect] {
        let areaThreshold = (imageSize.width * imageSize.height) * 0.001
        let nonTiny = rects.filter { $0.width * $0.height >= areaThreshold }

        var result: [CGRect] = []
        for rect in nonTiny {
            var shouldInsert = true
            for (index, existing) in result.enumerated() {
                if existing.contains(rect) {
                    shouldInsert = false
                    break
                }
                if rect.contains(existing) {
                    result[index] = rect
                    shouldInsert = false
                    break
                }
            }
            if shouldInsert {
                result.append(rect)
            }
        }
        return result
    }
}
