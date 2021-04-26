//
//  TableView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 26/04/2021.
//

import SwiftUI

struct OrderTabView: View {
    @ObservedObject var qrScanner: QrCodeScannerWork
    @StateObject var restaurantOrder = RestaurantOrderWork()
    
    var body: some View {
        TabView{
            ZoneSelection(qrScanner: qrScanner)
                .tabItem{
                    Image(systemName: "tray")
                    Text("Place Order")
                }
                .environmentObject(restaurantOrder)
                .navigationBarHidden(false)
            
            ActiveOrderView()
                .tabItem{
                    Image(systemName: "scroll")
                    Text("Active Order's")
                }
        }
    }
}
