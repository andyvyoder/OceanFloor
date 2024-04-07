/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's content view.
*/

import SwiftUI
import RealityKit
import ARKit
import Combine
import MetalKit

struct ContentView: View {
    @State private var showDebugOptions: Bool = false
    @StateObject var settings = Settings()

    var body: some View {
        // Scene + Debug (optional)
        HStack {

            // Scene
            ZStack {

                // Viewport
                ARViewContainer(settings: settings)
  
                // Buttons (on top of the viewport)
                HStack {
                    VStack {
                        Button(
                            action: { showDebugOptions = !showDebugOptions },
                            label: { Text("⚙️").font(.system(size: 30, weight: .bold)) }
                        )
                        Spacer()
                    }
                    Spacer()
                }
            }

            // Debug options (optional; on the right)
            if showDebugOptions {
                ScrollView {

                    Group {
                        SettingsView(settings: settings)
                    }.frame(maxWidth: 250).padding(10)
                }
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    private var settings: Settings

    public init(settings: Settings) {
        self.settings = settings
    }

    func makeUIView(context: Context) -> OceanView {
        let arView = OceanView(frame: .zero, settings: settings)
        arView.setup()
        return arView
    }

    func updateUIView(_ view: OceanView, context: Context) {
    }

}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
