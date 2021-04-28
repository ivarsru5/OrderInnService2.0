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
