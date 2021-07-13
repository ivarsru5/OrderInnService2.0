//
//  ActiveOrder.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 26/04/2021.
//

import Foundation
import FirebaseFirestore

struct ActiveOrder: Identifiable {
    var id = UUID().uuidString
    var kitchenItems: [String]
    var barItems: [String]
    var placedBy: String
    var orderReady: Bool
    var totalPrice: Double
    var forTable: String
    var forZone: String
    var orderSeen: Bool
    var created: Timestamp
    
    init?(snapshot: QueryDocumentSnapshot){
        let data = snapshot.data()
        self.id = snapshot.documentID
        
        guard let kitchenItems = data["kitchenItems"] as? [String] else{
            return nil
        }
        self.kitchenItems = kitchenItems
        
        guard let barItems = data["barItems"] as? [String] else{
            return nil
        }
        self.barItems = barItems
        
        guard let placedBy = data["placedBy"] as? String else{
            return nil
        }
        self.placedBy = placedBy
        
        guard let totalPrice = data["toatlOrderPrice"] as? Double else{
            return nil
        }
        self.totalPrice = totalPrice
        
        guard let forTable = data["forTable"] as? String else{
            return nil
        }
        self.forTable = forTable
        
        guard let orderReady = data["orderReady"] as? Bool else{
            return nil
        }
        self.orderReady = orderReady
        
        guard let forZone = data["inZone"] as? String else{
            return nil
        }
        self.forZone = forZone
        
        guard let orderSeen = data["orderSeen"] as? Bool else{
            return nil
        }
        self.orderSeen = orderSeen
        
        guard let created = data["created"] as? Timestamp else{
            return nil
        }
        self.created = created
    }
}

struct ActiveExtraOrder: Identifiable{
    var id = UUID().uuidString
    var extraItems: [String]
    var extraBarItems: [String]
    var orderId: String
    var extraOrderPart: Int
    var extraOrderPrice: Double
    
    init?(snapshot: QueryDocumentSnapshot){
        let data = snapshot.data()
        self.id = snapshot.documentID
        
        guard let extraitems = data["extraKitchenItems"] as? [String] else{
            return nil
        }
        self.extraItems = extraitems
        
        guard let extraBarItems = data["extraDrinks"] as? [String] else{
            return nil
        }
        self.extraBarItems = extraBarItems
        
        guard let orderId = data["forOrder"] as? String else{
            return nil
        }
        self.orderId = orderId
        
        guard let extraOrderPart = data["extraPart"] as? Int else{
            return nil
        }
        self.extraOrderPart = extraOrderPart
        
        guard let extraOrderPrice = data["extraPrice"] as? Double else{
            return nil
        }
        self.extraOrderPrice = extraOrderPrice
    }
}
