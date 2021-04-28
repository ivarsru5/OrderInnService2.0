//
//  ActiveOrdersEdit.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 27/04/2021.
//

import Foundation

struct OrderOverView: Identifiable{
    let id = UUID().uuidString
    var placedBy: String = ""
    var orderClosed: Bool = false
    var totalPrice: Double = 0.00
    var forTable: String = ""
    var withItems: [OrderOverviewEntry] = []
    
    struct OrderOverviewEntry: Identifiable{
        var id = UUID().uuidString
        var itemName: String = ""
        var itemPrice: Double = 0.00
    }
}

