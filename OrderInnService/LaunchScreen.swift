//
//  LounchScreen.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/04/2021.
//

import SwiftUI

struct LaunchScreen: View {
    @EnvironmentObject var authManager: AuthManager
    
    @ViewBuilder var innerBody: some View {
        switch authManager.authState {
        case .loading:
            Spinner()
        case .unauthenticated, .authenticatedWaiterUnknownID(restaurantID: _):
            LoginScreen()
        case .authenticatedWaiter(restaurantID: _, employeeID: _):
            OrderTabView.Wrapper()
        case .authenticatedKitchen(restaurantID: _, kitchen: _):
            KitchenTabView.Wrapper()
        case .authenticatedAdmin(restaurantID: _, admin: _):
            AdminGeneralSelection()
        }
    }
    var body: some View {
        innerBody
            .environment(\.currentRestaurant, authManager.restaurant)
            .environment(\.currentEmployee, authManager.waiter)
    }
}

