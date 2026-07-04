//
//  PairingService.swift
//  PhilatelyApp
//

import Foundation

enum PairingService {
    static func autoPair(frontRegions: [Region], backRegions: [Region]) throws -> [PhilatelyItem] {
        let sortedFront = frontRegions.sorted { $0.index < $1.index }
        let sortedBack = backRegions.sorted { $0.index < $1.index }

        guard sortedFront.count == sortedBack.count else {
            throw PhilatelyError.regionCountMismatch(front: sortedFront.count, back: sortedBack.count)
        }

        var items: [PhilatelyItem] = []
        for (offset, pair) in zip(sortedFront, sortedBack).enumerated() {
            let item = PhilatelyItem(
                indexInRound: offset + 1,
                frontRegion: pair.0,
                backRegion: pair.1
            )
            items.append(item)
        }
        return items
    }

    static func validatePairing(items: [PhilatelyItem]) -> PhilatelyError? {
        for item in items {
            guard item.frontRegion != nil else {
                return .itemMissingFront(item.indexInRound)
            }
            guard item.backRegion != nil else {
                return .itemMissingBack(item.indexInRound)
            }
        }
        return nil
    }
}
