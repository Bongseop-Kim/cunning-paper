import AppKit
import SwiftData
import SwiftUI

@main
struct CunningPaperApp: App {
    @State private var coordinator = AppCoordinator()

    static let modelContainer: ModelContainer = {
        let schema = Schema(versionedSchema: CunningPaperSchemaV3.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: CunningPaperMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup("CunningPaper") {
            EditorView()
                .environment(coordinator)
                .modelContainer(Self.modelContainer)
                .task {
                    coordinator.setup(modelContainer: Self.modelContainer)
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 980, height: 680)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
