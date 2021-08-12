//
//  TypedExtensions.swift
//  OrderInnService
//
//  Created by paulsnar on 8/12/21.
//

import Combine
import FirebaseFirestore
import Foundation

protocol FirestoreInitiable {
    associatedtype Key: CodingKey & Hashable
    static var firestoreCollection: String { get }
    var firestoreReference: TypedDocumentReference<Self> { get }
    init(from snapshot: KeyedDocumentSnapshot<Self>)
}

/// A Firestore DocumentSnapshot with a predefined set of valid keys.
///
/// A KeyedDocumentSnapshot always exists, so checking for `untyped.exists` is unnecessary.
struct KeyedDocumentSnapshot<Document: FirestoreInitiable> {
    typealias Key = Document.Key

    let untyped: FirebaseFirestore.DocumentSnapshot
    init(_ source: FirebaseFirestore.DocumentSnapshot, document: Document.Type) {
        self.untyped = source
    }

    var documentID: String {
        untyped.documentID
    }
    var reference: TypedDocumentReference<Document> {
        TypedDocumentReference(untyped.reference)
    }

    subscript(_ key: Key) -> Any? {
        return untyped.get(key.stringValue)
    }
    subscript(_ key: Key, fallback fallback: Key, otherFallbacks: Key...) -> Any? {
        var value = self[key]
        value = value ?? self[fallback]

        var index = otherFallbacks.startIndex
        while value == nil && index < otherFallbacks.endIndex {
            let key = otherFallbacks[index]
            value = self[key]
            index = otherFallbacks.index(after: index)
        }

        return value
    }
}

extension FirebaseFirestore.DocumentSnapshot {
    func keyed<Document: FirestoreInitiable>(for document: Document.Type) -> KeyedDocumentSnapshot<Document> {
        precondition(self.exists)
        return KeyedDocumentSnapshot(self, document: Document.self)
    }
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

    func get(forceReload: Bool = false) -> AnyPublisher<Document, Error> {
        return untyped.getDocumentFuture(source: forceReload ? .server : .default)
            .map { rawSnapshot in
                let snapshot = rawSnapshot.keyed(for: Document.self)
                return Document.init(from: snapshot)
            }
            .eraseToAnyPublisher()
    }

    func delete() -> AnyPublisher<Void, Error> {
        return untyped.deleteFuture().eraseToAnyPublisher()
    }

    func updateData(_ fields: [Document.Key: Any]) -> AnyPublisher<TypedDocumentReference<Document>, Error> {
        let mappedData = fields.mapKeys { element in element.key.stringValue }
        return untyped.updateDataFuture(mappedData)
            .map { self }
            .eraseToAnyPublisher()
    }

    func parentDocument<Parent>(ofKind: Parent.Type) -> TypedDocumentReference<Parent> where Parent : FirestoreInitiable {
        return TypedDocumentReference<Parent>(untyped.parent.parent!)
    }

    @available(*, deprecated, message: "Use collection(of:) instead of specifying the path manually")
    func collection<Child>(_ path: String, of: Child.Type) -> TypedCollectionReference<Child> where Child : FirestoreInitiable {
        TypedCollectionReference(untyped.collection(path))
    }
    func collection<Child>(of: Child.Type) -> TypedCollectionReference<Child> where Child : FirestoreInitiable {
        TypedCollectionReference(untyped.collection(Child.firestoreCollection))
    }
}

struct TypedCollectionReference<Document> where Document : FirestoreInitiable {
    let untyped: CollectionReference

    init(_ reference: CollectionReference) {
        self.untyped = reference
    }

    static func root(_ firestore: Firestore, of type: Document.Type) -> TypedCollectionReference<Document> {
        return self.init(firestore.collection(type.firestoreCollection))
    }

    var query: TypedQuery<Document> {
        TypedQuery(untyped)
    }

    func get() -> AnyPublisher<Document, Error> {
        return untyped.getDocumentsFuture()
            .flatMap { snapshot in
                Record<Document, Error>() { recording in
                    snapshot.documents.forEach { rawDocumentSnapshot in
                        let documentSnapshot = rawDocumentSnapshot.keyed(for: Document.self)
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
    func addDocument(data: [Document.Key: Any]) -> TypedDocumentReference<Document> {
        let mappedData = data.mapKeys { (key, _) -> String in key.stringValue }
        return TypedDocumentReference(untyped.addDocument(data: mappedData))
    }

    /// Adds a document and waits until confirmation from the server.
    func addDocumentAndCommit(data: [Document.Key: Any]) -> AnyPublisher<TypedDocumentReference<Document>, Error> {
        let mappedData = data.mapKeys { (key, _) -> String in key.stringValue }
        return untyped.addDocumentFuture(data: mappedData)
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
                    snapshot.documents.forEach { rawDocumentSnapshot in
                        let documentSnapshot = rawDocumentSnapshot.keyed(for: Document.self)
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

    func whereField(_ field: Document.Key, isEqualTo value: Any) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(field.stringValue, isEqualTo: value))
    }
    func whereField(_ field: Document.Key, isNotEqualTo value: Any) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(field.stringValue, isNotEqualTo: value))
    }
    func whereField(_ field: Document.Key, isLessThan value: Any) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(field.stringValue, isLessThan: value))
    }
    func whereField(_ field: Document.Key, isLessThanOrEqualTo value: Any) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(field.stringValue, isLessThanOrEqualTo: value))
    }
    func whereField(_ field: Document.Key, isGreaterThan value: Any) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(field.stringValue, isGreaterThan: value))
    }
    func whereField(_ field: Document.Key, isGreaterThanOrEqualTo value: Any) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(field.stringValue, isGreaterThanOrEqualTo: value))
    }
    func whereField(_ field: Document.Key, in values: [Any]) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(field.stringValue, in: values))
    }
    func whereField(_ field: Document.Key, notIn values: [Any]) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(field.stringValue, notIn: values))
    }
    func whereField(_ field: Document.Key, arrayContains value: Any) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(field.stringValue, arrayContains: value))
    }
    func whereField(_ field: Document.Key, arrayContainsAny values: [Any]) -> TypedQuery<Document> {
        TypedQuery(untyped.whereField(field.stringValue, arrayContainsAny: values))
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

    func order(by field: Document.Key, descending: Bool = false) -> TypedQuery<Document> {
        TypedQuery(untyped.order(by: field.stringValue, descending: descending))
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
