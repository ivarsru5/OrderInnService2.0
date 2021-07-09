//
//  LoginQRCode.swift
//  OrderInnService
//
//  Created by paulsnar on 7/9/21.
//

import Foundation

enum LoginQRCode {
    case waiter(restaurantID: Restaurant.ID)
    case kitchen(restaurantID: Restaurant.ID, kitchen: String)

    static func parse(from input: String) -> LoginQRCode? {
        guard let url = URL(string: input) else {
            return nil
        }

        guard url.scheme == "orderInnService" && url.host == "qr1" else {
            return nil
        }

        let pathParts = url.path.split(separator: "/")
        if pathParts.count == 1 {
            return LoginQRCode.waiter(restaurantID: String(pathParts[0]))
        } else if pathParts.count == 2 {
            return LoginQRCode.kitchen(restaurantID: String(pathParts[0]),
                                       kitchen: String(pathParts[1]))
        } else {
            return nil
        }
    }

    var restaurantID: Restaurant.ID {
        switch self {
        case let .waiter(restaurantID): return restaurantID
        case let .kitchen(restaurantID, _): return restaurantID
        }
    }
}
