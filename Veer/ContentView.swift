import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")

            Button(action: {
                print("Button clicked")
            }) {
                Text("Create an account")
            }
            .buttonStyle(.glass) // or any style you like
        }
    }
}

#Preview {
    ContentView()
}
