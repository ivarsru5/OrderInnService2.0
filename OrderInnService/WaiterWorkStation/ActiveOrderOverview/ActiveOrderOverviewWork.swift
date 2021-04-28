//
//  ActiveOrderOverviewWork.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 27/04/2021.
//

import Foundation

class ActiveOrderOverviewWork: ObservableObject{
    @Published var submitedOrder = OrderOverView()
    @Published var submitedItems = [OrderOverView.OrderOverviewEntry]()
    @Published var extraOrderComponents = [OrderOverView.ExtraOrder]()
    @Published var extraOrderTotalPrice = 0.00
    
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
    
    func retreveSubmitedIttems(from items: ActiveOrder){
        self.submitedItems = items.orderItems.map{ item -> OrderOverView.OrderOverviewEntry in
            let seperator = "/"
            let partParts = item.components(separatedBy: seperator)
            let itemName = partParts[0]
            let itemPrice = Double(partParts[1])
            
            let collectedItems = OrderOverView.OrderOverviewEntry(itemName: itemName, itemPrice: itemPrice!)
            return collectedItems
        }
        
        self.submitedOrder = OrderOverView(placedBy: items.placedBy, orderClosed: items.orderCompleted, totalPrice: items.totalPrice, forTable: items.forTable, withItems: self.submitedItems)
    }
}
