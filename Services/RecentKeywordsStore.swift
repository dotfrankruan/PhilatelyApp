//
//  RecentKeywordsStore.swift
//  PhilatelyApp
//

import Foundation
import Combine

final class RecentKeywordsStore: ObservableObject {
    @Published var keywords: [String] = []

    private let defaultsKey = "com.philatelyapp.recentKeywords"
    private let maxCount = 50

    init() {
        load()
    }

    func add(_ keyword: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        keywords.removeAll { $0 == trimmed }
        keywords.insert(trimmed, at: 0)
        if keywords.count > maxCount {
            keywords = Array(keywords.prefix(maxCount))
        }
        save()
    }

    func addKeywords(_ keywords: [String]) {
        for keyword in keywords {
            add(keyword)
        }
    }

    func remove(_ keyword: String) {
        keywords.removeAll { $0 == keyword }
        save()
    }

    private func load() {
        guard let saved = UserDefaults.standard.array(forKey: defaultsKey) as? [String] else { return }
        keywords = saved
    }

    private func save() {
        UserDefaults.standard.set(keywords, forKey: defaultsKey)
    }
}
