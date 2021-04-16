//
//  ContentView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 15/04/2021.
//

import SwiftUI

struct QrScannerView: View {
    @StateObject var scannerWork = QrCodeScannerWork()
    
    var body: some View {
        NavigationView{
            ZStack{
                QrCodeScannerView(qrCode: $scannerWork.qrCode, alertItem: $scannerWork.alertItem)
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
                
//                HalfModalView(isShown: $scannerWork.displayHalfModalLogin, modalHeight: 400){
//                    Text("\(scannerWork.restaurant?.name ?? "There is no restaurant")")
//                        .foregroundColor(.blue)
//                }.onReceive(scannerWork.objectWillChange, perform: {
//                    scannerWork.retriveEmployes(withId: scannerWork.qrCode)
//                })
            }
            .navigationBarHidden(true)
            .alert(item: $scannerWork.alertItem){ alert in
                Alert(title: alert.title,
                      message: alert.message,
                      dismissButton: alert.dismissButton)
            }
        }
    }
}
