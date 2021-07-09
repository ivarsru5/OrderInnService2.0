//
//  ActiveOrdersEdit.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 27/04/2021.
//

import Foundation

struct OrderOverview: Identifiable{
    var id = UUID().uuidString
    var placedBy: String = ""
    var orderCompleted = false
    var orderClosed: Bool = false
    var totalPrice: Double = 0.00
    var forTable: String = ""
    var inZone: String = ""
    var withItems: [OrderOverviewEntry] = []
        
    struct OrderOverviewEntry: Identifiable{
        var id = UUID().uuidString
        var itemName: String = ""
        var itemPrice: Double?
    }
}

struct ExtraOrderOverview: Identifiable{
    var id = UUID().uuidString
    var extraOrderPart: Int?
    var extraPrice: Double = 0.00
    var forOrder: String = ""
    var withItems: [ExtraOrderEntry] = []
    
    struct ExtraOrderEntry:Identifiable{
        let id = UUID().uuidString
        var itemName: String = ""
        var itemPrice: Double = 0.00
    }
}

struct ClientSubmittedOrder: Identifiable{
    var id = UUID().uuidString
    var placedBy: String = ""
    var orderOpened = false
    var orderClosed: Bool = false
    var totalPrice: Double = 0.00
    var forTable: String = ""
    var inZone: String = ""
    var created: String = ""
    var withItems: [OrderOverview.OrderOverviewEntry] = []
    var withExtraItems: [ExtraOrderOverview] = []
}

extension ClientSubmittedOrder: Equatable{
    static func == (lhs: ClientSubmittedOrder, rhs: ClientSubmittedOrder) -> Bool {
        return lhs.id == rhs.id
    }
}
