import SwiftUI

@main
struct DrivePodApp: App {
    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environmentObject(LibraryService.shared)
                .environmentObject(PlayerService.shared)
        }
    }
}
