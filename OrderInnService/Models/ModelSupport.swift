//
//  ModelSupport.swift
//  OrderInnService
//
//  Created by paulsnar on 7/13/21.
//

import Foundation

enum ModelError: Error {
    case invalidEnumStringEncoding
}

// HACK[pn 2021-07-13]: Even though we don't use Double in a non-currency
// context, this type should be used instead to delineate where it would need
// to be replaced if we were to ever do currency correctly.
// See: http://wiki.c2.com/?FloatingPointCurrency
typealias Currency = Double

extension Currency {
    static func * (_ lhs: Currency, _ rhs: Int) -> Currency { lhs * Double(rhs) }
}
