//
//  FirestorePublisher.swift
//  OrderInnService
//
//  Created by paulsnar on 8/12/21.
//

import Combine
import FirebaseFirestore
import Foundation

class FirestoreSnapshotPublisher<Document>: Publisher where Document : FirestoreInitiable {
    typealias Output = [Document]
    typealias Failure = Error

    private enum Demand: Equatable {
        case unknown
        case none
        case some(Int)
        case infinite

        init(from: Subscribers.Demand) {
            if let max = from.max, max == 0 {
                self = .none
            } else if let max = from.max {
                self = .some(max)
            } else {
                self = .infinite
            }
        }

        static func + (_ lhs: Demand, _ rhs: Int) -> Demand {
            switch lhs {
            case .infinite: return lhs
            case .none, .unknown: return .some(rhs)
            case let .some(lhsValue): return .some(lhsValue + rhs)
            }
        }
        static func - (_ lhs: Demand, _ rhs: Int) -> Demand {
            switch lhs {
            case .unknown, .none, .infinite: return lhs
            case let .some(lhsValue):
                let newValue = lhsValue - rhs
                if newValue <= 0 {
                    return .none
                } else {
                    return .some(lhsValue - rhs)
                }
            }
        }
    }
    private class Sub: Subscription {
        private weak var publisher: FirestoreSnapshotPublisher<Document>?
        private let id: CombineIdentifier

        init(_ publisher: FirestoreSnapshotPublisher<Document>, _ id: CombineIdentifier) {
            self.publisher = publisher
            self.id = id
        }

        func request(_ demand: Subscribers.Demand) {
            guard let publisher = self.publisher else { return }
            guard let (subscriber, oldDemand) = publisher.subscribers[id] else { return }
            guard oldDemand != .infinite else { return }

            let newDemand = Demand(from: demand)
            let updatedDemand: Demand
            switch newDemand {
            case .none, .infinite: updatedDemand = newDemand
            case let .some(value): updatedDemand = oldDemand + value
            case .unknown: preconditionFailure()
            }

            publisher.queue.async { [self] in
                publisher.subscribers[id] = (subscriber, updatedDemand)
                publisher.updateSubscription()
            }
        }

        func cancel() {
            guard let publisher = self.publisher else { return }
            publisher.queue.async { [self] in
                publisher.subscribers.removeValue(forKey: self.id)
            }
        }
    }

    private var registration: ListenerRegistration?
    private var query: FirebaseFirestore.Query
    private let includeMetadataChanges: Bool
    private typealias AnySub = AnySubscriber<Output, Failure>
    private typealias StoredSub = (AnySub, Demand)
    private var hasAnyDemand = false
    private var subscribers: [CombineIdentifier: StoredSub] = [:]
    private let queue = DispatchQueue(label: "FirestorePublisher",
                                      qos: .utility,
                                      attributes: [],
                                      autoreleaseFrequency: .workItem,
                                      target: DispatchQueue.main)

    init(query: TypedQuery<Document>, includeMetadataChanges: Bool = false) {
        self.query = query.untyped
        self.includeMetadataChanges = includeMetadataChanges
    }

    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        queue.async { [self] in
            subscribers[subscriber.combineIdentifier] = (AnySub(subscriber), .unknown)

            let subscription = Sub(self, subscriber.combineIdentifier)
            subscriber.receive(subscription: subscription)
        }
    }

    private func updateSubscription() {
        let hasDemand = subscribers.contains(where: { _, data in
            switch data.1 {
            case .some(_), .infinite: return true
            default: return false
            }
        })
        if hasDemand && registration == nil {
            registration = query.addSnapshotListener(includeMetadataChanges: includeMetadataChanges,
                                                     listener: self.handleSnapshotEvent)
        } else if !hasDemand, let reg = registration {
            reg.remove()
            registration = nil
        }
    }

    private func send(_ value: Output) {
        var subscribers = self.subscribers
        subscribers.forEach { id, data in
            let (subscriber, oldDemand) = data
            let newDemand: Demand
            switch oldDemand {
            case .none, .unknown, .some(0): newDemand = oldDemand
            case .infinite:
                _ = subscriber.receive(value)
                newDemand = oldDemand
            case .some(_):
                switch Demand(from: subscriber.receive(value)) {
                case .none: newDemand = oldDemand - 1
                case let .some(value): newDemand = oldDemand - 1 + value
                case .infinite: newDemand = .infinite
                case .unknown: preconditionFailure()
                }
            }

            subscribers[id] = (subscriber, newDemand)
        }

        self.subscribers = subscribers
        updateSubscription()
    }

    private func send(completion: Subscribers.Completion<Failure>) {
        subscribers.forEach { _, data in
            let subscriber = data.0
            subscriber.receive(completion: completion)
        }
        subscribers.removeAll()
        registration?.remove()
        registration = nil
    }

    private func handleSnapshotEvent(_ maybeSnapshot: QuerySnapshot?, _ maybeError: Error?) {
        guard let snapshot = maybeSnapshot else {
            queue.async { [self] in
                send(completion: .failure(maybeError!))
            }
            return
        }

        let documents = snapshot.documents.map { (rawSnapshot: FirebaseFirestore.DocumentSnapshot) -> Document in
            let snapshot = KeyedDocumentSnapshot(rawSnapshot, document: Document.self)
            return Document.init(from: snapshot)
        }
        queue.async { [self] in
            send(documents)
        }
    }
}
