//
//  OrderInnServiceApp.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 15/04/2021.
//

import SwiftUI
import Firebase

@main
struct OrderInnServiceApp: App {
    @StateObject var qrScanner: QrCodeScannerWork
    
    init(){
        FirebaseApp.configure()
        let scanner = QrCodeScannerWork()
        _qrScanner = StateObject(wrappedValue: scanner)
    }
    
    var body: some Scene {
        WindowGroup {
            LounchScreen()
                .environmentObject(qrScanner)
        }
    }
}
