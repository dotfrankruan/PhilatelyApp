//
//  Round.swift
//  PhilatelyApp
//

import Foundation

struct Round: Identifiable, Codable, Equatable {
    let id: UUID
    var createdAt: Date
    var frontScan: ScanSheet?
    var backScan: ScanSheet?
    var items: [PhilatelyItem]
    var exportDirectory: URL?
    var isCompleted: Bool

    init(id: UUID = UUID(), createdAt: Date = Date(), frontScan: ScanSheet? = nil, backScan: ScanSheet? = nil, items: [PhilatelyItem] = [], exportDirectory: URL? = nil, isCompleted: Bool = false) {
        self.id = id
        self.createdAt = createdAt
        self.frontScan = frontScan
        self.backScan = backScan
        self.items = items
        self.exportDirectory = exportDirectory
        self.isCompleted = isCompleted
    }
}
