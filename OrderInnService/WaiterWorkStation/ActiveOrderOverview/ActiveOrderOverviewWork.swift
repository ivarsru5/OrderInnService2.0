//
//  ActiveOrderOverviewWork.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 27/04/2021.
//

import Foundation
import FirebaseFirestore

class ActiveOrderOverviewWork: ObservableObject{
    @Published var submitedOrder = OrderOverView()
    @Published var submitedItems = [OrderOverView.OrderOverviewEntry]()
    //@Published var extraComponent = OrderOverView.ExtraOrder()
    @Published var submittedExtraOrder = [OrderOverView.SubmitedExtraOrder]()
    @Published var extraOrderTotalPrice = 0.00
    var postableItems: [String] = []
    let databse = Firestore.firestore()
    
    var menuItems = [MenuItem]()
    var extraOrderComponents = [OrderOverView.ExtraOrder]()
    
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
    
    func addExtraItems() -> OrderOverView.ExtraOrder{
        let menuItems = self.menuItems.map { item -> MenuItem in
            let index = self.menuItems.firstIndex(where: { $0.id == item.id })!
            let menuItem = self.menuItems[index]
            self.menuItems.remove(at: index)
            return menuItem
        }
        
        let extraOrder = OrderOverView.ExtraOrder(index: self.extraOrderComponents.count + 1,
                                                  menuItems: menuItems)
        self.extraOrderComponents.append(extraOrder)
        return extraOrder
    }
    
    func submitExtraOrder(){
        _ = addExtraItems()
        
        var itemName: [String] = []
        var additionalOrderIndex = 0
        
        for order in extraOrderComponents{
            for item in order.menuItems{
                let orderItem = item.name + "/\(item.price)"
                additionalOrderIndex = order.index
                itemName.append(orderItem)
            }
        }
        
        let documentData: [String: Any] = [
            "forOrder": submitedOrder.id,
            "additionalOrder_\(additionalOrderIndex)" : itemName,
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
                    self.saveSubmittedExtraOrder()
                    self.extraOrderComponents.removeAll()
                }
            }
    }
    
    func saveSubmittedExtraOrder(){
        self.submittedExtraOrder = self.extraOrderComponents.map { order -> OrderOverView.SubmitedExtraOrder in
            let order = OrderOverView.SubmitedExtraOrder(index: order.index, submitedItems: order.menuItems)
            return order
        }
    }
    
    func retreveSubmitedIttems(from items: ActiveOrder){
        self.submitedItems = items.orderItems.map{ item -> OrderOverView.OrderOverviewEntry in
            let seperator = "/"
            let partParts = item.components(separatedBy: seperator)
            let itemName = partParts[0]
            let itemPrice = Double(partParts[1])
            
            let collectedItems = OrderOverView.OrderOverviewEntry(itemName: itemName, itemPrice: itemPrice!)
            return collectedItems
        }
        
        self.submitedOrder = OrderOverView(id: items.id, placedBy: items.placedBy, orderCompleted: items.orderCompleted, orderClosed: items.orderClosed, totalPrice: items.totalPrice, forTable: items.forTable, withItems: submitedItems)
    }
}
