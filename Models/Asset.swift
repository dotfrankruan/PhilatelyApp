//
//  Asset.swift
//  PhilatelyApp
//

import Foundation

enum AssetRole: String, Codable, CaseIterable {
    case front
    case back
    case extra
    case content
}

struct Asset: Identifiable, Codable, Equatable {
    let id: UUID
    var role: AssetRole
    var sourceImageURL: URL
    var sourceSheetSide: SheetSide?
    var cropRect: CGRect?
    var outputImageURL: URL?

    init(id: UUID = UUID(), role: AssetRole, sourceImageURL: URL, sourceSheetSide: SheetSide? = nil, cropRect: CGRect? = nil, outputImageURL: URL? = nil) {
        self.id = id
        self.role = role
        self.sourceImageURL = sourceImageURL
        self.sourceSheetSide = sourceSheetSide
        self.cropRect = cropRect
        self.outputImageURL = outputImageURL
    }
}
