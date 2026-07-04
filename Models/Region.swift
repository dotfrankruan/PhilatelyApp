//
//  Region.swift
//  PhilatelyApp
//

import Foundation
import CoreGraphics

struct Region: Identifiable, Codable, Equatable {
    let id: UUID
    var index: Int
    var cropRect: CGRect
    var rotation: Double
    var isAdjustedManually: Bool

    init(id: UUID = UUID(), index: Int, cropRect: CGRect, rotation: Double = 0, isAdjustedManually: Bool = false) {
        self.id = id
        self.index = index
        self.cropRect = cropRect
        self.rotation = rotation
        self.isAdjustedManually = isAdjustedManually
    }
}
