//
//  QrCodeScannerView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 15/04/2021.
//

import SwiftUI
import Combine
import AVFoundation

struct QrCodeScannerView: UIViewControllerRepresentable{
    @Binding var restaurant: String
    @Binding var kitchen: String?
    @Binding var alertItem: AlertItem?
    
    func makeUIViewController(context: Context) -> QrScannerViewController {
        QrScannerViewController(scannerDelegate: context.coordinator)
    }
    func updateUIViewController(_ uiViewController: QrScannerViewController, context: Context) {
        if alertItem != nil{
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                uiViewController.session.startRunning()
            })
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(qrScannerView: self)
    }
    
    class Coordinator: NSObject, ScannerVCDelegate{
        private var qrScannerView: QrCodeScannerView
        
        init(qrScannerView: QrCodeScannerView){
            self.qrScannerView = qrScannerView
        }
        
        func didFind(qrCode: QRURL) {
            qrScannerView.restaurant = qrCode.restaurant
            qrScannerView.kitchen = qrCode.kitchen
        }
        
        func didSurface(error: CameraError) {
            switch error {
            case .invalidDeviceInput:
                qrScannerView.alertItem = AlertContext.invalidDevice
            case .invalidCodeFormat:
                qrScannerView.alertItem = AlertContext.invalidCodeFormat
            case .invalidQrCode:
                qrScannerView.alertItem = AlertContext.invalidQrCode
            }
        }
    }
}
