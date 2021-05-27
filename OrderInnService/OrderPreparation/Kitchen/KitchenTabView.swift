//
//  KitchenTabView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 27/05/2021.
//

import SwiftUI

struct KitchenTabView: View {
    @ObservedObject var qrScanner: QrCodeScannerWork
    
    var body: some View {
        TabView{
            NavigationView{
                KitchenView(qrScanner: qrScanner)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem{
                Image(systemName: "tray")
                Text("Orders")
            }
            
            NavigationView{
                ItemAvailability()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem{
                Image(systemName: "tray")
                Text("Availability")
            }
        }
    }
}
