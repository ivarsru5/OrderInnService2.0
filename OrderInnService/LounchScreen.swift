//
//  LounchScreen.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/04/2021.
//

import SwiftUI

struct LounchScreen: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        switch authManager.authState {
        case .loading:
            Spinner()
        case .unauthenticated, .authenticatedWaiterUnknownID(restaurantID: _):
            QrScannerView()
        case .authenticatedWaiter(restaurantID: _, employeeID: _):
            OrderTabView()
        case .authenticatedKitchen(restaurantID: _, kitchen: _):
            KitchenView()
        }
    }
}

struct LounchScreen_Previews: PreviewProvider {
    static var previews: some View {
        LounchScreen()
    }
}
