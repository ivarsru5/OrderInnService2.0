//
//  LounchScreen.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/04/2021.
//

import SwiftUI

struct LounchScreen: View {
    @StateObject var qrScaner = QrCodeScannerWork()
    
    var body: some View {
        if UserDefaults.standard.startScreen{
            ZoneSelection(qrScanner: qrScaner)
        }else{
            QrScannerView()
        }
    }
}

struct LounchScreen_Previews: PreviewProvider {
    static var previews: some View {
        LounchScreen()
    }
}
