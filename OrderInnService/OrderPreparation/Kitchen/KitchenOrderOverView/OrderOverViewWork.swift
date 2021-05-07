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
    
    func collectAllOrderParts(withExtras: [ExtraOrderOverview]){
        let extraPrice = withExtras.map{ $0.extraPrice }
        let extraOrderPrice = extraPrice.reduce(0, +)
        let totalOrderPrice = extraOrderPrice + submitedOrder.totalPrice
        
        self.collectedOrder = ClientSubmittedOrder(id: submitedOrder.id, placedBy: submitedOrder.placedBy, orderCompleted: submitedOrder.orderCompleted, orderClosed: submitedOrder.orderClosed, totalPrice: totalOrderPrice, forTable: submitedOrder.forTable, withItems: submitedOrder.withItems, withExtraItems: withExtras)
    }
    
    func retreveSubmitedItems(from items: ActiveOrder, withItems: [ExtraOrderOverview]){
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
        self.collectAllOrderParts(withExtras: withItems)
    }
    
    func deleteOrder(fromOrder: ActiveOrder, withExtras: [ExtraOrderOverview]){
        databse.collection("Restaurants")
            .document(UserDefaults.standard.kitchenQrStringKey)
            .collection("Order")
            .document(fromOrder.id)
            .delete(){ error in
                if let error = error{
                    print("Document was not deleted \(error)")
                }else{
                    print("Extra Orders deleted.")
                    for order in withExtras{
                        let orderID = order.forOrder
                        
                        if orderID == fromOrder.id{
                            self.databse.collection("Restaurants")
                                .document(UserDefaults.standard.kitchenQrStringKey)
                                .collection("ExtraOrder")
                                .document(order.id)
                                .delete() { error in
                                    if let error = error{
                                        print("Document was not deleted \(error)")
                                    }else{
                                        print("Extra Orders deleted.")
                                }
                            }
                        }
                    }
                }
            }
    }
}
