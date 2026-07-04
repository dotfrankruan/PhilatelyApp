# PhilatelyApp

A local macOS SwiftUI utility for semi-automatically processing scanned philatelic items (stamps, postcards, covers, etc.).

## What it does

PhilatelyApp helps you turn large front/back scan sheets into individual, keyworded, catalogued items.

Typical workflow:

1. Create a new **Round**.
2. Import a **front** scan sheet.
3. Import a **back** scan sheet.
4. Manually add/adjust crop regions on each sheet.
5. Auto-pair front regions with back regions by index.
6. Open each item, add keywords, manifest, notes, and extra images.
7. Save to export a UUID-named folder with cropped images, JSON metadata, and optional manifest text.

## Requirements

- macOS 14+ (built with SwiftUI + AppKit bridges)
- Xcode 15+
- [exiftool](https://exiftool.org/) installed on your Mac:

```bash
brew install exiftool
```

## Important notes

- This is a local, self-use tool. App Sandbox is disabled in this MVP so exiftool and folder export work without entitlement friction.
- Source scans are never modified. All output goes to the export directory you choose.
- Automatic region detection is disabled by default in this version because it was not reliable enough; use **Add Region** and manual resize instead.

## Keyboard / mouse shortcuts

| Action | Shortcut |
|--------|----------|
| Move region | Drag inside a region box |
| Resize region | Drag one of the four corner handles |
| Delete region | Double-click a region box |
| Zoom image | Cmd/Ctrl + scroll wheel |

## Export output

For each saved item a folder named after the item UUID is created:

```
Export/
└── abcdef123456/
    ├── abcdef123456-front.jpg
    ├── abcdef123456-back.jpg
    ├── abcdef123456-extra-1.jpg
    ├── abcdef123456-content-1.jpg
    ├── abcdef123456.json
    └── abcdef123456.txt      # only if manifest is non-empty
```

All exported images receive these IPTC / XMP keywords:

- `<16-char UUID>`
- `philately`
- every keyword you entered manually

## Project structure

```
PhilatelyApp/
├── Models/          # Round, ScanSheet, Region, PhilatelyItem, Asset
├── Views/           # RoundView, ScanSheetCanvasView, ItemDetailView, etc.
├── ViewModels/      # RoundViewModel, ItemDetailViewModel
├── Services/        # ExportService, ImageCropService, ExifToolMetadataWriter, etc.
└── Utilities/       # Helpers and extensions
```

## Known limitations / TODO

- No automatic region detection in this build.
- No built-in scanner integration.
- No Apple Photos integration.
- Extra / content images are copied as-is; cropping them is not yet supported.
- App Sandbox is disabled. If you re-enable it later, add the appropriate entitlements and security-scoped bookmarks.
