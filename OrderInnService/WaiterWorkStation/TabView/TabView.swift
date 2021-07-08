//
//  TableView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 26/04/2021.
//

import SwiftUI

struct OrderTabView: View {
    @ObservedObject var qrScanner: QrCodeScannerWork
    
    var body: some View {
        TabView{
            NavigationView{
                ZoneSelection(qrScanner: qrScanner)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem{
                Image(systemName: "tray")
                Text("Place Order")
            }
            NavigationView{
                ActiveOrderView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem{
                Image(systemName: "scroll")
                Text("Active Order's")
            }

            #if DEBUG
            NavigationView {
                DebugMenu()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Image(systemName: "wrench.and.screwdriver")
                Text("Debug")
            }
            #endif
        }
    }
}
