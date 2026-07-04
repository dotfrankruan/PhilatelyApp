//
//  PhilatelyItem.swift
//  PhilatelyApp
//

import Foundation

struct PhilatelyItem: Identifiable, Codable, Equatable {
    let id: UUID
    var indexInRound: Int
    var uuid: String?
    var frontRegion: Region?
    var backRegion: Region?
    var extraAssets: [Asset]
    var exportedAssets: [Asset]
    var keywords: [String]
    var manifest: String
    var notes: String
    var isCompleted: Bool

    init(id: UUID = UUID(), indexInRound: Int, uuid: String? = nil, frontRegion: Region? = nil, backRegion: Region? = nil, extraAssets: [Asset] = [], exportedAssets: [Asset] = [], keywords: [String] = [], manifest: String = "", notes: String = "", isCompleted: Bool = false) {
        self.id = id
        self.indexInRound = indexInRound
        self.uuid = uuid
        self.frontRegion = frontRegion
        self.backRegion = backRegion
        self.extraAssets = extraAssets
        self.exportedAssets = exportedAssets
        self.keywords = keywords
        self.manifest = manifest
        self.notes = notes
        self.isCompleted = isCompleted
    }
}
