//
//  QrScannerViewController.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 15/04/2021.
//

import UIKit
import AVFoundation

enum CameraError: String{
    case invalidDeviceInput
    case invalidCodeFormat
    case invalidQrCode
}

protocol ScannerVCDelegate: AnyObject {
    func didFind(qrCode: String)
    func didSurface(error: CameraError)
}

class QrScannerViewController: UIViewController{
    let session = AVCaptureSession()
    var preViewLayer: AVCaptureVideoPreviewLayer?
    weak var scannerDelegate: ScannerVCDelegate?
    
    init(scannerDelegate: ScannerVCDelegate){
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
        
        guard let previewLayer = preViewLayer else{
            scannerDelegate?.didSurface(error: .invalidDeviceInput)
            return
        }
        previewLayer.frame = view.layer.bounds
    }
    
    private func setupCameraSession(){
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else{
            scannerDelegate?.didSurface(error: .invalidDeviceInput)
            return
        }
        let videoInput: AVCaptureDeviceInput
        
        do{
            try videoInput = AVCaptureDeviceInput(device: videoCaptureDevice)
        }catch{
            scannerDelegate?.didSurface(error: .invalidDeviceInput)
            return
        }
        
        if session.canAddInput(videoInput){
            session.addInput(videoInput)
        }else{
            scannerDelegate?.didSurface(error: .invalidDeviceInput)
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if session.canAddOutput(metadataOutput){
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }else{
            return
        }
        
        preViewLayer = AVCaptureVideoPreviewLayer(session: session)
        preViewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preViewLayer!)
        
        session.startRunning()
    }
    
}

extension QrScannerViewController: AVCaptureMetadataOutputObjectsDelegate{
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
        
//        if let result = QRURL.validateWaiter(from: qrCode){
//            scannerDelegate?.didFind(qrCode: result.restaurant)
//        }else if let result = QRURL.validateKitchen(from: qrCode){
//            scannerDelegate?.didFind(qrCode: result.restaurant + result.kitchen!)
//            print(result)
//        }else{
//            scannerDelegate?.didSurface(error: .invalidQrCode)
//        }
        
        guard let result = QRURL.validateWaiter(from: qrCode)else{
            scannerDelegate?.didSurface(error: .invalidQrCode)
            return
        }
        
        scannerDelegate?.didFind(qrCode: result.restaurant)
    }
}