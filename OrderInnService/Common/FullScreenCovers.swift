//
//  FullScreenCovers.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 20/04/2021.
//

import SwiftUI

struct ToZoneView: View {
    @ObservedObject var qrscanner: QrCodeScannerWork
    var body: some View {
        ZoneSelection(qrScanner: qrscanner)
    }
}

struct ToQrScannerView: View{
    var body: some View{
        QrScannerView()
    }
}
