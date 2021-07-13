//
//  ManagerAccess.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 13/07/2021.
//

import Foundation
import FirebaseFirestore

class ManagerAccess: ObservableObject{
    @Published var completedOrders = [ClientSubmittedOrder]()
}
