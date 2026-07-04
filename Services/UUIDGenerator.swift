//
//  UUIDGenerator.swift
//  PhilatelyApp
//

import Foundation

enum UUIDGenerator {
    private static let chars = "abcdefghijklmnopqrstuvwxyz0123456789"

    static func generateShortUUID(length: Int = 16) -> String {
        var result = ""
        for _ in 0..<length {
            if let char = chars.randomElement() {
                result.append(char)
            }
        }
        return result
    }
}
