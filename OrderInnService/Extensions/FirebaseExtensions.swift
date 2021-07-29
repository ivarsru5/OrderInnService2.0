//
//  FirebaseExtensions.swift
//  OrderInnService
//
//  Created by paulsnar on 7/9/21.
//

import Foundation
import FirebaseFirestore
import Combine

extension FirebaseFirestore.DocumentReference {
    func getDocumentFuture() -> Future<DocumentSnapshot, Error> {
        return Future() { [self] resolve in
            getDocument { maybeSnapshot, error in
                guard let snapshot = maybeSnapshot else {
                    resolve(.failure(error!))
                    return
                }

                resolve(.success(snapshot))
            }
        }
    }

    func updateDataFuture(_ fields: [AnyHashable: Any]) -> Future<Void, Error> {
        return Future() { [self] resolve in
            updateData(fields, completion: { maybeError in
                if let error = maybeError {
                    resolve(.failure(error))
                } else {
                    resolve(.success(()))
                }
            })
        }
    }

    func deleteFuture() -> Future<Void, Error> {
        return Future() { [self] resolve in
            delete(completion: { maybeError in
                if let error = maybeError {
                    resolve(.failure(error))
                } else {
                    resolve(.success(()))
                }
            })
        }
    }
}

extension FirebaseFirestore.Query {
    func getDocumentsFuture() -> Future<QuerySnapshot, Error> {
        return Future() { [self] resolve in
            getDocuments { maybeSnapshot, error in
                guard let snapshot = maybeSnapshot else {
                    resolve(.failure(error!))
                    return
                }

                resolve(.success(snapshot))
            }
        }
    }
}

extension FirebaseFirestore.CollectionReference {
    func addDocumentFuture(data: [String: Any]) -> Future<FirebaseFirestore.DocumentReference, Error> {
        return Future() { [self] resolve in
            var ref: FirebaseFirestore.DocumentReference?
            ref = addDocument(data: data, completion: { maybeError in
                if let error = maybeError {
                    resolve(.failure(error))
                } else {
                    resolve(.success(ref!))
                }
            })
        }
    }
}

protocol FirestoreInitiable {
    static var firestoreCollection: String { get }
    var firestoreReference: TypedDocumentReference<Self> { get }
    init(from snapshot: DocumentSnapshot)
}

struct TypedDocumentReference<Document> where Document : FirestoreInitiable {
    #if DEBUG
    let rawUntyped: DocumentReference?
    var untyped: DocumentReference {
        rawUntyped!
    }
    let idOverride: String?
    init(_ reference: DocumentReference?, idOverride: String? = nil) {
        self.rawUntyped = reference
        self.idOverride = idOverride
    }
    init(_ reference: DocumentReference) {
        self.rawUntyped = reference
        self.idOverride = nil
    }
    #else
    let untyped: DocumentReference
    init(_ reference: DocumentReference) {
        self.untyped = reference
    }
    #endif

    var documentID: String {
        #if DEBUG
        idOverride ?? untyped.documentID
        #else
        untyped.documentID
        #endif
    }

    func get() -> AnyPublisher<Document, Error> {
        return untyped.getDocumentFuture()
            .map { snapshot in Document.init(from: snapshot) }
            .eraseToAnyPublisher()
    }

    func delete() -> AnyPublisher<Void, Error> {
        return untyped.deleteFuture().eraseToAnyPublisher()
    }

    func updateData(_ fields: [AnyHashable: Any]) -> AnyPublisher<TypedDocumentReference<Document>, Error> {
        return untyped.updateDataFuture(fields)
            .map { self }
            .eraseToAnyPublisher()
    }

    func parentDocument<Parent>(ofKind: Parent.Type) -> TypedDocumentReference<Parent> where Parent : FirestoreInitiable {
        return TypedDocumentReference<Parent>(untyped.parent.parent!)
    }

    func collection<Child>(_ path: String, of: Child.Type) -> TypedCollectionReference<Child> where Child : FirestoreInitiable {
        TypedCollectionReference(untyped.collection(path))
    }
    func collection<Child>(of: Child.Type) -> TypedCollectionReference<Child> where Child : FirestoreInitiable {
        TypedCollectionReference(untyped.collection(Child.firestoreCollection))
    }
}

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

    fileprivate init(query: TypedQuery<Document>, includeMetadataChanges: Bool = false) {
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

        let documents = snapshot.documents.map { doc in Document(from: doc) }
        queue.async { [self] in
            send(documents)
        }
    }
}

struct TypedCollectionReference<Document> where Document : FirestoreInitiable {
    let untyped: CollectionReference

    init(_ reference: CollectionReference) {
        self.untyped = reference
    }

    var query: TypedQuery<Document> {
        TypedQuery(untyped)
    }

    func get() -> AnyPublisher<Document, Error> {
        return untyped.getDocumentsFuture()
            .flatMap { snapshot in
                Record<Document, Error>() { recording in
                    snapshot.documents.forEach { documentSnapshot in
                        let instance = Document.init(from: documentSnapshot)
                        recording.receive(instance)
                    }
                    recording.receive(completion: .finished)
                }
            }
            .eraseToAnyPublisher()
    }
    func listen(includeMetadataChanges: Bool = false) -> AnyPublisher<[Document], Error> {
        let pub = FirestoreSnapshotPublisher(query: query, includeMetadataChanges: includeMetadataChanges)
        return pub.eraseToAnyPublisher()
    }

    func document(_ id: String) -> TypedDocumentReference<Document> {
        TypedDocumentReference(untyped.document(id))
    }

    /// Adds a document.
    ///
    /// The resulting reference may not be valid since this method doesn't wait for confirmation before
    /// returning it. For that, please use `addDocumentAndCommit`.
    func addDocument(data: [String: Any]) -> TypedDocumentReference<Document> {
        TypedDocumentReference(untyped.addDocument(data: data))
    }

    /// Adds a document and waits until confirmation from the server.
    func addDocumentAndCommit(data: [String: Any]) -> AnyPublisher<TypedDocumentReference<Document>, Error> {
        untyped.addDocumentFuture(data: data)
            .map { ref in TypedDocumentReference<Document>(ref) }
            .eraseToAnyPublisher()
    }
}

struct TypedQuery<Document> where Document : FirestoreInitiable {
    let untyped: Query

    init(_ query: Query) {
        self.untyped = query
    }

    func get() -> AnyPublisher<Document, Error> {
        return untyped.getDocumentsFuture()
            .flatMap { snapshot in
                Record<Document, Error>() { recording in
                    snapshot.documents.forEach { documentSnapshot in
                        let instance = Document.init(from: documentSnapshot)
                        recording.receive(instance)
                    }
                    recording.receive(completion: .finished)
                }
            }
            .eraseToAnyPublisher()
    }
    func listen(includeMetadataChanges: Bool = false) -> AnyPublisher<[Document], Error> {
        let pub = FirestoreSnapshotPublisher(query: self, includeMetadataChanges: includeMetadataChanges)
        return pub.eraseToAnyPublisher()
    }

    func whereField(_ field: String, isEqualTo value: Any) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(field, isEqualTo: value))
    }
    func whereField(_ field: String, isNotEqualTo value: Any) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(field, isNotEqualTo: value))
    }
    func whereField(_ field: String, isLessThan value: Any) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(field, isLessThan: value))
    }
    func whereField(_ field: String, isLessThanOrEqualTo value: Any) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(field, isLessThanOrEqualTo: value))
    }
    func whereField(_ field: String, isGreaterThan value: Any) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(field, isGreaterThan: value))
    }
    func whereField(_ field: String, isGreaterThanOrEqualTo value: Any) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(field, isGreaterThanOrEqualTo: value))
    }
    func whereField(_ field: String, in values: [Any]) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(field, in: values))
    }
    func whereField(_ field: String, notIn values: [Any]) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(field, notIn: values))
    }
    func whereField(_ field: String, arrayContains value: Any) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(field, arrayContains: value))
    }
    func whereField(_ field: String, arrayContainsAny values: [Any]) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(field, arrayContainsAny: values))
    }

    func whereField(_ fieldPath: FieldPath, isEqualTo value: Any) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(fieldPath, isEqualTo: value))
    }
    func whereField(_ fieldPath: FieldPath, isNotEqualTo value: Any) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(fieldPath, isNotEqualTo: value))
    }
    func whereField(_ fieldPath: FieldPath, isLessThan value: Any) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(fieldPath, isLessThan: value))
    }
    func whereField(_ fieldPath: FieldPath, isLessThanOrEqualTo value: Any) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(fieldPath, isLessThanOrEqualTo: value))
    }
    func whereField(_ fieldPath: FieldPath, isGreaterThan value: Any) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(fieldPath, isGreaterThan: value))
    }
    func whereField(_ fieldPath: FieldPath, isGreaterThanOrEqualTo value: Any) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(fieldPath, isGreaterThanOrEqualTo: value))
    }
    func whereField(_ fieldPath: FieldPath, in values: [Any]) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(fieldPath, in: values))
    }
    func whereField(_ fieldPath: FieldPath, notIn values: [Any]) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(fieldPath, notIn: values))
    }
    func whereField(_ fieldPath: FieldPath, arrayContains value: Any) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(fieldPath, arrayContains: value))
    }
    func whereField(_ fieldPath: FieldPath, arrayContainsAny values: [Any]) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(fieldPath, arrayContainsAny: values))
    }

    func filter(using predicate: NSPredicate) -> TypedQuery<Document> {
        TypedQuery(untyped.filter(using: predicate))
    }

    func order(by field: String, descending: Bool = false) -> TypedQuery<Document> {
        TypedQuery(untyped.order(by: field, descending: descending))
    }
    func order(by fieldPath: FieldPath, descending: Bool = false) -> TypedQuery<Document> {
        TypedQuery(untyped.order(by: fieldPath, descending: descending))
    }

    func limit(to limit: Int) -> TypedQuery<Document> {
        TypedQuery(untyped.limit(to: limit))
    }
    func limit(toLast limit: Int) -> TypedQuery<Document> {
        TypedQuery(untyped.limit(toLast: limit))
    }

    func start(atDocument document: DocumentSnapshot) -> TypedQuery<Document> {
        TypedQuery(untyped.start(atDocument: document))
    }
    func start(at fieldValues: [Any]) -> TypedQuery<Document> {
        TypedQuery(untyped.start(at: fieldValues))
    }
    func start(afterDocument document: DocumentSnapshot) -> TypedQuery<Document> {
        TypedQuery(untyped.start(afterDocument: document))
    }
    func start(after fieldValues: [Any]) -> TypedQuery<Document> {
        TypedQuery(untyped.start(after: fieldValues))
    }
    func end(atDocument document: DocumentSnapshot) -> TypedQuery<Document> {
        TypedQuery(untyped.end(atDocument: document))
    }
    func end(at fieldValues: [Any]) -> TypedQuery<Document> {
        TypedQuery(untyped.end(at: fieldValues))
    }
    func end(beforeDocument document: DocumentSnapshot) -> TypedQuery<Document> {
        TypedQuery(untyped.end(beforeDocument: document))
    }
    func end(before fieldValues: [Any]) -> TypedQuery<Document> {
        TypedQuery(untyped.end(before: fieldValues))
    }
}
