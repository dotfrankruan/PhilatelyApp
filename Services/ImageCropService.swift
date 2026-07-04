//
//  ImageCropService.swift
//  PhilatelyApp
//

import Foundation
import AppKit
import CoreGraphics

enum ImageCropService {
    static func imageSize(for url: URL) throws -> CGSize {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw PhilatelyError.imageLoadFailed(url)
        }
        let options: [NSString: Any] = [kCGImageSourceShouldCache: false]
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, options as CFDictionary) else {
            throw PhilatelyError.imageLoadFailed(url)
        }
        return CGSize(width: cgImage.width, height: cgImage.height)
    }

    static func cropImage(from url: URL, rect: CGRect) throws -> NSImage {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw PhilatelyError.imageLoadFailed(url)
        }
        let options: [NSString: Any] = [kCGImageSourceShouldCache: false]
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, options as CFDictionary) else {
            throw PhilatelyError.imageLoadFailed(url)
        }

        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)

        let cgRect = CGRect(
            x: rect.origin.x,
            y: rect.origin.y,
            width: rect.width,
            height: rect.height
        )

        guard cgRect.width > 0, cgRect.height > 0 else {
            throw PhilatelyError.imageCropFailed
        }

        guard let cropped = cgImage.cropping(to: cgRect) else {
            throw PhilatelyError.imageCropFailed
        }

        return NSImage(cgImage: cropped, size: NSSize(width: cgRect.width, height: cgRect.height))
    }

    static func saveJPEG(_ image: NSImage, to url: URL, compressionFactor: CGFloat = 0.92) throws {
        guard let tiffData = image.tiffRepresentation else {
            throw PhilatelyError.imageCropFailed
        }
        guard let bitmap = NSBitmapImageRep(data: tiffData) else {
            throw PhilatelyError.imageCropFailed
        }
        guard let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: compressionFactor]) else {
            throw PhilatelyError.imageCropFailed
        }
        try jpegData.write(to: url, options: .atomic)
    }

    static func copyImage(from sourceURL: URL, to destinationURL: URL) throws {
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
    }
}
