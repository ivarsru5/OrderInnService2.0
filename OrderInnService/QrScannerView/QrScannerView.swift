//
//  ContentView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 15/04/2021.
//

import SwiftUI

struct QrScannerView: View {
    @StateObject var scannerWork = QrCodeScannerWork()
    @State var alertItem: AlertItem?
    
    var body: some View {
        NavigationView{
            ZStack{
                QrCodeScannerView(qrCode: $scannerWork.qrCode, alertItem: $alertItem)
                    .edgesIgnoringSafeArea(.all)
                
                BlurEffectView(effect: UIBlurEffect(style: .dark))
                    .inverseMask(Circle().padding())
                    .edgesIgnoringSafeArea(.all)
                VStack{
                    Text("Please scan QR code.")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(.top, 60)
                    
                    Spacer()
                }
            }
            .overlay(
                HalfModalView(isShown: $scannerWork.displayHalfModalLogin, modalHeight: 600){
                    Text("\(scannerWork.restaurant?.name ?? "There is no restaurant")")
                        .foregroundColor(.blue)
                }
            )
            .navigationBarHidden(true)
            .alert(item: $alertItem){ alert in
                Alert(title: alert.title,
                      message: alert.message,
                      dismissButton: alert.dismissButton)
            }
            .onReceive(scannerWork.objectWillChange, perform: {
                scannerWork.retriveEmployes(with: scannerWork.qrCode!)
                scannerWork.displayHalfModalLogin.toggle()
            })
        }
    }
}
