//
//  MetadataWriter.swift
//  PhilatelyApp
//

import Foundation

protocol MetadataWriter {
    func writeKeywords(_ keywords: [String], to imageURL: URL) throws
}
