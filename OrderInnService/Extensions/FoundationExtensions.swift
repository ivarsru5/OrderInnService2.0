//
//  FoundationExtensions.swift
//  OrderInnService
//
//  Created by paulsnar on 7/13/21.
//

import Foundation

extension Array {
    func sum() -> Element where Element : Numeric {
        if count == 0 {
            return 0
        }
        return self[1...].reduce(first!, { $0 + $1 })
    }

    mutating func sort<Value: Comparable>(by keyPath: KeyPath<Element, Value>) {
        self.sort(by: { $0[keyPath: keyPath] < $1[keyPath: keyPath] })
    }

    func sorted<Value: Comparable>(by keyPath: KeyPath<Element, Value>) -> [Element] {
        return self.sorted(by: { $0[keyPath: keyPath] < $1[keyPath: keyPath] })
    }
}
