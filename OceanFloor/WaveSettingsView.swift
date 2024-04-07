import Foundation
import SwiftUI

struct WaveSettingsView: View {

    @EnvironmentObject var settings: Settings

    var parameters: [ParameterView.Parameter] {
        [
            ("Wave Scale", $settings.waveHeightScale)
        ].map { .init(id: $0.0, binding: $0.1) }
    }

    var body: some View {
        ForEach(parameters) { parameter in
            ParameterView(parameter: parameter)
            Spacer()
        }
        ColorPicker("Wave Color", selection: $settings.waveColor)
    }
}
