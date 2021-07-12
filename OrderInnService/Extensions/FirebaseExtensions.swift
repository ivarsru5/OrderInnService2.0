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
