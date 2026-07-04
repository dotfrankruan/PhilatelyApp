//
//  KeywordEditorView.swift
//  PhilatelyApp
//

import SwiftUI

struct KeywordEditorView: View {
    @Binding var keywords: [String]
    @ObservedObject var recentStore: RecentKeywordsStore

    @State private var input: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Keywords").font(.headline)

            HStack {
                TextField("Add keyword", text: $input)
                    .onSubmit(addInput)
                Button("Add") { addInput() }
                    .keyboardShortcut(.defaultAction)
            }

            if !keywords.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(keywords, id: \.self) { keyword in
                        HStack(spacing: 4) {
                            Text(keyword)
                                .lineLimit(1)
                            Button(action: { remove(keyword) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(8)
                    }
                }
            }

            if !recentStore.keywords.isEmpty {
                Text("Recent").font(.subheadline).foregroundStyle(.secondary)
                FlowLayout(spacing: 8) {
                    ForEach(recentStore.keywords, id: \.self) { keyword in
                        Button(keyword) {
                            add(keyword)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(keywords.contains(keyword))
                    }
                }
            }
        }
    }

    private func addInput() {
        add(input)
        input = ""
    }

    private func add(_ keyword: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !keywords.contains(trimmed) else { return }
        keywords.append(trimmed)
    }

    private func remove(_ keyword: String) {
        keywords.removeAll { $0 == keyword }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    private struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                x += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}
