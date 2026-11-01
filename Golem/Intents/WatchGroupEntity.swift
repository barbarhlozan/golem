import AppIntents
import GolemKit

/// A Golem group as Shortcuts sees it, so an automation can say
/// "When Instagram is opened → Golem: App Opened in *Social*".
struct WatchGroupEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Golem Group"
    static let defaultQuery = WatchGroupQuery()

    let id: UUID
    let name: String

    init(_ group: WatchGroup) {
        id = group.id
        name = group.name
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct WatchGroupQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [WatchGroupEntity] {
        SharedStore().settings.groups
            .filter { identifiers.contains($0.id) }
            .map(WatchGroupEntity.init)
    }

    func suggestedEntities() async throws -> [WatchGroupEntity] {
        SharedStore().settings.groups.map(WatchGroupEntity.init)
    }
}
