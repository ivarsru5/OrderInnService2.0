//
//  FoundationExtensions.swift
//  OrderInnService
//
//  Created by paulsnar on 7/13/21.
//

import Foundation

extension Array {
    func sum() -> Element where Element : Numeric {
        precondition(count > 0)
        return self[1...].reduce(first!, { $0 + $1 })
    }
}
