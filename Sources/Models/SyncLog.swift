import Foundation

struct SyncLog: Codable, Identifiable {
    let id: UUID
    let date: Date
    let glucoseSynced: Int
    let insulinSynced: Int
    let carbsSynced: Int
    let errors: [String]

    init(date: Date, glucoseSynced: Int, insulinSynced: Int, carbsSynced: Int, errors: [String]) {
        self.id = UUID()
        self.date = date
        self.glucoseSynced = glucoseSynced
        self.insulinSynced = insulinSynced
        self.carbsSynced = carbsSynced
        self.errors = errors
    }

    var totalSynced: Int { glucoseSynced + insulinSynced + carbsSynced }
    var hasErrors: Bool { !errors.isEmpty }
}
