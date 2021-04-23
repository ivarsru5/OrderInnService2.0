//
//  OrderInnServiceApp.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 15/04/2021.
//

import SwiftUI
import Firebase

@main
struct OrderInnServiceApp: App {
    @StateObject var restaurantOrder: RestaurantOrderWork
    init(){
        FirebaseApp.configure()
        let order = RestaurantOrderWork()
        _restaurantOrder = StateObject(wrappedValue: order)
    }
    
    var body: some Scene {
        WindowGroup {
            LounchScreen()
                .environmentObject(restaurantOrder)
        }
    }
}
