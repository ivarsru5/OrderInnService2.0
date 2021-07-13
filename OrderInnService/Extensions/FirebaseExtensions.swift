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
}

extension FirebaseFirestore.CollectionReference {
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

protocol FirestoreInitiable {
    init(from snapshot: DocumentSnapshot)
}

struct TypedDocumentReference<Document> where Document : FirestoreInitiable {
    let untyped: DocumentReference

    init(_ reference: DocumentReference) {
        self.untyped = reference
    }

    func get() -> AnyPublisher<Document, Error> {
        return untyped.getDocumentFuture()
            .map { snapshot in Document.init(from: snapshot) }
            .eraseToAnyPublisher()
    }

    func updateData(_ fields: [AnyHashable: Any]) -> AnyPublisher<TypedDocumentReference<Document>, Error> {
        return untyped.updateDataFuture(fields)
            .map { self }
            .eraseToAnyPublisher()
    }

    func collection<Child>(_ path: String, of: Child.Type) -> TypedCollectionReference<Child> where Child : FirestoreInitiable {
        TypedCollectionReference(untyped.collection(path))
    }
}

struct TypedCollectionReference<Document> where Document : FirestoreInitiable {
    let untyped: CollectionReference

    init(_ reference: CollectionReference) {
        self.untyped = reference
    }

    func get() -> AnyPublisher<Document, Error> {
        return untyped.getDocumentsFuture()
            .flatMap { snapshot in
                Record<Document, Error>() { recorder in
                    snapshot.documents.forEach { documentSnapshot in
                        let instance = Document.init(from: documentSnapshot)
                        recorder.receive(instance)
                    }
                    recorder.receive(completion: .finished)
                }
            }
            .eraseToAnyPublisher()
    }

    func document(_ id: String) -> TypedDocumentReference<Document> {
        TypedDocumentReference(untyped.document(id))
    }

    func addDocument(data: [String: Any]) -> TypedDocumentReference<Document> {
        TypedDocumentReference(untyped.addDocument(data: data))
    }
}
