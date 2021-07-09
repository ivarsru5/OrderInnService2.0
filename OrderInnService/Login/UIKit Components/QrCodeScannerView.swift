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
    @EnvironmentObject var authManager: AuthManager
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
        Coordinator(authManager: authManager, alertItem: $alertItem)
    }
    
    class Coordinator: NSObject, ScannerVCDelegate {
        let authManager: AuthManager
        let alertItem: Binding<AlertItem?>

        init(authManager: AuthManager, alertItem: Binding<AlertItem?>) {
            self.authManager = authManager
            self.alertItem = alertItem
        }

        private var _authManagerLoginCancellable: AnyCancellable!
        func didFind(qrCode: LoginQRCode) {
            _authManagerLoginCancellable = authManager.logIn(using: qrCode).sink(receiveCompletion: {
                result in
                if case .failure(_) = result {
                    // TODO: show error...
                }
            }, receiveValue: { _ in })
        }
        
        func didSurface(error: CameraError) {
            switch error {
            case .invalidDeviceInput:
                alertItem.wrappedValue = AlertContext.invalidDevice
            case .invalidCodeFormat:
                alertItem.wrappedValue = AlertContext.invalidCodeFormat
            case .invalidQrCode:
                alertItem.wrappedValue = AlertContext.invalidQrCode
            }
        }
    }
}
