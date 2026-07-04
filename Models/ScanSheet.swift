//
//  ScanSheet.swift
//  PhilatelyApp
//

import Foundation

enum SheetSide: String, Codable, CaseIterable {
    case front
    case back
}

struct ScanSheet: Identifiable, Codable, Equatable {
    let id: UUID
    var imageURL: URL
    var side: SheetSide
    var detectedRegions: [Region]

    init(id: UUID = UUID(), imageURL: URL, side: SheetSide, detectedRegions: [Region] = []) {
        self.id = id
        self.imageURL = imageURL
        self.side = side
        self.detectedRegions = detectedRegions
    }
}
