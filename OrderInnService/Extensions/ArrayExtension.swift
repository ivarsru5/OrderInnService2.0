//
//  ArrayExtension.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 26/06/2021.
//

import Foundation

extension Array {

    func uniques<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        return reduce([]) { result, element in
            let alreadyExists = (result.contains(where: { $0[keyPath: keyPath] == element[keyPath: keyPath] }))
            return alreadyExists ? result : result + [element]
        }
    }
}
