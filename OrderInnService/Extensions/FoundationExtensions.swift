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

    /// Insert `element` in a sorted array.
    ///
    /// If the array is not sorted before attempting to call this method, the behaviour is undefined.
    mutating func insertSorted(_ element: Element) where Element: Comparable {
        let index = firstIndex(where: { $0 >= element }) ?? endIndex
        self.insert(element, at: index)
    }
    /// Insert `element` in an array that's sorted by `comparator`.
    ///
    /// If the array is not sorted before attempting to call this method, the behaviour is undefined.
    mutating func insert(_ element: Element, sortedBy comparator: (Element, Element) -> Bool) {
        let index = firstIndex(where: { !comparator(element, $0) }) ?? endIndex
        self.insert(element, at: index)
    }

    /// Insert `element` in an array that's sorted by `keyPath`.
    ///
    /// If the array is not sorted before attempting to call this method, the behaviour is undefined.
    mutating func insert<Value: Comparable>(_ element: Element, sortedBy keyPath: KeyPath<Element, Value>) {
        let index = firstIndex(where: { $0[keyPath: keyPath] >= element[keyPath: keyPath] }) ?? endIndex
        self.insert(element, at: index)
    }
}
