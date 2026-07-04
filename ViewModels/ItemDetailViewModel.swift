//
//  ItemDetailViewModel.swift
//  PhilatelyApp
//

import Foundation
import Combine

@MainActor
final class ItemDetailViewModel: ObservableObject {
    @Published var item: PhilatelyItem
    @Published var isSaving = false
    @Published var errorMessage: String?

    let round: Round
    let recentStore: RecentKeywordsStore
    let exportService: ExportService
    let onSave: (PhilatelyItem) -> Void

    var availableBackRegions: [Region] {
        round.backScan?.detectedRegions ?? []
    }

    init(item: PhilatelyItem, round: Round, exportService: ExportService, recentStore: RecentKeywordsStore, onSave: @escaping (PhilatelyItem) -> Void) {
        self.item = item
        self.round = round
        self.exportService = exportService
        self.recentStore = recentStore
        self.onSave = onSave
    }

    func addKeyword(_ keyword: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !item.keywords.contains(trimmed) else { return }
        item.keywords.append(trimmed)
    }

    func removeKeyword(_ keyword: String) {
        item.keywords.removeAll { $0 == keyword }
    }

    func addExtra() {
        guard let url = FilePickerService.pickImage() else { return }
        let asset = Asset(role: .extra, sourceImageURL: url)
        item.extraAssets.append(asset)
    }

    func addContent() {
        guard let url = FilePickerService.pickImage() else { return }
        let asset = Asset(role: .content, sourceImageURL: url)
        item.extraAssets.append(asset)
    }

    func removeExtraAsset(_ asset: Asset) {
        item.extraAssets.removeAll { $0.id == asset.id }
    }

    func replaceBack(with region: Region?) {
        item.backRegion = region
    }

    func save() {
        isSaving = true
        defer { isSaving = false }
        do {
            let exported = try exportService.export(item: item, round: round)
            onSave(exported)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
