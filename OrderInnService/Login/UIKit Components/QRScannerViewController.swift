//
//  QRScannerViewController.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 15/04/2021.
//

import UIKit
import AVFoundation

protocol QRScannerViewControllerDelegate: AnyObject {
    func didFind(qrCode: LoginQRCode)
    func didSurface(error: QRScannerViewController.CameraError)
}

class QRScannerViewController: UIViewController {
    typealias Delegate = QRScannerViewControllerDelegate

    enum CameraError {
        case invalidDeviceInput
        case invalidCodeFormat
        case invalidQRCode
    }

    let session = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    weak var scannerDelegate: Delegate?
    
    init(scannerDelegate: Delegate) {
        super.init(nibName: nil, bundle: nil)
        self.scannerDelegate = scannerDelegate
    }
    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented for ScannerVC") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCameraSession()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let previewLayer = previewLayer else {
            scannerDelegate?.didSurface(error: .invalidDeviceInput)
            return
        }
        previewLayer.frame = view.layer.bounds
    }
    
    private func setupCameraSession(){
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            scannerDelegate?.didSurface(error: .invalidDeviceInput)
            return
        }
        let videoInput: AVCaptureDeviceInput
        
        do {
            try videoInput = AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            scannerDelegate?.didSurface(error: .invalidDeviceInput)
            return
        }
        
        if session.canAddInput(videoInput){
            session.addInput(videoInput)
        } else {
            scannerDelegate?.didSurface(error: .invalidDeviceInput)
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if session.canAddOutput(metadataOutput){
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer!)
        
        session.startRunning()
    }
    
}

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate{
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first else{
            scannerDelegate?.didSurface(error: .invalidCodeFormat)
            return
        }
        guard let readableObject = object as? AVMetadataMachineReadableCodeObject else{
            scannerDelegate?.didSurface(error: .invalidCodeFormat)
            return
        }
        guard let qrCode = readableObject.stringValue else {
            scannerDelegate?.didSurface(error: .invalidCodeFormat)
            return
        }
        session.stopRunning()

        if let result = LoginQRCode.parse(from: qrCode) {
            scannerDelegate?.didFind(qrCode: result)
        } else {
            scannerDelegate?.didSurface(error: .invalidQRCode)
        }
    }
}
