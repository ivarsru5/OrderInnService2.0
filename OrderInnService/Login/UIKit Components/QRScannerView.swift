//
//  QRScannerView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 15/04/2021.
//

import SwiftUI
import Combine
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {
    @EnvironmentObject var authManager: AuthManager
    let alertTemplate: Binding<Alerts.Template?>
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        QRScannerViewController(scannerDelegate: context.coordinator)
    }
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {
        if alertTemplate.wrappedValue != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                uiViewController.session.startRunning()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(authManager: authManager, alertTemplate: alertTemplate)
    }
    
    class Coordinator: NSObject, QRScannerViewControllerDelegate {
        let authManager: AuthManager
        let alertTemplate: Binding<Alerts.Template?>

        init(authManager: AuthManager, alertTemplate: Binding<Alerts.Template?>) {
            self.authManager = authManager
            self.alertTemplate = alertTemplate
        }

        func didFind(qrCode: LoginQRCode) {
            var sub: AnyCancellable?
            sub = authManager.logIn(using: qrCode)
                .mapError { error in
                    // TODO[pn 2021-08-03]
                    fatalError("FIXME Failed to use QR code to log in: \(String(describing: error))")
                }
                .sink { _ in
                    if let _ = sub {
                        sub = nil
                    }
                }
        }
        
        func didSurface(error: QRScannerViewController.CameraError) {
            switch error {
            case .invalidDeviceInput:
                alertTemplate.wrappedValue = Alerts.invalidDevice
            case .invalidCodeFormat:
                alertTemplate.wrappedValue = Alerts.invalidCodeFormat
            case .invalidQRCode:
                alertTemplate.wrappedValue = Alerts.invalidQrCode
            }
        }
    }
}
