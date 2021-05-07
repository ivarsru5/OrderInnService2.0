//
//  OrderOverViewWork.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 07/05/2021.
//

import Foundation
import FirebaseFirestore

class KitchenOrderWork: ObservableObject{
    @Published var collectedOrder = ClientSubmittedOrder()
    @Published var submitedOrder = OrderOverview()
    
    let databse = Firestore.firestore()
    
    @Published var submittedExtraOrder = [ExtraOrderOverview]()
    
    func collectAllOrderParts(withExtras: [ExtraOrderOverview]){
        let extraPrice = withExtras.map{ $0.extraPrice }
        let extraOrderPrice = extraPrice.reduce(0, +)
        let totalOrderPrice = extraOrderPrice + submitedOrder.totalPrice
        
        self.collectedOrder = ClientSubmittedOrder(id: submitedOrder.id, placedBy: submitedOrder.placedBy, orderCompleted: submitedOrder.orderCompleted, orderClosed: submitedOrder.orderClosed, totalPrice: totalOrderPrice, forTable: submitedOrder.forTable, withItems: submitedOrder.withItems, withExtraItems: withExtras)
    }
    
    func retreveSubmitedItems(from items: ActiveOrder){
        let submittedDrinks = items.barItems.map{ item -> OrderOverview.OrderOverviewEntry in
            let seperator = "/"
            let partParts = item.components(separatedBy: seperator)
            let itemName = partParts[0]
            let itemPrice = Double(partParts[1])!
            
            let collectedDrinks = OrderOverview.OrderOverviewEntry(itemName: itemName, itemPrice: itemPrice)
            return collectedDrinks
        }
        
        var submitedItems = items.kitchenItems.map{ item -> OrderOverview.OrderOverviewEntry in
            let seperator = "/"
            let partParts = item.components(separatedBy: seperator)
            let itemName = partParts[0]
            let itemPrice = Double(partParts[1])
            
            let collectedItems = OrderOverview.OrderOverviewEntry(itemName: itemName, itemPrice: itemPrice!)
            return collectedItems
        }
        
        submitedItems.append(contentsOf: submittedDrinks)
        
        self.submitedOrder = OrderOverview(id: items.id, placedBy: items.placedBy, orderCompleted: items.orderCompleted, orderClosed: items.orderClosed, totalPrice: items.totalPrice, forTable: items.forTable, withItems: submitedItems)
        
        getExtraOrders(from: items)
    }
    
    func getExtraOrders(from order: ActiveOrder){
        databse.collection("Restaurants")
            .document(UserDefaults.standard.wiaterQrStringKey)
            .collection("ExtraOrder").whereField("forOrder", isEqualTo: order.id)
            .addSnapshotListener { snapshot, error in
                
                guard let snapshotDocument = snapshot?.documents else{
                    print("There is no documents")
                    return
                }
                
                let activeExtraOrders = snapshotDocument.compactMap{ activeExtras -> ActiveExtraOrder? in
                    guard let collectedExtras = ActiveExtraOrder(snapshot: activeExtras) else{
                        return nil
                    }
                    return collectedExtras
                }
                
                let extraOrder = activeExtraOrders.map{ order -> ExtraOrderOverview in
                    var extraOrderEntry = [ExtraOrderOverview.ExtraOrderEntry]()
                    
                    let kitchenItems = order.extraItems.map{ item -> ExtraOrderOverview.ExtraOrderEntry in
                        let seperator = "/"
                        let partParts = item.components(separatedBy: seperator)
                        let itemName = partParts[0]
                        let itemPrice = Double(partParts[1])!
                        
                        let collectedItem = ExtraOrderOverview.ExtraOrderEntry(itemName: itemName, itemPrice: itemPrice)
                        return collectedItem
                    }
                    
                    extraOrderEntry.append(contentsOf: kitchenItems)
                    
                    let barItems = order.extraBarItems.map{ item -> ExtraOrderOverview.ExtraOrderEntry in
                        let seperator = "/"
                        let partParts = item.components(separatedBy: seperator)
                        let itemName = partParts[0]
                        let itemPrice = Double(partParts[1])!
                        
                        let collectedItem = ExtraOrderOverview.ExtraOrderEntry(itemName: itemName, itemPrice: itemPrice)
                        return collectedItem
                    }
                    
                    extraOrderEntry.append(contentsOf: barItems)
                    
                    let collectedOrder = ExtraOrderOverview(id: order.id, extraOrderPart: order.extraOrderPart, extraPrice: order.extraOrderPrice, forOrder: order.orderId, withItems: extraOrderEntry)
                    return collectedOrder
            }
                self.submittedExtraOrder = extraOrder.sorted { $0.extraOrderPart! > $1.extraOrderPart! }
                self.collectAllOrderParts(withExtras: self.submittedExtraOrder)
        }
    }
}
