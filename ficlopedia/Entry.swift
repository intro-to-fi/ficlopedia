//
// Created 5/18/19
// Copyright © 2019 Intro To FI. All rights reserved.
//

import Foundation

struct Entry: FirebaseCodable {
    let id: String?
    let value: String
    let description: String
    let status: EntryStatus
}

protocol FirebaseCodable: Codable {
    var id: String? { get }
}

enum EntryStatus: String, Codable {
    case published
    case inReview = "in review"
    case draft
}

extension FirebaseCodable {
    var data: [String: Any] {
        do {
            let foo = try JSONEncoder().encode(self)
            let data = try JSONSerialization.jsonObject(with: foo, options: []) as? [String: Any]
            return data ?? [:]
        } catch {
            print(error.localizedDescription)
            return [:]
        }
    }
}
