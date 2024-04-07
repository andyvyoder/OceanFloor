import Foundation
import SwiftUI

class Settings: ObservableObject {
    @Published var waveHeightScale: Float = 0.3
    @Published var waveColor: Color = .init(cgColor: #colorLiteral(red: 0.106, green: 0.467, blue: 0.518, alpha: 1.0))
}

struct SettingsView: View {

    @StateObject var settings: Settings

    var body: some View {
        WaveSettingsView().environmentObject(settings)
    }
}

