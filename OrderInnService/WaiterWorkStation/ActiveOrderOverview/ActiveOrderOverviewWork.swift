//
//  ActiveOrderOverviewWork.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 27/04/2021.
//

import Foundation
import FirebaseFirestore

class ActiveOrderOverviewWork: ObservableObject{
    @Published var collectedOrder = ClientSubmittedOrder()
    @Published var submitedOrder = OrderOverview()
    @Published var extraOrder = ExtraOrderOverview()
    @Published var menuItems = [MenuItem]()
    @Published var extraOrderTotalPrice = 0.00
    @Published var totalCollectedOrderPrice = 0.00
    @Published var sendingQuery = false
    
    let databse = Firestore.firestore()
    
    @Published var submittedExtraOrder = [ExtraOrderOverview]()
    
    func updatePrice(fromItems: MenuItem){
        self.extraOrderTotalPrice = menuItems.reduce(0) { $0 + $1.price }
    }
    
    func getItemCount(forItem: MenuItem) -> Int{
        return menuItems.filter { $0 == forItem }.count
    }
    
    func addExtraItem(_ menuItem: MenuItem){
        menuItems.append(menuItem)
        updatePrice(fromItems: menuItem)
    }
    
    func removeExtraItem(_ menuItem: MenuItem){
        if let index = menuItems.firstIndex(where: { $0.id == menuItem.id }){
            menuItems.remove(at: index)
            updatePrice(fromItems: menuItem)
        }
    }
    
    func collectAllOrderParts(withExtras: [ExtraOrderOverview]){
        let extraPrice = withExtras.map{ $0.extraPrice }
        let extraOrderPrice = extraPrice.reduce(0, +)
        let totalOrderPrice = extraOrderPrice + submitedOrder.totalPrice
        self.totalCollectedOrderPrice = totalOrderPrice
        
        self.collectedOrder = ClientSubmittedOrder(id: submitedOrder.id, placedBy: submitedOrder.placedBy, orderCompleted: submitedOrder.orderCompleted, orderClosed: submitedOrder.orderClosed, totalPrice: totalOrderPrice, forTable: submitedOrder.forTable, withItems: submitedOrder.withItems, withExtraItems: withExtras)
    }
    
    func retreveSubmitedItems(from items: ActiveOrder){
        let submitedItems = items.orderItems.map{ item -> OrderOverview.OrderOverviewEntry in
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
            .document(UserDefaults.standard.qrStringKey)
            .collection("ExtraOrder").whereField("forOrder", isEqualTo: order.id)
            .getDocuments { snapshot, error in
                
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
                
                self.submittedExtraOrder = activeExtraOrders.map{ order -> ExtraOrderOverview in
                    var extraOrderEntry = [ExtraOrderOverview.ExtraOrderEntry]()
                    
                    extraOrderEntry = order.extraItems.map{ item -> ExtraOrderOverview.ExtraOrderEntry in
                        let seperator = "/"
                        let partParts = item.components(separatedBy: seperator)
                        let itemName = partParts[0]
                        let itemPrice = Double(partParts[1])!
                        
                        let collectedItem = ExtraOrderOverview.ExtraOrderEntry(itemName: itemName, itemPrice: itemPrice)
                        return collectedItem
                    }
                    
                    let collectedOrder = ExtraOrderOverview(id: order.id, extraOrderPart: order.extraOrderPart, extraPrice: order.extraOrderPrice, forOrder: order.orderId, withItems: extraOrderEntry)
                    
                    self.extraOrder = collectedOrder
                    return collectedOrder
            }
                self.collectAllOrderParts(withExtras: self.submittedExtraOrder)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            self.sendingQuery = false
        })
    }
    
    func submitExtraOrder(from items: ActiveOrder){
        self.sendingQuery = true
        
        var additionalOrderIndex = 0
        
        for index in submittedExtraOrder{
            if index.extraOrderPart == nil{
                additionalOrderIndex += 1
            }else{
                additionalOrderIndex = index.extraOrderPart! + 1
            }
        }
        
        var itemName = self.menuItems.map{ item -> String in
            return "\(item.name)" + "/\(item.price)"
        }
        
        let documentData: [String: Any] = [
            "extraPart": additionalOrderIndex,
            "forOrder": submitedOrder.id,
            "additionalOrder" : itemName,
            "extraPrice" : extraOrderTotalPrice
        ]
        itemName.removeAll()
        
        databse.collection("Restaurants")
            .document(UserDefaults.standard.qrStringKey)
            .collection("ExtraOrder")
            .addDocument(data: documentData){ error in
                if let error = error{
                    //TODO: add alert
                    print("Order did not update \(error)")
                }else{
                    print("Urder updated!")
                    self.menuItems.removeAll()
                    self.getExtraOrders(from: items)
                }
            }
    }
}
