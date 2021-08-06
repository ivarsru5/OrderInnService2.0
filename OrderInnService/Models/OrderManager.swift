//
//  OrderManager.swift
//  OrderInnService
//
//  Created by paulsnar on 8/3/21.
//

import Combine
import Foundation

class OrderManager: ObservableObject {
    let restaurant: Restaurant
    @Published var hasData = false
    @Published var orders: [RestaurantOrder] = []

    private var orderListenerSub: AnyCancellable?

    enum SubscriptionScope {
        /// Listen for orders only where the `placedBy` attribute equals that of this employee.
        case onlyPlacedBy(employee: Restaurant.Employee)

        /// Listen for all orders within the given restaurant.
        case all

        init(defaultFor employee: Restaurant.Employee) {
            if employee.manager {
                self = .all
            } else {
                self = .onlyPlacedBy(employee: employee)
            }
        }

        func makeQuery(restaurant: Restaurant) -> TypedQuery<RestaurantOrder> {
            var query = restaurant.firestoreReference
                .collection(of: RestaurantOrder.self)
                .query

            if case let .onlyPlacedBy(employee) = self {
                query = query.whereField("placedBy", isEqualTo: employee.firestoreReference.untyped)
            }

            query = query.order(by: "createdAt", descending: true)

            return query
        }
    }

    init(for restaurant: Restaurant, scope: SubscriptionScope) {
        self.restaurant = restaurant

        orderListenerSub = scope.makeQuery(restaurant: restaurant)
            .listen()
            .mapError { error in
                // TODO[pn 2021-08-03] Similarly to MenuManager, there's no good
                // way to surface this error---although in this case it's more
                // managable, what with the narrower scope and all.
                fatalError("FIXME Failed to subscribe to order updates: \(String(describing: error))")
            }
            .sink { [unowned self] orders in
                if !self.hasData {
                    self.hasData = true
                }
                self.orders = orders.sorted(by: OrderManager.orderComparator)
            }
    }

    fileprivate static func orderComparator(_ a: RestaurantOrder, _ b: RestaurantOrder) -> Bool {
        if a.state != b.state {
            return a.state < b.state
        }
        return b.createdAt < a.createdAt
    }

    #if DEBUG
    init(debugForRestaurant restaurant: Restaurant, withOrders orders: [RestaurantOrder]) {
        self.restaurant = restaurant
        self.orders = orders.sorted(by: OrderManager.orderComparator)
        self.orderListenerSub = nil
        self.hasData = true
    }
    #endif

    func update(order: RestaurantOrder, setState state: RestaurantOrder.OrderState) -> AnyPublisher<RestaurantOrder, Error> {
        return order.updateState(state)
            .map { [unowned self] order in
                if let index = self.orders.firstIndex(where: { $0.id == order.id }) {
                    self.orders[index] = order
                } else {
                    self.orders.append(order)
                }
                self.orders.sort(by: OrderManager.orderComparator)
                return order
            }
            .eraseToAnyPublisher()
    }

    func addPart(_ part: RestaurantOrder.OrderPart, to order: RestaurantOrder) -> AnyPublisher<RestaurantOrder, Error> {
        return order.addPart(part)
            .map { [unowned self] order in
                if let index = self.orders.firstIndex(where: { $0.id == order.id }) {
                    self.orders[index] = order
                } else {
                    self.orders.append(order)
                }
                self.orders.sort(by: OrderManager.orderComparator)
                return order
            }
            .eraseToAnyPublisher()
    }
}

#if O6N_TEST
import XCTest

class OrderManagerTests: XCTestCase {
    typealias Order = RestaurantOrder

    private var orderSequence = 1
    private func makeOrder(id: String? = nil,
                           state: RestaurantOrder.OrderState,
                           createdAt: Date,
                           parts: [RestaurantOrder.OrderPart] = []) -> RestaurantOrder {
        defer {
            orderSequence += 1
        }
        let concreteID = id ?? "O-\(orderSequence)"
        return Order(restaurantID: "R", id: concreteID,
                     state: state, table: "T", placedBy: "E",
                     createdAt: createdAt, parts: parts)
    }

    func testOrderComparator() {
        let comparator = OrderManager.orderComparator

        let parser = ISO8601DateFormatter()
        let dateA = parser.date(from: "2021-08-01T18:00:00Z")!
        let dateB = dateA.advanced(by: 3600)

        var orders = [
            makeOrder(id: "C-A", state: .closed, createdAt: dateA),
            makeOrder(id: "C-B", state: .closed, createdAt: dateB),
            makeOrder(id: "O-A", state: .open, createdAt: dateA),
            makeOrder(id: "O-B", state: .open, createdAt: dateB),
            makeOrder(id: "N-A", state: .new, createdAt: dateA),
            makeOrder(id: "N-B", state: .new, createdAt: dateB),
        ]

        orders.sort(by: comparator)

        let expectedIDOrder = ["N-B", "N-A", "O-B", "O-A", "C-B", "C-A"]
        orders.indices.forEach { index in
            let order = orders[index]
            let expectedID = expectedIDOrder[index]
            XCTAssertEqual(order.id, expectedID,
                "Ordering failure at index \(index): expected ID \(expectedID), got ID \(order.id)")
        }
    }
}
#endif
