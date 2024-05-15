//
//  BatteryViewModel.swift
//  YaneuraOuWatch Watch App
//
//  Created by 日高雅俊 on 2024/05/14.
//

import Foundation
import SwiftUI

@Observable class BatteryViewModel {
    private let device = WKInterfaceDevice.current()
    var batteryLevel: Float
    var batteryState: WKInterfaceDeviceBatteryState

    init() {
        device.isBatteryMonitoringEnabled = true
        batteryLevel = device.batteryLevel
        batteryState = device.batteryState
        Timer.scheduledTimer(timeInterval: 10,
                             target: self,
                             selector: #selector(BatteryViewModel.timerUpdate),
                             userInfo: nil,
                             repeats: true)
    }

    @objc func timerUpdate() {
        batteryLevel = device.batteryLevel
        batteryState = device.batteryState
    }
}
