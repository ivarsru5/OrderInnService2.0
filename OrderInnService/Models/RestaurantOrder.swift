//
//  Order.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 22/04/2021.
//

import Foundation

struct RestaurantOrder: Identifiable{
    var id = UUID().uuidString
    var menuItems: [MenuItem]
    var placedBy: String
    
    init(){
        self.menuItems = []
        self.placedBy = UserDefaults.standard.currentUser
    }
    
    struct Course{
        let index: Int
        let menuItems: [MenuItem]
    }
}
