//
//  OrderCatView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 23/04/2021.
//

import SwiftUI

struct OrderCatView: View {
    @EnvironmentObject var restaurantOrder: RestaurantOrderWork
    
    var body: some View {
        VStack{
            List{
                ForEach(restaurantOrder.restaurantOrder!.menuItems, id: \.id){ item in
                    Text(item.name)
                        .bold()
                        .foregroundColor(.white)
                    
                    Text("\(item.price)")
                        .bold()
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct OrderCatView_Previews: PreviewProvider {
    static var previews: some View {
        OrderCatView()
    }
}
