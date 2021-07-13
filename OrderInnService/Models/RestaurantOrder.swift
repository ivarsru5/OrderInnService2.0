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
    var placedBy: Restaurant.Employee
    var orderReady: Bool
    var forTable: String
    var forZone: String
    var orderSeen: Bool
    
    init(){
        self.menuItems = []
        self.orderReady = false
        self.forTable = ""
        self.forZone = ""
        self.orderSeen = false
        self.placedBy = AuthManager.shared.waiter!
    }
    
    struct Course{
        let index: Int
        let menuItems: [MenuItem]
    }
}
