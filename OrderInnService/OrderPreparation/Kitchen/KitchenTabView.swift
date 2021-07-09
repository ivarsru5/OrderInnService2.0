//
//  KitchenTabView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 27/05/2021.
//

import SwiftUI

struct KitchenTabView: View {
    var body: some View {
        TabView{
            NavigationView{
                KitchenView()
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
