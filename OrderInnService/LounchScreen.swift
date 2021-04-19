//
//  LounchScreen.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/04/2021.
//

import SwiftUI

struct LounchScreen: View {
    @ObservedObject var qrScannerWork = QrCodeScannerWork()

    var body: some View {
        if UserDefaults.standard.startScreen{
            ZoneSelection(restaurant: qrScannerWork.restaurant)
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
