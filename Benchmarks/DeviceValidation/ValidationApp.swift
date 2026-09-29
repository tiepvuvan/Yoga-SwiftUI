import SwiftUI

@main
struct ValidationApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.rectangle.stack")
                    .font(.largeTitle)
                Text("Yoga Validation").font(.title)
                Text("Development tests are controlled from Xcode.")
            }
            .padding()
            .task { DeviceBenchmark.runIfRequested() }
        }
    }
}
