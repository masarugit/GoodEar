import SwiftUI

@main
struct GoodEarApp: App {
    init() {
        NSLog("🔔 GoodEarApp initialized")
    }
    var body: some Scene {
        WindowGroup {
            LessonListView()
                .onAppear {
                    NSLog("👀 GoodEarApp: LessonListView appeared")
                }
        }
    }
}
