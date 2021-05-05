//
//  KitchenView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 04/05/2021.
//

import SwiftUI

struct KitchenView: View {
    @StateObject var kitchen = KitchenWork()
    @ObservedObject var qrScanner: QrCodeScannerWork
    
    var body: some View {
        VStack{
            List{
                ForEach(kitchen.activeOrder, id: \.id){ order in
                    ForEach(order.withItems, id: \.id){ item in
                        VStack{
                            VStack{
                                Text("In Zone: \(order.inZone)")
                                    .bold()
                                    .foregroundColor(Color(UIColor.label))
                                
                                Text("For Table: \(order.forTable)")
                                    .bold()
                                    .foregroundColor(Color(UIColor.label))
                            }
                            
                        }
                    }
                }
            }
        }
        .navigationTitle("\(kitchen.getRestaurantName(fromQrString: qrScanner.restaurantQrCode)): \(qrScanner.kitchen!)")
        .onAppear{
            kitchen.getKitchenOrder(qrScanner)
        }
    }
}

