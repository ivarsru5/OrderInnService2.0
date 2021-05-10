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
    
    func retreveSubmitedItems(from items: ActiveOrder){
        
        let submitedItems = items.kitchenItems.map{ item -> OrderOverview.OrderOverviewEntry in
            let seperator = "/"
            let partParts = item.components(separatedBy: seperator)
            let itemName = partParts[0]
            let itemPrice = Double(partParts[1])
            
            let collectedItems = OrderOverview.OrderOverviewEntry(itemName: itemName, itemPrice: itemPrice!)
            return collectedItems
        }
        
        self.submitedOrder = OrderOverview(id: items.id, placedBy: items.placedBy, orderCompleted: items.orderCompleted, orderClosed: items.orderClosed, totalPrice: items.totalPrice, forTable: items.forTable, withItems: submitedItems)
        
        getExtraOrders(from: items)
    }
    
    func getExtraOrders(from order: ActiveOrder){
        databse.collection("Restaurants")
            .document(UserDefaults.standard.kitchenQrStringKey)
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
                    
                    let kitchenItems = order.extraItems.map{ item -> ExtraOrderOverview.ExtraOrderEntry in
                        let seperator = "/"
                        let partParts = item.components(separatedBy: seperator)
                        let itemName = partParts[0]
                        let itemPrice = Double(partParts[1])!
                        
                        let collectedItem = ExtraOrderOverview.ExtraOrderEntry(itemName: itemName, itemPrice: itemPrice)
                        return collectedItem
                    }
                    
                    let collectedOrder = ExtraOrderOverview(id: order.id, extraOrderPart: order.extraOrderPart, extraPrice: order.extraOrderPrice, forOrder: order.orderId, withItems: kitchenItems)
                    return collectedOrder
                }
                self.submittedExtraOrder = extraOrder.sorted { $0.extraOrderPart! > $1.extraOrderPart! }
                
                self.collectedOrder = ClientSubmittedOrder(id: self.submitedOrder.id,
                                                           placedBy: self.submitedOrder.placedBy,
                                                           orderCompleted: self.submitedOrder.orderCompleted,
                                                           orderClosed: self.submitedOrder.orderClosed,
                                                           totalPrice: 0.00,
                                                           forTable: self.submitedOrder.forTable,
                                                           withItems: self.submitedOrder.withItems,
                                                           withExtraItems: self.submittedExtraOrder)
            }
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
