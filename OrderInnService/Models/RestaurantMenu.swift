//
//  RestaurantMenu.swift
//  OrderInnService
//
//  Created by paulsnar on 7/13/21.
//

import Combine
import Foundation
import FirebaseFirestore

struct MenuCategory: Identifiable, Hashable, FirestoreInitiable {
    typealias ID = String

    // TODO[pn 2021-07-13]: Pluralisation typo.
    static let firestoreCollection = "MenuCategory"

    enum CategoryType: String, Equatable, Codable {
        case food = "food"
        case drink = "drink"

        init(from string: String) throws {
            switch string {
            case CategoryType.food.rawValue: self = .food
            case CategoryType.drink.rawValue: self = .drink
            default: throw ModelError.invalidEnumStringEncoding
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            try self.init(from: value)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(self.rawValue)
        }
    }

    enum Key: String, CodingKey {
        case name = "name"
        case type = "type"
    }

    let restaurantID: Restaurant.ID
    let id: ID
    let name: String
    let type: CategoryType

    init(from snapshot: KeyedDocumentSnapshot<MenuCategory>) {
        self.id = snapshot.documentID
        self.name = snapshot[.name] as! String
        self.type = try! CategoryType(from: snapshot[.type] as! String)

        let restaurant = snapshot.reference.parentDocument(ofKind: Restaurant.self)
        restaurantID = restaurant.documentID
    }

    #if DEBUG
    init(id: ID, name: String, type: CategoryType, restaurantID: Restaurant.ID) {
        self.id = id
        self.name = name
        self.type = type
        self.restaurantID = restaurantID
    }
    #endif

    var firestoreReference: TypedDocumentReference<MenuCategory> {
        TypedCollectionReference.root(Firestore.firestore(), of: Restaurant.self)
            .document(restaurantID)
            .collection(of: MenuCategory.self)
            .document(id)
    }

    static func create(under restaurant: Restaurant,
                       name: String, type: CategoryType) -> AnyPublisher<MenuCategory, Error> {
        restaurant.firestoreReference
            .collection(of: MenuCategory.self)
            .addDocument(data: [
                .name: name,
                .type: type.rawValue,
            ])
            .get()
    }
}

struct MenuItem: Identifiable, Hashable, FirestoreInitiable {
    typealias ID = String

    // TODO[pn 2021-07-13]: Nondescript name.
    static let firestoreCollection = "Menu"

    enum Destination: String, Codable {
        case kitchen = "kitchen"
        case bar = "bar"

        init(from string: String) throws {
            switch string {
            case Destination.kitchen.rawValue: self = .kitchen
            case Destination.bar.rawValue: self = .bar
            default: throw ModelError.invalidEnumStringEncoding
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            try self.init(from: value)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(self.rawValue)
        }
    }

    struct FullID: Hashable, Equatable, Codable {
        let category: MenuCategory.ID
        let item: ID

        init(category: MenuCategory.ID, item: ID) {
            self.category = category
            self.item = item
        }
        init?(string: String) {
            guard let tuple = FullID.unparse(string: string) else { return nil }
            self.category = tuple.0
            self.item = tuple.1
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            guard let tuple = FullID.unparse(string: string) else {
                throw ModelError.invalidFormat
            }
            self.category = tuple.0
            self.item = tuple.1
        }

        private static func unparse(string: String) -> (MenuCategory.ID, ID)? {
            let parts = string.split(separator: "/")
            guard parts.count == 2 else { return nil }
            let category = MenuCategory.ID(parts[0])
            let item = ID(parts[1])
            return (category, item)
        }

        var string: String { "\(category)/\(item)" }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(self.string)
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(category)
            hasher.combine(item)
        }
    }

    enum Key: String, CodingKey {
        case name = "name"
        case price = "price"
        case destination = "destination"
        case isAvailable = "isAvailable"

        @available(*, deprecated)
        case old_isAvailable = "available"
    }

    let restaurantID: Restaurant.ID
    let categoryID: MenuCategory.ID
    let id: ID
    let name: String
    let price: Double
    let isAvailable: Bool
    let destination: Destination

    init(from snapshot: KeyedDocumentSnapshot<MenuItem>) {
        self.id = snapshot.documentID
        self.name = snapshot[.name] as! String
        self.price = snapshot[.price] as! Double
        self.destination = try! Destination(from: snapshot[.destination] as! String)
        self.isAvailable = snapshot[.isAvailable, fallback: .old_isAvailable] as! Bool

        let category = snapshot.reference.parentDocument(ofKind: MenuCategory.self)
        categoryID = category.documentID
        let restaurant = category.parentDocument(ofKind: Restaurant.self)
        restaurantID = restaurant.documentID
    }

    #if DEBUG
    init(id: ID, name: String, price: Double, isAvailable: Bool,
         destination: Destination, restaurantID: Restaurant.ID,
         categoryID: MenuCategory.ID) {
        self.id = id
        self.name = name
        self.price = price
        self.isAvailable = isAvailable
        self.destination = destination
        self.restaurantID = restaurantID
        self.categoryID = categoryID
    }
    #endif

    var fullID: FullID {
        return FullID(category: categoryID, item: id)
    }

    var firestoreReference: TypedDocumentReference<MenuItem> {
        TypedCollectionReference.root(Firestore.firestore(), of: Restaurant.self)
            .document(restaurantID)
            .collection(of: MenuCategory.self)
            .document(categoryID)
            .collection(of: MenuItem.self)
            .document(id)
    }

    static func create(in category: MenuCategory,
                       name: String, price: Double, destination: Destination,
                       isAvailable: Bool = true) -> AnyPublisher<MenuItem, Error> {
        category.firestoreReference
            .collection(of: MenuItem.self)
            .addDocument(data: [
                .name: name,
                .price: price,
                .isAvailable: isAvailable,
                .destination: destination.rawValue,
            ])
            .get()
    }

    func update(isAvailable: Bool) -> AnyPublisher<MenuItem, Error> {
        self.firestoreReference
            .updateData([.isAvailable: isAvailable])
            .flatMap { ref in ref.get() }
            .eraseToAnyPublisher()
    }
}

class MenuManager: ObservableObject {
    typealias Menu = [MenuItem.FullID: MenuItem]
    typealias Categories = [MenuCategory.ID: MenuCategory]

    let restaurant: Restaurant
    @Published var hasData = false
    @Published var menu: Menu = [:]
    @Published var categories: Categories = [:]
    @Published var categoryItems: [MenuCategory.ID: [MenuItem.FullID]] = [:]
    @Published var categoryOrder: [MenuCategory.ID] = []

    var orderedCategories: [MenuCategory] {
        categoryOrder.map { id in categories[id]! }
    }

    private var categorySubscriptions: [MenuCategory.ID: AnyCancellable] = [:]

    init(for restaurant: Restaurant) {
        self.restaurant = restaurant

        // TODO[pn 2021-07-30]: Should this actually subscribe to snapshots to
        // get updates to the menu? This may be particularly relevant when
        // considering potential availability changes.
        // TODO, related to above: Research whether changes to subcollection
        // objects (say, menu items in this case) propagate as snapshot
        // notifications to their parent subcollections (menu categories).

        var sub: AnyCancellable?
        sub = restaurant.firestoreReference
            .collection(of: MenuCategory.self)
            .get()
            .flatMap { [unowned self] category -> AnyPublisher<Never, Error> in
                self.categories[category.id] = category
                return listen(to: category).ignoreOutput().eraseToAnyPublisher()
            }
            .mapError { error in
                // TODO[pn 2021-07-29]: We have no good mechanism to report this
                // failure upstream, so instead we crash.
                fatalError("FIXME Failed to load categories in manager: \(String(describing: error))")
            }
            .sink(receiveCompletion: { [unowned self] _ in
                if let _ = sub {
                    sub = nil
                }
                orderCategories()
                hasData = true
            })
    }

    #if DEBUG
    init(debugForRestaurant restaurant: Restaurant, withMenu menu: Menu, categories: Categories) {
        self.restaurant = restaurant
        self.menu = menu
        self.categories = categories
        orderCategories()

        menu.values.forEach { item in
            var items = categoryItems[item.categoryID, default: []]
            items.append(item.fullID)
            categoryItems[item.categoryID] = items
        }
        categoryItems.forEach { categoryID, items in
            categoryItems[categoryID] = items.sorted(by: \.item)
        }

        self.hasData = true
    }
    convenience init(debugForRestaurant restaurant: Restaurant, withAutoMenu autoMenu: [MenuItem],
                     autoCategories: [MenuCategory]) {
        var menu = Menu()
        autoMenu.forEach { item in
            menu[item.fullID] = item
        }
        var categories = Categories()
        autoCategories.forEach { category in
            categories[category.id] = category
        }
        self.init(debugForRestaurant: restaurant, withMenu: menu, categories: categories)
    }
    #endif

    /// - Returns: The contents of the initial snapshot for this category.
    private func listen(to category: MenuCategory) -> AnyPublisher<[MenuItem], Error> {
        let publisher = category.firestoreReference
            .collection(of: MenuItem.self)
            .listen()

        let sub = publisher
            .replaceError(with: [])
            .sink(receiveValue: { [unowned self] items in
                items.forEach { item in
                    self.menu[item.fullID] = item

                    var categoryItems = self.categoryItems[item.categoryID, default: []]
                    if !categoryItems.contains(item.fullID) {
                        categoryItems.insert(item.fullID, sortedBy: \.item)
                        self.categoryItems[item.categoryID] = categoryItems
                    }
                }
            })
        self.categorySubscriptions[category.id] = sub

        return publisher.first().eraseToAnyPublisher()
    }

    private func orderCategories() {
        categoryOrder.removeAll(keepingCapacity: true)

        var mealCategories = [MenuCategory.ID]()
        var drinkCategories = [MenuCategory.ID]()

        categories.values.forEach { category in
            switch category.type {
            case .food: mealCategories.append(category.id)
            case .drink: drinkCategories.append(category.id)
            }
        }

        mealCategories.sort()
        drinkCategories.sort()

        categoryOrder.reserveCapacity(categories.count)
        categoryOrder.append(contentsOf: mealCategories)
        categoryOrder.append(contentsOf: drinkCategories)
    }

    func update(item: MenuItem, setAvailability isAvailable: Bool) -> AnyPublisher<MenuItem, Error> {
        return item.update(isAvailable: isAvailable)
            .map { [unowned self] item in
                self.menu[item.fullID] = item
                return item
            }
            .eraseToAnyPublisher()
    }
}
