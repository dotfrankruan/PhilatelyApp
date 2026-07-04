//
//  RoundViewModel.swift
//  PhilatelyApp
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class RoundViewModel: ObservableObject {
    @Published var round: Round
    @Published var selectedSide: SheetSide = .front
    @Published var selectedItem: PhilatelyItem?
    @Published var isDetecting = false
    @Published var errorMessage: String?
    @Published var showCompletionAlert = false

    let recentStore: RecentKeywordsStore
    let exportService: ExportService

    var currentScanSheet: ScanSheet? {
        selectedSide == .front ? round.frontScan : round.backScan
    }

    var currentRegions: [Region] {
        currentScanSheet?.detectedRegions ?? []
    }

    var items: [PhilatelyItem] {
        get { round.items }
        set { round.items = newValue }
    }

    var canAutoPair: Bool {
        round.frontScan != nil && round.backScan != nil
    }

    var regionCountMismatch: Bool {
        guard let front = round.frontScan, let back = round.backScan else { return false }
        return front.detectedRegions.count != back.detectedRegions.count
    }

    init(round: Round = Round(), recentStore: RecentKeywordsStore = RecentKeywordsStore()) {
        self.round = round
        self.recentStore = recentStore
        self.exportService = ExportService(recentStore: recentStore)
    }

    func newRound() {
        round = Round()
        selectedSide = .front
        selectedItem = nil
        errorMessage = nil
        showCompletionAlert = false
    }



    func importFrontScan() {
        guard let url = FilePickerService.pickImage() else { return }
        round.frontScan = ScanSheet(imageURL: url, side: .front)
        round.items = []
    }

    func importBackScan() {
        guard let url = FilePickerService.pickImage() else { return }
        round.backScan = ScanSheet(imageURL: url, side: .back)
    }

    func detectRegions(for side: SheetSide) async {
        guard let scan = side == .front ? round.frontScan : round.backScan else { return }
        isDetecting = true
        defer { isDetecting = false }
        do {
            let regions = try await RegionDetectionService.detectRegions(in: scan.imageURL)
            if side == .front {
                round.frontScan?.detectedRegions = regions
            } else {
                round.backScan?.detectedRegions = regions
            }
            try attemptAutoPair()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func autoPair() {
        do {
            try attemptAutoPair()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func attemptAutoPair() throws {
        guard let front = round.frontScan, let back = round.backScan else { return }
        let newItems = try PairingService.autoPair(frontRegions: front.detectedRegions, backRegions: back.detectedRegions)
        round.items = newItems
        errorMessage = nil
        objectWillChange.send()
    }

    func reDetectCurrentSide() {
        Task {
            await detectRegions(for: selectedSide)
        }
    }

    func addRegion() {
        guard let scan = currentScanSheet else {
            errorMessage = "Import a scan first."
            return
        }
        let size = (try? ImageCropService.imageSize(for: scan.imageURL)) ?? CGSize(width: 800, height: 600)
        let rect = CGRect(
            x: size.width * 0.25,
            y: size.height * 0.25,
            width: size.width * 0.5,
            height: size.height * 0.5
        )
        let nextIndex = (scan.detectedRegions.map(\.index).max() ?? 0) + 1
        let region = Region(index: nextIndex, cropRect: rect)
        if selectedSide == .front {
            round.frontScan?.detectedRegions.append(region)
        } else {
            round.backScan?.detectedRegions.append(region)
        }
        objectWillChange.send()
    }

    func removeRegion(_ region: Region) {
        if selectedSide == .front {
            round.frontScan?.detectedRegions.removeAll { $0.id == region.id }
            for index in round.items.indices where round.items[index].frontRegion?.id == region.id {
                round.items[index].frontRegion = nil
            }
        } else {
            round.backScan?.detectedRegions.removeAll { $0.id == region.id }
            for index in round.items.indices where round.items[index].backRegion?.id == region.id {
                round.items[index].backRegion = nil
            }
        }
        objectWillChange.send()
    }

    func updateRegion(_ region: Region) {
        if selectedSide == .front {
            guard let idx = round.frontScan?.detectedRegions.firstIndex(where: { $0.id == region.id }) else { return }
            round.frontScan?.detectedRegions[idx] = region
            for index in round.items.indices where round.items[index].frontRegion?.id == region.id {
                round.items[index].frontRegion = region
            }
        } else {
            guard let idx = round.backScan?.detectedRegions.firstIndex(where: { $0.id == region.id }) else { return }
            round.backScan?.detectedRegions[idx] = region
            for index in round.items.indices where round.items[index].backRegion?.id == region.id {
                round.items[index].backRegion = region
            }
        }
        objectWillChange.send()
    }

    func selectExportDirectory() {
        guard let url = FilePickerService.pickExportDirectory() else { return }
        round.exportDirectory = url
    }

    func openExportFolder() {
        guard let url = round.exportDirectory else {
            errorMessage = "Export directory not selected."
            return
        }
        FileHelpers.openFolderInFinder(url)
    }

    func replaceBackScan() {
        guard let url = FilePickerService.pickImage() else { return }
        round.backScan = ScanSheet(imageURL: url, side: .back)
        for index in round.items.indices {
            round.items[index].backRegion = nil
        }
        Task {
            await detectRegions(for: .back)
        }
    }

    func replaceBackRegion(for itemID: UUID, with region: Region?) {
        guard let index = round.items.firstIndex(where: { $0.id == itemID }) else { return }
        round.items[index].backRegion = region
        objectWillChange.send()
    }

    func updateItem(_ item: PhilatelyItem) {
        guard let index = round.items.firstIndex(where: { $0.id == item.id }) else { return }
        round.items[index] = item
        checkRoundCompletion()
    }

    func checkRoundCompletion() {
        guard !round.items.isEmpty, round.items.allSatisfy(\.isCompleted) else { return }
        round.isCompleted = true
        showCompletionAlert = true
    }
}
