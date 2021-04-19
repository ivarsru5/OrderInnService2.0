//
//  RestaruantLogin.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 16/04/2021.
//

import SwiftUI

struct Restaurant: Identifiable{
    var id = UUID().uuidString
    var name: String = ""
    
    struct RestaurantEmploye: Identifiable{
        var id = UUID().uuidString
        let name: String
        let lastName: String
        let isActive: Bool
    }
}
