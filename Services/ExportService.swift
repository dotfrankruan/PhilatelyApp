//
//  ExportService.swift
//  PhilatelyApp
//

import Foundation

final class ExportService {
    private let metadataWriter: MetadataWriter
    private let recentStore: RecentKeywordsStore

    init(metadataWriter: MetadataWriter = ExifToolMetadataWriter(), recentStore: RecentKeywordsStore) {
        self.metadataWriter = metadataWriter
        self.recentStore = recentStore
    }

    func export(item: PhilatelyItem, round: Round) throws -> PhilatelyItem {
        guard let frontScan = round.frontScan else {
            throw PhilatelyError.noFrontScan
        }
        guard let backScan = round.backScan else {
            throw PhilatelyError.noBackScan
        }
        guard let exportDirectory = round.exportDirectory else {
            throw PhilatelyError.exportDirectoryNotSelected
        }

        var exportedItem = item
        let uuid = exportedItem.uuid ?? generateUniqueUUID(in: exportDirectory)
        exportedItem.uuid = uuid

        let itemFolder = exportDirectory.appendingPathComponent(uuid, isDirectory: true)
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: itemFolder.path, isDirectory: &isDirectory) {
            throw PhilatelyError.outputAlreadyExists(uuid)
        }
        do {
            try FileManager.default.createDirectory(at: itemFolder, withIntermediateDirectories: true, attributes: nil)
        } catch {
            throw PhilatelyError.exportDirectoryNotWritable(exportDirectory)
        }

        var exportedAssets: [Asset] = []

        // Front
        if let frontRegion = exportedItem.frontRegion {
            let outputURL = itemFolder.appendingPathComponent("\(uuid)-front.jpg")
            let image = try ImageCropService.cropImage(from: frontScan.imageURL, rect: frontRegion.cropRect)
            try ImageCropService.saveJPEG(image, to: outputURL)
            try metadataWriter.writeKeywords(finalKeywords(for: exportedItem), to: outputURL)
            exportedAssets.append(Asset(
                role: .front,
                sourceImageURL: frontScan.imageURL,
                sourceSheetSide: .front,
                cropRect: frontRegion.cropRect,
                outputImageURL: outputURL
            ))
        } else {
            throw PhilatelyError.itemMissingFront(exportedItem.indexInRound)
        }

        // Back
        if let backRegion = exportedItem.backRegion {
            let outputURL = itemFolder.appendingPathComponent("\(uuid)-back.jpg")
            let image = try ImageCropService.cropImage(from: backScan.imageURL, rect: backRegion.cropRect)
            try ImageCropService.saveJPEG(image, to: outputURL)
            try metadataWriter.writeKeywords(finalKeywords(for: exportedItem), to: outputURL)
            exportedAssets.append(Asset(
                role: .back,
                sourceImageURL: backScan.imageURL,
                sourceSheetSide: .back,
                cropRect: backRegion.cropRect,
                outputImageURL: outputURL
            ))
        } else {
            throw PhilatelyError.itemMissingBack(exportedItem.indexInRound)
        }

        // Extra / Content
        var extraIndex = 1
        var contentIndex = 1
        var updatedExtraAssets: [Asset] = []
        for asset in exportedItem.extraAssets {
            var updatedAsset = asset
            let outputURL: URL
            switch asset.role {
            case .extra:
                outputURL = itemFolder.appendingPathComponent("\(uuid)-extra-\(extraIndex).jpg")
                extraIndex += 1
            case .content:
                outputURL = itemFolder.appendingPathComponent("\(uuid)-content-\(contentIndex).jpg")
                contentIndex += 1
            default:
                updatedExtraAssets.append(asset)
                continue
            }

            if let cropRect = asset.cropRect {
                let sourceURL = asset.sourceSheetSide == .front ? frontScan.imageURL : backScan.imageURL
                let image = try ImageCropService.cropImage(from: sourceURL, rect: cropRect)
                try ImageCropService.saveJPEG(image, to: outputURL)
            } else {
                try ImageCropService.copyImage(from: asset.sourceImageURL, to: outputURL)
            }
            try metadataWriter.writeKeywords(finalKeywords(for: exportedItem), to: outputURL)
            updatedAsset.outputImageURL = outputURL
            exportedAssets.append(updatedAsset)
            updatedExtraAssets.append(updatedAsset)
        }
        exportedItem.extraAssets = updatedExtraAssets
        exportedItem.exportedAssets = exportedAssets
        exportedItem.isCompleted = true

        // JSON
        let jsonURL = itemFolder.appendingPathComponent("\(uuid).json")
        let record = ExportRecord(
            from: exportedItem,
            frontScanPath: frontScan.imageURL.path,
            backScanPath: backScan.imageURL.path
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(record)
        try data.write(to: jsonURL, options: .atomic)

        // Manifest txt
        if !exportedItem.manifest.isEmpty {
            let txtURL = itemFolder.appendingPathComponent("\(uuid).txt")
            try exportedItem.manifest.write(to: txtURL, atomically: true, encoding: .utf8)
        }

        // Recents
        recentStore.addKeywords(exportedItem.keywords)

        return exportedItem
    }

    private func finalKeywords(for item: PhilatelyItem) -> [String] {
        guard let uuid = item.uuid else { return [] }
        var result: [String] = [uuid, "philately"]
        for keyword in item.keywords {
            let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            if !result.contains(trimmed) {
                result.append(trimmed)
            }
        }
        return result
    }

    private func generateUniqueUUID(in directory: URL) -> String {
        var uuid = UUIDGenerator.generateShortUUID()
        while FileManager.default.fileExists(atPath: directory.appendingPathComponent(uuid).path) {
            uuid = UUIDGenerator.generateShortUUID()
        }
        return uuid
    }
}

private struct ExportRecord: Codable {
    let uuid: String
    let indexInRound: Int
    let keywords: [String]
    let manifest: String
    let notes: String
    let createdAt: Date
    let assets: [Asset]
    let sourceFrontScanPath: String
    let sourceBackScanPath: String
    let isCompleted: Bool

    init(from item: PhilatelyItem, frontScanPath: String, backScanPath: String) {
        self.uuid = item.uuid ?? ""
        self.indexInRound = item.indexInRound
        self.keywords = {
            guard let uuid = item.uuid else { return item.keywords }
            var result = [uuid, "philately"]
            for keyword in item.keywords {
                let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty, !result.contains(trimmed) else { continue }
                result.append(trimmed)
            }
            return result
        }()
        self.manifest = item.manifest
        self.notes = item.notes
        self.createdAt = Date()
        self.assets = item.exportedAssets
        self.sourceFrontScanPath = frontScanPath
        self.sourceBackScanPath = backScanPath
        self.isCompleted = item.isCompleted
    }
}
