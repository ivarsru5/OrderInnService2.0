//
//  ItemAvailabilityController.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 07/06/2021.
//

import Combine
import FirebaseFirestore
import Foundation
import SwiftUI

class ItemAvailabilityController: ObservableObject {
    @Published var menuCategories = [MenuCategory]()
    @Published var categoryItems: [MenuCategory.ID: [MenuItem]] = [:]
    let restaurant: Restaurant

    init() {
        restaurant = AuthManager.shared.restaurant
    }
    
    func getMenuCategory() {
        var categoryItems: [MenuCategory.ID: [MenuItem]] = [:]

        let categoryPub = restaurant.firestoreReference
            .collection(of: MenuCategory.self)
            .get()
            .catch { error in
                // TODO[pn 2021-07-16]: Handle error
                return Empty<MenuCategory, Never>()
            }
            .eraseToAnyPublisher()

        categoryPub.collect().assign(to: &$menuCategories)

        var itemSub: AnyCancellable?
        itemSub = categoryPub
            .flatMap { category -> AnyPublisher<(MenuCategory, [MenuItem]), Error> in
                let items = category.firestoreReference
                    .collection(of: MenuItem.self)
                    .get()
                    .collect()
                return Just(category)
                    .setFailureType(to: Error.self)
                    .zip(items)
                    .eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { result in
                if case .failure(let error) = result {
                    // TODO[pn 2021-07-16]: Handle error
                }
                if let _ = itemSub {
                    itemSub = nil
                }
            }, receiveValue: { tuple in
                let (category, items) = tuple
                categoryItems[category.id] = items
            })
    }
    
    func setAvailable(_ availability: Bool, for item: MenuItem) -> AnyPublisher<MenuItem, Error> {
        return item.firestoreReference
            .updateData(["available": !item.isAvailable])
            .flatMap { reference in
                reference.get()
            }
            .map { [unowned self] item in
                if let _ = categoryItems[item.categoryID],
                   let idx = categoryItems[item.categoryID]!.firstIndex(where: { $0.id == item.id }) {
                    categoryItems[item.categoryID]![idx] = item
                }
                return item
            }
            .eraseToAnyPublisher()
    }
}
