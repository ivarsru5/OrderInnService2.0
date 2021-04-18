//
//  AlertItem.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 15/04/2021.
//

import SwiftUI
import AVFoundation

struct AlertItem: Identifiable{
    let id = UUID()
    let title: Text
    let message: Text
    let dismissButton: Alert.Button
}

struct AlertContext{
    static let invalidCodeFormat = AlertItem(title: Text("Error"),
                                         message: Text("This does not look like QR code. Please try again."),
                                         dismissButton: .default(Text("OK")))
    
    static let invalidDevice = AlertItem(title: Text("Something went wrong"),
                                         message: Text("Something is wrong with camera. We are unable to display it."),
                                         dismissButton: .default(Text("OK")))
    
    static let invalidQrCode = AlertItem(title: Text("Whoops..."),
                                         message: Text("This does not look like OrderInn Service qr code. Please try again."),
                                         dismissButton: .default(Text("OK")))
}
