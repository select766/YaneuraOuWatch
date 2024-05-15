//
//  BatteryView.swift
//  YaneuraOuWatch Watch App
//
//  Created by 日高雅俊 on 2024/05/14.
//

import SwiftUI

struct BatteryView: View {
    var batteryViewModel = BatteryViewModel()
    
    var batteryStateText: String {
        switch batteryViewModel.batteryState {
        case .unknown:
            return "unknown"
        case .unplugged:
            return "unplugged"
        case .charging:
            return "charging"
        case .full:
            return "full"
        @unknown default:
            return "unknown"
        }
    }

    var body: some View {
        Text("\(Int(roundf(batteryViewModel.batteryLevel * 100)))% \(batteryStateText)")
    }
}

#Preview {
    BatteryView()
}
