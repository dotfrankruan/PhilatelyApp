//
//  FileHelpers.swift
//  PhilatelyApp
//

import Foundation
import AppKit

enum FileHelpers {
    static func openFolderInFinder(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    static func ensureDirectoryExists(at url: URL) throws {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            guard isDirectory.boolValue else {
                throw PhilatelyError.exportDirectoryNotWritable(url)
            }
            return
        }
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }
}
