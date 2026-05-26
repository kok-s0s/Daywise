import Foundation
import Observation

@Observable
final class CategoryStore {
    static let shared = CategoryStore()

    private let key = "customCategories"

    static let defaults: [String] = ["数码", "家电", "服饰", "家居", "运动", "美妆", "书籍", "其他"]

    private(set) var customCategories: [String]

    init() {
        self.customCategories = UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    var all: [String] {
        var combined = CategoryStore.defaults
        for c in customCategories where !combined.contains(c) {
            combined.append(c)
        }
        return combined
    }

    func add(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !all.contains(trimmed) else { return }
        customCategories.append(trimmed)
        UserDefaults.standard.set(customCategories, forKey: key)
    }
}
