//
//  ItemListView.swift
//  PhilatelyApp
//

import SwiftUI

struct ItemListView: View {
    @ObservedObject var viewModel: RoundViewModel

    var body: some View {
        List(viewModel.items) { item in
            ItemRow(item: item, backRegions: viewModel.round.backScan?.detectedRegions ?? [])
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.selectedItem = item
                }
                .background(viewModel.selectedItem?.id == item.id ? Color.accentColor.opacity(0.1) : Color.clear)
        }
    }
}

private struct ItemRow: View {
    let item: PhilatelyItem
    let backRegions: [Region]

    var body: some View {
        HStack {
            Text(item.isCompleted ? "✅" : "⬜")
            Text("\(item.indexInRound)")
                .font(.headline)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("F: \(item.frontRegion?.index ?? 0)")
                    .font(.caption)
                Text("B: \(item.backRegion?.index ?? 0)")
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}
