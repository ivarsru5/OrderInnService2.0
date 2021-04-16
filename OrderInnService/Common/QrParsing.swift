//
//  QrParsing.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 16/04/2021.
//

import Foundation

struct QRURL{
    let restaurant: String
    
    static func validateQrString(from input: String) -> QRURL?{
        guard let url = URL.init(string: input) else { return nil }
        guard url.scheme == "orderInnService" && url.host == "qr1" else{ return nil }
        let pathParts = url.path.split(separator: "/")
        guard pathParts.count == 1 else { return nil }
        return QRURL.init(restaurant: String.init(pathParts[0]))
    }
}
