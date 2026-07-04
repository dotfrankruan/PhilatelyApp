//
//  ScanSheetCanvasView.swift
//  PhilatelyApp
//

import SwiftUI
import AppKit

struct ScanSheetCanvasView: NSViewRepresentable {
    @ObservedObject var viewModel: RoundViewModel
    var onUpdate: (Region) -> Void
    var onDelete: (Region) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> CanvasNSView {
        let view = CanvasNSView()
        view.onUpdate = onUpdate
        view.onDelete = onDelete
        context.coordinator.view = view
        context.coordinator.viewModel = viewModel
        view.configure(with: viewModel)
        return view
    }

    func updateNSView(_ nsView: CanvasNSView, context: Context) {
        context.coordinator.viewModel = viewModel
        nsView.configure(with: viewModel)
    }

    final class Coordinator: NSObject {
        weak var view: CanvasNSView?
        weak var viewModel: RoundViewModel?
    }
}

final class CanvasNSView: NSView {
    var onUpdate: ((Region) -> Void)?
    var onDelete: ((Region) -> Void)?

    fileprivate var imageView: NSImageView?
    private var overlayView: NSView?
    private var regionViews: [UUID: RegionOverlayView] = [:]
    fileprivate var imagePixelSize: CGSize = .zero

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        let imageView = NSImageView(frame: bounds)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.autoresizingMask = [.width, .height]
        addSubview(imageView)
        self.imageView = imageView

        let overlayView = NSView(frame: bounds)
        overlayView.autoresizingMask = [.width, .height]
        overlayView.wantsLayer = true
        addSubview(overlayView)
        self.overlayView = overlayView
    }

    func configure(with viewModel: RoundViewModel) {
        let url = viewModel.currentScanSheet?.imageURL
        if imageView?.image == nil || (url != nil && imageView?.image != NSImage(contentsOf: url!)) {
            setImageURL(url)
        }
        refreshOverlays(with: viewModel.currentRegions)
    }

    func setImageURL(_ url: URL?) {
        guard let url else {
            imageView?.image = nil
            imagePixelSize = .zero
            return
        }
        let image = NSImage(contentsOf: url)
        imageView?.image = image
        if let cgImage = image?.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            imagePixelSize = CGSize(width: cgImage.width, height: cgImage.height)
        } else {
            imagePixelSize = image?.size ?? .zero
        }
        refreshOverlays()
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        refreshOverlays()
    }

    private func refreshOverlays(with regions: [Region]? = nil) {
        guard let overlayView, let imageView else { return }
        let currentRegions = regions ?? regionViews.values.map(\.region)

        let existingIDs = Set(regionViews.keys)
        let newIDs = Set(currentRegions.map(\.id))
        for id in existingIDs.subtracting(newIDs) {
            regionViews[id]?.removeFromSuperview()
            regionViews.removeValue(forKey: id)
        }

        let imageBounds = imageView.imageBounds
        guard imageBounds.width > 0, imageBounds.height > 0, imagePixelSize.width > 0, imagePixelSize.height > 0 else { return }

        let scaleX = imageBounds.width / imagePixelSize.width
        let scaleY = imageBounds.height / imagePixelSize.height

        for region in currentRegions {
            let y = imagePixelSize.height - region.cropRect.origin.y - region.cropRect.height
            let frame = CGRect(
                x: imageBounds.minX + region.cropRect.minX * scaleX,
                y: imageBounds.minY + y * scaleY,
                width: region.cropRect.width * scaleX,
                height: region.cropRect.height * scaleY
            )
            if let existing = regionViews[region.id] {
                existing.frame = frame
                existing.region = region
            } else {
                let overlay = RegionOverlayView(frame: frame, region: region)
                overlay.onUpdate = { [weak self] updated in
                    self?.onUpdate?(updated)
                }
                overlay.onDelete = { [weak self] deleted in
                    self?.onDelete?(deleted)
                }
                overlayView.addSubview(overlay)
                regionViews[region.id] = overlay
            }
        }
    }

    fileprivate func imageBoundsToPixelRect(_ frame: CGRect) -> CGRect {
        guard let imageView else { return frame }
        let imageBounds = imageView.imageBounds
        let scaleX = imagePixelSize.width / imageBounds.width
        let scaleY = imagePixelSize.height / imageBounds.height
        let x = (frame.minX - imageBounds.minX) * scaleX
        let y = (frame.minY - imageBounds.minY) * scaleY
        let w = frame.width * scaleX
        let h = frame.height * scaleY
        return CGRect(
            x: x,
            y: imagePixelSize.height - y - h,
            width: w,
            height: h
        )
    }
}

private extension NSImageView {
    var imageBounds: CGRect {
        guard let image else { return bounds }
        let imageSize = image.size
        let viewSize = bounds.size
        let aspect = imageSize.width / imageSize.height
        let viewAspect = viewSize.width / viewSize.height
        let rect: CGRect
        if aspect > viewAspect {
            let width = viewSize.width
            let height = width / aspect
            rect = CGRect(x: 0, y: (viewSize.height - height) / 2, width: width, height: height)
        } else {
            let height = viewSize.height
            let width = height * aspect
            rect = CGRect(x: (viewSize.width - width) / 2, y: 0, width: width, height: height)
        }
        return rect
    }
}

private final class RegionOverlayView: NSView {
    var region: Region
    var onUpdate: ((Region) -> Void)?
    var onDelete: ((Region) -> Void)?

    private var trackingArea: NSTrackingArea?
    private var dragStartSuper: NSPoint = .zero
    private var initialFrame: CGRect = .zero
    private var activeHandle: Handle = .none
    private let handleInset: CGFloat = 12

    private enum Handle {
        case none, topLeft, topRight, bottomLeft, bottomRight
    }

    init(frame frameRect: NSRect, region: Region) {
        self.region = region
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.08).cgColor
        layer?.borderColor = NSColor.controlAccentColor.cgColor
        layer?.borderWidth = 2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea { removeTrackingArea(trackingArea) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow], owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingArea = area
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let context = NSGraphicsContext.current?.cgContext
        context?.setFillColor(NSColor.controlAccentColor.cgColor)
        for handle in [Handle.topLeft, .topRight, .bottomLeft, .bottomRight] {
            context?.fill(handleRect(for: handle))
        }

        let label = "\(region.index)"
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.boldSystemFont(ofSize: 14),
            .backgroundColor: NSColor.controlAccentColor
        ]
        let size = label.size(withAttributes: attributes)
        let labelRect = CGRect(x: 4, y: bounds.height - size.height - 8, width: size.width + 8, height: size.height + 4)
        context?.setFillColor(NSColor.controlAccentColor.cgColor)
        context?.fill(labelRect)
        label.draw(at: CGPoint(x: labelRect.minX + 4, y: labelRect.minY + 2), withAttributes: attributes)
    }

    private func handleRect(for handle: Handle) -> CGRect {
        switch handle {
        case .topLeft: return CGRect(x: 0, y: bounds.height - handleInset, width: handleInset, height: handleInset)
        case .topRight: return CGRect(x: bounds.width - handleInset, y: bounds.height - handleInset, width: handleInset, height: handleInset)
        case .bottomLeft: return CGRect(x: 0, y: 0, width: handleInset, height: handleInset)
        case .bottomRight: return CGRect(x: bounds.width - handleInset, y: 0, width: handleInset, height: handleInset)
        case .none: return .zero
        }
    }

    private func handle(at point: NSPoint) -> Handle {
        for handle in [Handle.topLeft, .topRight, .bottomLeft, .bottomRight] {
            if handleRect(for: handle).contains(point) { return handle }
        }
        return .none
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        let local = convert(event.locationInWindow, from: nil)
        if event.clickCount == 2 {
            onDelete?(region)
            return
        }
        activeHandle = handle(at: local)
        dragStartSuper = superview?.convert(event.locationInWindow, from: nil) ?? .zero
        initialFrame = frame
    }

    override func mouseDragged(with event: NSEvent) {
        guard let superview else { return }
        let superPoint = superview.convert(event.locationInWindow, from: nil)

        var newFrame: CGRect
        switch activeHandle {
        case .none:
            newFrame = CGRect(
                x: initialFrame.minX + (superPoint.x - dragStartSuper.x),
                y: initialFrame.minY + (superPoint.y - dragStartSuper.y),
                width: initialFrame.width,
                height: initialFrame.height
            )
        case .topLeft:
            let anchor = CGPoint(x: initialFrame.maxX, y: initialFrame.minY)
            newFrame = CGRect(x: min(superPoint.x, anchor.x), y: min(superPoint.y, anchor.y), width: abs(superPoint.x - anchor.x), height: abs(superPoint.y - anchor.y))
        case .topRight:
            let anchor = CGPoint(x: initialFrame.minX, y: initialFrame.minY)
            newFrame = CGRect(x: min(superPoint.x, anchor.x), y: min(superPoint.y, anchor.y), width: abs(superPoint.x - anchor.x), height: abs(superPoint.y - anchor.y))
        case .bottomLeft:
            let anchor = CGPoint(x: initialFrame.maxX, y: initialFrame.maxY)
            newFrame = CGRect(x: min(superPoint.x, anchor.x), y: min(superPoint.y, anchor.y), width: abs(superPoint.x - anchor.x), height: abs(superPoint.y - anchor.y))
        case .bottomRight:
            let anchor = CGPoint(x: initialFrame.minX, y: initialFrame.maxY)
            newFrame = CGRect(x: min(superPoint.x, anchor.x), y: min(superPoint.y, anchor.y), width: abs(superPoint.x - anchor.x), height: abs(superPoint.y - anchor.y))
        }

        newFrame.size.width = max(20, newFrame.size.width)
        newFrame.size.height = max(20, newFrame.size.height)
        self.frame = newFrame
    }

    override func mouseUp(with event: NSEvent) {
        guard let canvas = superview?.superview as? CanvasNSView else {
            activeHandle = .none
            return
        }
        let imageBounds = canvas.imageView?.imageBounds ?? canvas.bounds
        var newFrame = self.frame
        newFrame.origin.x = max(imageBounds.minX, min(newFrame.minX, imageBounds.maxX - newFrame.width))
        newFrame.origin.y = max(imageBounds.minY, min(newFrame.minY, imageBounds.maxY - newFrame.height))
        self.frame = newFrame

        let pixelRect = canvas.imageBoundsToPixelRect(newFrame)
        var updated = region
        updated.cropRect = pixelRect
        updated.isAdjustedManually = true
        region = updated
        onUpdate?(region)
        activeHandle = .none
    }
}
