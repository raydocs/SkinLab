import Foundation
import SwiftData

// MARK: - Routine Phase
enum RoutinePhase: String, Codable, CaseIterable, Sendable {
    case am, pm
    
    var displayName: String {
        switch self {
        case .am: return "早上"
        case .pm: return "晚上"
        }
    }
}

// MARK: - Routine Goal
enum RoutineGoal: String, Codable, CaseIterable, Sendable {
    case acne
    case sensitivity
    case dryness
    case pores
    case pigmentation
    case antiAging
    
    var displayName: String {
        switch self {
        case .acne: return "控痘祛痘"
        case .sensitivity: return "舒缓敏感"
        case .dryness: return "补水保湿"
        case .pores: return "细致毛孔"
        case .pigmentation: return "淡化色斑"
        case .antiAging: return "抗衰老化"
        }
    }
}

// MARK: - Routine Step
struct RoutineStep: Codable, Identifiable, Sendable, Equatable, Hashable {
    let id: UUID
    let phase: RoutinePhase
    let order: Int
    let title: String
    let productType: String
    let instructions: String
    let frequency: String
    let precautions: [String]
    let alternatives: [String]
    
    init(id: UUID = UUID(), phase: RoutinePhase, order: Int, title: String, productType: String, instructions: String, frequency: String, precautions: [String] = [], alternatives: [String] = []) {
        self.id = id
        self.phase = phase
        self.order = order
        self.title = title
        self.productType = productType
        self.instructions = instructions
        self.frequency = frequency
        self.precautions = precautions
        self.alternatives = alternatives
    }
}

// MARK: - Skincare Routine
struct SkincareRoutine: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    let generatedAt: Date
    let skinType: SkinType?
    let concerns: [SkinConcern]
    let goals: [RoutineGoal]
    let steps: [RoutineStep]
    let notes: [String]
    let weeksDuration: Int
    
    init(id: UUID = UUID(), generatedAt: Date = Date(), skinType: SkinType?, concerns: [SkinConcern], goals: [RoutineGoal], steps: [RoutineStep], notes: [String], weeksDuration: Int = 4) {
        self.id = id
        self.generatedAt = generatedAt
        self.skinType = skinType
        self.concerns = concerns
        self.goals = goals
        self.steps = steps
        self.notes = notes
        self.weeksDuration = weeksDuration
    }
    
    var amSteps: [RoutineStep] {
        steps.filter { $0.phase == .am }.sorted { $0.order < $1.order }
    }
    
    var pmSteps: [RoutineStep] {
        steps.filter { $0.phase == .pm }.sorted { $0.order < $1.order }
    }
}

// MARK: - SwiftData Record
@Model
final class SkincareRoutineRecord {
    @Attribute(.unique) var id: UUID
    var generatedAt: Date
    var skinTypeRaw: String?
    var concernsRaw: [String]
    var goalsRaw: [String]
    var stepsData: Data?
    var notes: [String]
    var weeksDuration: Int
    
    init(from routine: SkincareRoutine) {
        self.id = routine.id
        self.generatedAt = routine.generatedAt
        self.skinTypeRaw = routine.skinType?.rawValue
        self.concernsRaw = routine.concerns.map { $0.rawValue }
        self.goalsRaw = routine.goals.map { $0.rawValue }
        self.stepsData = try? JSONEncoder().encode(routine.steps)
        self.notes = routine.notes
        self.weeksDuration = routine.weeksDuration
    }
    
    func toRoutine() -> SkincareRoutine? {
        let steps = (try? stepsData.flatMap { try JSONDecoder().decode([RoutineStep].self, from: $0) }) ?? []
        return SkincareRoutine(
            id: id,
            generatedAt: generatedAt,
            skinType: skinTypeRaw.flatMap { SkinType(rawValue: $0) },
            concerns: concernsRaw.compactMap { SkinConcern(rawValue: $0) },
            goals: goalsRaw.compactMap { RoutineGoal(rawValue: $0) },
            steps: steps,
            notes: notes,
            weeksDuration: weeksDuration
        )
    }
}
