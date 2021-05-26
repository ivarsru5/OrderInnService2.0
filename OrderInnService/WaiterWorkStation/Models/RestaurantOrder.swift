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
    var orderOpened: Bool
    var orderClosed: Bool
    var forTable: String
    var forZone: String
    
    init(){
        self.menuItems = []
        self.placedBy = UserDefaults.standard.currentUser
        self.orderOpened = false
        self.orderClosed = false
        self.forTable = ""
        self.forZone = ""
    }
    
    struct Course{
        let index: Int
        let menuItems: [MenuItem]
    }
}
