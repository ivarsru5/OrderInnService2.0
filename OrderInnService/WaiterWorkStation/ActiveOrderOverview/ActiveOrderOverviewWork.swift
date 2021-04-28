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
    @Published var extraComponent = OrderOverView.ExtraOrder()
    @Published var extraOrderComponents = [OrderOverView.ExtraOrder]()
    @Published var extraOrderTotalPrice = 0.00
    let databse = Firestore.firestore()
    
    var menuItems = [MenuItem]()
    
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
        let itemName = extraComponent.menuItems.map{ item -> String in
            return "\(item.name)" + "/\(item.price)"
        }
        
        let documentData: [String: Any] = [
            "placedBy" : submitedOrder.placedBy,
            "additionalOrder_\(extraComponent.index)" : itemName,
            "toatlOrderPrice" : submitedOrder.totalPrice + extraOrderTotalPrice,
            
        ]
        
        databse.collection("Restaurants")
            .document(UserDefaults.standard.qrStringKey)
            .collection("Order")
            .document(submitedOrder.id)
            .setData(documentData) { error in
                if let error = error{
                    //TODO: add alert
                    print("Order did not update \(error)")
                }else{
                    print("Urder updated!")
                }
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
