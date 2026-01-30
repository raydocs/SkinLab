import Foundation

struct EvidenceEntry: Codable, Sendable, Identifiable {
    let ingredientName: String
    let level: EvidenceLevel
    let sources: [EvidenceSource]
    let studyCount: Int?
    let description: String?

    var id: String {
        ingredientName
    }
}

final class EvidenceStore: Sendable {
    static let shared = EvidenceStore()

    private let evidenceByKey: [String: EvidenceEntry]

    private init() {
        evidenceByKey = Self.loadEvidence()
    }

    func evidence(for key: String) -> EvidenceEntry? {
        evidenceByKey[key.lowercased()]
    }

    func evidence(forIngredientName name: String) -> EvidenceEntry? {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return evidenceByKey[normalized]
    }

    private static func loadEvidence() -> [String: EvidenceEntry] {
        guard let url = Bundle.main.url(forResource: "evidence", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: EvidenceEntry].self, from: data) else {
            return [:]
        }

        return decoded
    }
}
