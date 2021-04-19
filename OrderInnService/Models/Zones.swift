//
//  Zones.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/04/2021.
//

import Foundation
import FirebaseFirestore

struct Zones: Identifiable {
    let id = UUID().uuidString
    let location: String
}
