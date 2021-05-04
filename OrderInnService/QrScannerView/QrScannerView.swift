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
        ZStack{
            QrCodeScannerView(restaurant: $scannerWork.restaurantQrCode, kitchen: $scannerWork.kitchen, alertItem: $alertItem)
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
        .alert(item: $alertItem){ alert in
            Alert(title: alert.title,
                  message: alert.message,
                  dismissButton: alert.dismissButton)
            
        }
        .fullScreenCover(isPresented: $scannerWork.displayUsers){
            if scannerWork.kitchen == nil{
                EmployeeList(scannerWork: scannerWork)
            }else{
                KitchenView()
            }
        }
    }
}

enum FullScreenCover: Hashable, Identifiable{
    case toZones
    case toQrScanner
    
    var id: Int{
        return self.hashValue
    }
}

struct EmployeeList: View{
    @ObservedObject var scannerWork: QrCodeScannerWork
    @State var presentFullScreenCover: FullScreenCover? = nil
    
    var body: some View{
        VStack{
            if !scannerWork.loadingQuery{
                if !scannerWork.users.isEmpty{
                    Text("\(scannerWork.restaurant.name)")
                        .bold()
                        .foregroundColor(Color(UIColor.label))
                        .padding(.top, 10)
                        .font(.largeTitle)
                    
                    List{
                        ForEach(scannerWork.users, id:\.id){ user in
                            Button(action: {
                                scannerWork.updateData(with: user)
                                scannerWork.currentUser = user
                                self.presentFullScreenCover = .toZones
                                UserDefaults.standard.startScreen = true
                            }, label: {
                                HStack{
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(Color(UIColor.label))
                                        .font(.custom("SF Symbols", size: 20))
                                        .padding(.all, 5)
                                    
                                    Text("\(user.name) \(user.lastName)")
                                        .foregroundColor(Color(UIColor.label))
                                        .padding(.all, 10)
                                }
                            })
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }else{
                    VStack{
                        Text("There are no pending users! Please contact your supervisor.")
                            .bold()
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            self.presentFullScreenCover = .toQrScanner
                        }, label: {
                            Text("Retry Scan")
                                .frame(width: 250, height: 50, alignment: .center)
                                .foregroundColor(.blue)
                                .background(Color.white)
                                .cornerRadius(10)
                        })
                        .padding()
                    }
                }
            }else{
                Spinner()
            }
        }
        .onAppear{
            scannerWork.retriveRestaurant(with: scannerWork.restaurantQrCode)
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $presentFullScreenCover) { item in
            if item == .toZones{
                ToZoneView(qrscanner: scannerWork)
            }else if item == .toQrScanner{
                ToQrScannerView()
            }
        }
    }
}
