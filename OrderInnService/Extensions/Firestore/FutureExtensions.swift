//
//  Extensions.swift
//  OrderInnService
//
//  Created by paulsnar on 8/12/21.
//

import Combine
import FirebaseFirestore
import Foundation

extension FirebaseFirestore.DocumentReference {
    func getDocumentFuture(source: FirestoreSource = .default) -> Future<DocumentSnapshot, Error> {
        return Future() { [self] resolve in
            getDocument(source: source) { maybeSnapshot, error in
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
    func getDocumentsFuture(source: FirestoreSource = .default) -> Future<QuerySnapshot, Error> {
        return Future() { [self] resolve in
            getDocuments(source: source) { maybeSnapshot, error in
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
