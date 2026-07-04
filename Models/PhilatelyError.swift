//
//  PhilatelyError.swift
//  PhilatelyApp
//

import Foundation

enum PhilatelyError: LocalizedError, Equatable {
    case noFrontScan
    case noBackScan
    case regionCountMismatch(front: Int, back: Int)
    case itemMissingFront(Int)
    case itemMissingBack(Int)
    case exportDirectoryNotSelected
    case exportDirectoryNotWritable(URL)
    case exifToolNotFound
    case exifToolFailed(String)
    case imageCropFailed
    case jsonWriteFailed
    case manifestWriteFailed
    case outputAlreadyExists(String)
    case imageLoadFailed(URL)
    case pairingFailed(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .noFrontScan:
            return "No front scan imported."
        case .noBackScan:
            return "No back scan imported."
        case .regionCountMismatch(let front, let back):
            return "Front has \(front) regions but back has \(back). Please adjust or manually pair."
        case .itemMissingFront(let index):
            return "Item \(index) is missing a front region."
        case .itemMissingBack(let index):
            return "Item \(index) is missing a back region."
        case .exportDirectoryNotSelected:
            return "Export directory not selected."
        case .exportDirectoryNotWritable(let url):
            return "Export directory is not writable: \(url.path)"
        case .exifToolNotFound:
            return "exiftool not found. Please install it with: brew install exiftool"
        case .exifToolFailed(let message):
            return "exiftool failed: \(message)"
        case .imageCropFailed:
            return "Failed to crop image."
        case .jsonWriteFailed:
            return "Failed to write JSON manifest."
        case .manifestWriteFailed:
            return "Failed to write manifest text file."
        case .outputAlreadyExists(let uuid):
            return "Output folder already exists for UUID \(uuid)."
        case .imageLoadFailed(let url):
            return "Failed to load image: \(url.lastPathComponent)"
        case .pairingFailed(let message):
            return "Pairing failed: \(message)"
        case .unknown(let message):
            return message
        }
    }
}
