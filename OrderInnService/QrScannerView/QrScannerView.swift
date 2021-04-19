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
                NavigationLink(destination: EmployeeList(scannerWork: scannerWork), isActive: $scannerWork.displayUsers){
                    EmptyView()
                }
            }
            .navigationBarHidden(true)
            .onDisappear{
                scannerWork.retriveRestaurant(with: scannerWork.qrCode)
                scannerWork.getUsers(with: scannerWork.qrCode)
            }
            .alert(item: $alertItem){ alert in
                Alert(title: alert.title,
                      message: alert.message,
                      dismissButton: alert.dismissButton)
            }
        }
    }
}

struct EmployeeList: View{
    @ObservedObject var scannerWork: QrCodeScannerWork
    @State var showZones = false
    
    var body: some View{
        VStack{
            if !scannerWork.loadingQuery{
                if !scannerWork.users.isEmpty{
                    Text("\(scannerWork.restaurant.name)")
                        .bold()
                        .foregroundColor(.white)
                        .padding(.all, 20)
                    
                    List{
                        ForEach(scannerWork.users, id:\.id){ user in
                            Button(action: {
                                scannerWork.updateData(with: user)
                                showZones.toggle()
                            }, label: {
                                Text("\(user.name) \(user.lastName)")
                                    .foregroundColor(Color(UIColor.label))
                                    .padding(.all, 10)
                            })
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    
                    NavigationLink(destination: ZoneSelection(), isActive: $showZones) { EmptyView() }
                    
                }else{
                    Text("There are no pending users! Please contact your supervisor.")
                        .bold()
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
//                    NavigationLink(destination: QrScannerView()){
//                        Text("Retry Qr code scan")
//                            .bold()
//                            .frame(width: 100, height: 40, alignment: .center)
//                            .foregroundColor(Color(UIColor.systemBackground))
//                            .background(Color(UIColor.label))
//                            .padding()
//                    }
                }
            }else{
                Spinner()
            }
        }
        .navigationBarHidden(true)
    }
}
