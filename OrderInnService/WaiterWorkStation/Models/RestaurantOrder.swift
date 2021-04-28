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
    var orderCompleted: Bool
    var forTable: String
    
    init(){
        self.menuItems = []
        self.placedBy = UserDefaults.standard.currentUser
        self.orderCompleted = false
        self.forTable = ""
    }
    
    struct ExtraOrder: Identifiable{
        var id = UUID().uuidString
        var menuItems: [MenuItem] = []
    }
    
    struct Course{
        let index: Int
        let menuItems: [MenuItem]
    }
}
