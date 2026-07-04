//
//  FilePickerService.swift
//  PhilatelyApp
//

import AppKit
import UniformTypeIdentifiers

enum FilePickerService {
    static func pickImage() -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image, .jpeg, .png, .tiff]
        panel.message = "Select a scan image"
        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }

    static func pickImages(allowMultiple: Bool = true) -> [URL]? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = allowMultiple
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image, .jpeg, .png, .tiff]
        panel.message = "Select image(s)"
        guard panel.runModal() == .OK else { return nil }
        return Array(panel.urls)
    }

    static func pickExportDirectory() -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.message = "Select export folder"
        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }
}
