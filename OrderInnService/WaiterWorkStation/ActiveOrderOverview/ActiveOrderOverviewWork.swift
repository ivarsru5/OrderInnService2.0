//
//  ActiveOrderOverviewWork.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 27/04/2021.
//

import Foundation
import FirebaseFirestore

class ActiveOrderOverviewWork: ObservableObject{
    @Published var submitedOrder = OrderOverview()
    @Published var submitedItems = [OrderOverview.OrderOverviewEntry]()
    @Published var extraOrders = [OrderOverview.SubmitedExtraOrder]()
    @Published var menuItems = [MenuItem]()
    @Published var extraOrderTotalPrice = 0.00
    
    let databse = Firestore.firestore()
    var extraOrderComponents = [OrderOverview.ExtraOrder]()
    
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
    
    func addExtraItems() -> OrderOverview.ExtraOrder{
        let menuItems = self.menuItems.map { item -> MenuItem in
            let index = self.menuItems.firstIndex(where: { $0.id == item.id })!
            let menuItem = self.menuItems[index]
            self.menuItems.remove(at: index)
            return menuItem
        }
        
        let extraOrder = OrderOverview.ExtraOrder(menuItems: menuItems)
        self.extraOrderComponents.append(extraOrder)
        return extraOrder
    }
    
    func saveSubmittedExtraOrder() -> OrderOverview.SubmitedExtraOrder?{
        let menuItems = self.extraOrderComponents.compactMap{ item -> MenuItem? in
            var addedItem: MenuItem?
            
            for items in item.menuItems{
                addedItem = items
            }
            guard let collectedItem = addedItem else{
                return nil
            }
            return collectedItem
        }
        
        let savedOrder = OrderOverview.SubmitedExtraOrder(index: self.extraOrders.count + 1, submitedItems: menuItems)
        self.extraOrders.append(savedOrder)
        return savedOrder
    }
    
    func submitExtraOrder(){
        _ = addExtraItems()
        _ = self.saveSubmittedExtraOrder()
        
        var itemName: [String] = []
        var additionalOrderIndex = 0
        
        for index in extraOrders{
            additionalOrderIndex = index.index
        }
        
        for order in extraOrderComponents{
            for item in order.menuItems{
                let orderItem = item.name + "/\(item.price)"
                itemName.append(orderItem)
            }
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
                    self.extraOrderComponents.removeAll()
                }
            }
    }
    
    func retreveSubmitedItems(from items: ActiveOrder){
        self.submitedItems = items.orderItems.map{ item -> OrderOverview.OrderOverviewEntry in
            let seperator = "/"
            let partParts = item.components(separatedBy: seperator)
            let itemName = partParts[0]
            let itemPrice = Double(partParts[1])
            
            let collectedItems = OrderOverview.OrderOverviewEntry(itemName: itemName, itemPrice: itemPrice!)
            return collectedItems
        }
        
        self.submitedOrder = OrderOverview(id: items.id, placedBy: items.placedBy, orderCompleted: items.orderCompleted, orderClosed: items.orderClosed, totalPrice: items.totalPrice, forTable: items.forTable, withItems: submitedItems, extraOrder: self.submittedExtraOrder)
        
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
                    
                    return collectedOrder
            }
        }
    }
}
