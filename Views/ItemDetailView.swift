//
//  ItemDetailView.swift
//  PhilatelyApp
//

import SwiftUI

struct ItemDetailView: View {
    @StateObject var viewModel: ItemDetailViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    previews
                    backRegionPicker
                    extraAssets
                    KeywordEditorView(keywords: $viewModel.item.keywords, recentStore: viewModel.recentStore)
                    manifestEditor
                    notesEditor
                    errorArea
                }
                .padding()
            }

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                if viewModel.isSaving {
                    ProgressView()
                }
                Button("Save") { viewModel.save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(viewModel.isSaving)
            }
            .padding()
        }
        .frame(minWidth: 700, minHeight: 600)
        .onChange(of: viewModel.item.isCompleted) { _, completed in
            if completed {
                dismiss()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Item \(viewModel.item.indexInRound)")
                .font(.title)
            if let uuid = viewModel.item.uuid {
                Text(uuid)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            } else {
                Text("UUID will be assigned on save")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private var previews: some View {
        HStack {
            if let front = viewModel.item.frontRegion,
               let url = viewModel.round.frontScan?.imageURL {
                ThumbnailView(title: "Front", sourceURL: url, cropRect: front.cropRect)
            } else {
                missingView("No front")
            }

            if let back = viewModel.item.backRegion,
               let url = viewModel.round.backScan?.imageURL {
                ThumbnailView(title: "Back", sourceURL: url, cropRect: back.cropRect)
            } else {
                missingView("No back")
            }
        }
    }

    private var backRegionPicker: some View {
        Group {
            if !viewModel.availableBackRegions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Back Region").font(.subheadline).foregroundStyle(.secondary)
                    Picker("", selection: Binding<UUID?>(
                        get: { viewModel.item.backRegion?.id },
                        set: { id in
                            viewModel.replaceBack(with: viewModel.availableBackRegions.first { $0.id == id })
                        }
                    )) {
                        Text("None").tag(nil as UUID?)
                        ForEach(viewModel.availableBackRegions) { region in
                            Text("Back \(region.index)").tag(region.id as UUID?)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    private var extraAssets: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Extra / Content").font(.headline)
            HStack {
                Button("Add Extra") { viewModel.addExtra() }
                Button("Add Content") { viewModel.addContent() }
            }
            ForEach(viewModel.item.extraAssets) { asset in
                HStack {
                    Text(asset.sourceImageURL.lastPathComponent)
                    Spacer()
                    Text(asset.role.rawValue.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Remove") { viewModel.removeExtraAsset(asset) }
                }
            }
        }
    }

    private var manifestEditor: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Manifest").font(.headline)
            TextEditor(text: $viewModel.item.manifest)
                .frame(minHeight: 80)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))
        }
    }

    private var notesEditor: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Notes").font(.headline)
            TextEditor(text: $viewModel.item.notes)
                .frame(minHeight: 80)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))
        }
    }

    private var errorArea: some View {
        Group {
            if let message = viewModel.errorMessage {
                Text(message)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    private func missingView(_ text: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
            Text(text)
                .foregroundStyle(.secondary)
        }
        .frame(height: 160)
    }
}

private struct ThumbnailView: View {
    let title: String
    let sourceURL: URL
    let cropRect: CGRect

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption)
            GeometryReader { geo in
                if let nsImage = NSImage(contentsOf: sourceURL) {
                    CroppedImageView(nsImage: nsImage, cropRect: cropRect)
                } else {
                    Color.secondary.opacity(0.1)
                }
            }
            .frame(height: 160)
            .clipped()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct CroppedImageView: NSViewRepresentable {
    let nsImage: NSImage
    let cropRect: CGRect

    func makeNSView(context: Context) -> NSImageView {
        let view = NSImageView()
        view.image = croppedImage()
        view.imageScaling = .scaleAxesIndependently
        return view
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        nsView.image = croppedImage()
        nsView.imageScaling = .scaleAxesIndependently
    }

    private func croppedImage() -> NSImage? {
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let imageHeight = CGFloat(cgImage.height)
        let y = imageHeight - cropRect.origin.y - cropRect.height
        let rect = CGRect(x: cropRect.origin.x, y: y, width: cropRect.width, height: cropRect.height)
        guard let cropped = cgImage.cropping(to: rect) else { return nil }
        return NSImage(cgImage: cropped, size: NSSize(width: rect.width, height: rect.height))
    }
}
