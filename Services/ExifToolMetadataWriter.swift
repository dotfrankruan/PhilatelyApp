//
//  ExifToolMetadataWriter.swift
//  PhilatelyApp
//

import Foundation

final class ExifToolMetadataWriter: MetadataWriter {
    var executableURL: URL?

    init(executableURL: URL? = nil) {
        self.executableURL = executableURL
    }

    func writeKeywords(_ keywords: [String], to imageURL: URL) throws {
        let url = try resolveExecutable()

        var arguments: [String] = ["-overwrite_original"]
        for keyword in keywords {
            arguments.append("-IPTC:Keywords+=\(keyword)")
            arguments.append("-XMP-dc:Subject+=\(keyword)")
        }
        arguments.append(imageURL.path)

        let process = Process()
        process.executableURL = url
        process.arguments = arguments

        let errorPipe = Pipe()
        process.standardError = errorPipe
        process.standardOutput = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown error"
            throw PhilatelyError.exifToolFailed(message)
        }
    }

    private func resolveExecutable() throws -> URL {
        if let url = executableURL {
            if FileManager.default.isExecutableFile(atPath: url.path) {
                return url
            }
        }

        let candidates = [
            URL(fileURLWithPath: "/opt/homebrew/bin/exiftool"),
            URL(fileURLWithPath: "/usr/local/bin/exiftool")
        ]
        for url in candidates {
            if FileManager.default.isExecutableFile(atPath: url.path) {
                return url
            }
        }

        let whichProcess = Process()
        whichProcess.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        whichProcess.arguments = ["exiftool"]
        let pipe = Pipe()
        whichProcess.standardOutput = pipe
        try? whichProcess.run()
        whichProcess.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !path.isEmpty {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.isExecutableFile(atPath: url.path) {
                return url
            }
        }

        throw PhilatelyError.exifToolNotFound
    }
}
