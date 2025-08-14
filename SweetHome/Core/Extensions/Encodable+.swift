//
//  Encodable+.swift
//  SweetHome
//
//  Created by 김민호 on 8/12/25.
//

import Foundation

extension Encodable {
    func toDictionary() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self),
              let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dictionary
    }
}
