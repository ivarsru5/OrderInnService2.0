//
//  CombineExtensions.swift
//  OrderInnService
//
//  Created by paulsnar on 7/12/21.
//

import Foundation
import Combine

extension Publisher {
    func sink(receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void) -> AnyCancellable where Output == Never {
        return self.sink(receiveCompletion: receiveCompletion, receiveValue: { _ in })
    }
}
