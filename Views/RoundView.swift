//
//  RoundView.swift
//  PhilatelyApp
//

import SwiftUI

struct RoundView: View {
    @StateObject var viewModel = RoundViewModel()

    var body: some View {
        NavigationStack {
            HSplitView {
                scanPane
                    .frame(minWidth: 500)
                itemPane
                    .frame(minWidth: 260)
            }
            .toolbar { toolbarItems }
            .alert("All items completed", isPresented: $viewModel.showCompletionAlert) {
                Button("Start New Round") { viewModel.newRound() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All items in this round are completed. Start a new round?")
            }
            .sheet(item: $viewModel.selectedItem) { item in
                itemDetailSheet(item: item)
            }
        }
    }

    private var scanPane: some View {
        VStack(spacing: 0) {
            if viewModel.currentScanSheet?.imageURL != nil {
                ScanSheetCanvasView(
                    viewModel: viewModel,
                    onUpdate: { region in
                        viewModel.updateRegion(region)
                    },
                    onDelete: { region in
                        viewModel.removeRegion(region)
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                emptyScanPlaceholder
            }

            HStack(spacing: 12) {
                Picker("Side", selection: $viewModel.selectedSide) {
                    Text("Front").tag(SheetSide.front)
                    Text("Back").tag(SheetSide.back)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)

                if viewModel.regionCountMismatch {
                    Text("Region count mismatch")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Spacer()

                if viewModel.currentScanSheet?.imageURL != nil {
                    Button("-") { viewModel.zoomOutCanvas() }
                    Text("\(Int(viewModel.canvasScale * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 40)
                    Button("+") { viewModel.zoomInCanvas() }
                    Button("Reset Zoom") { viewModel.resetCanvasScale() }
                }

                Button("Add Region") { viewModel.addRegion() }
                    .disabled(viewModel.currentScanSheet == nil)
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
        }
    }

    private var emptyScanPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Import a front or back scan to begin")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var itemPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Items")
                .font(.headline)
                .padding()

            if viewModel.items.isEmpty {
                Spacer()
                Text("No items yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ItemListView(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id("items-\(viewModel.items.count)-\(viewModel.items.map(\.isCompleted).description)")
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
            }
        }
    }

    private var toolbarItems: some ToolbarContent {
        ToolbarItemGroup {
            Button("New Round") { viewModel.newRound() }
            Button("Import Front") { viewModel.importFrontScan() }
            Button("Import Back") { viewModel.importBackScan() }
            Button("Auto Pair") { viewModel.autoPair() }
                .disabled(!viewModel.canAutoPair)
            Button("Export Folder") { viewModel.selectExportDirectory() }
            Button("Open Export") { viewModel.openExportFolder() }
            if viewModel.round.exportDirectory != nil {
                Text(viewModel.round.exportDirectory!.lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func itemDetailSheet(item: PhilatelyItem) -> some View {
        let detailVM = ItemDetailViewModel(
            item: item,
            round: viewModel.round,
            exportService: viewModel.exportService,
            recentStore: viewModel.recentStore,
            onSave: { saved in
                viewModel.updateItem(saved)
                viewModel.selectedItem = nil
            }
        )
        return ItemDetailView(viewModel: detailVM)
    }
}
