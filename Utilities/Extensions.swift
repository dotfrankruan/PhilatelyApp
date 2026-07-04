//
//  Extensions.swift
//  PhilatelyApp
//

import Foundation

extension Array where Element: Equatable {
    func uniqued() -> [Element] {
        var result: [Element] = []
        for element in self {
            if !result.contains(element) {
                result.append(element)
            }
        }
        return result
    }
}
