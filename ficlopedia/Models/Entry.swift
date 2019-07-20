//
// Created 5/18/19
// Copyright © 2019 Intro To FI. All rights reserved.
//

import Foundation

protocol Identifiable {}
enum ID<T: Identifiable>: Equatable, Codable {
    init(from decoder: Decoder) throws {
        let raw = try? decoder.singleValueContainer().decode(String.self)
        if let string = raw {
            self = .saved(string)
        } else {
            self = .unsaved
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .unsaved:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        case let .saved(string), let .unresolved(string):
            var container = encoder.singleValueContainer()
            try container.encode(string)
        }
    }

    case unsaved
    case unresolved(String)
    case saved(String)
}

protocol FirebaseCodable: Codable, Equatable {
    associatedtype T: Identifiable
    var id: ID<T> { get }
    var isSaved: Bool { get }
}

extension FirebaseCodable {
    var isSaved: Bool {
        guard case .saved = id else { return false }
        return true
    }
}

enum EntryStatus: String, Codable, Optionable {
    var optionId: String? { rawValue }

    var name: String { rawValue }

    var subName: String? { nil }

    case published
    case inReview = "in review"
    case draft
    
    static var statuses: [EntryStatus] {
        return [.published, .inReview, .draft]
    }
}

extension FirebaseCodable {
    func json() throws -> [String: Any]? {
        let data = try JSONEncoder().encode(self)
        return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }
}

struct Entry: FirebaseCodable, Identifiable {
    let id: ID<Entry>
    let value: String
    let description: String
    let category: String
    let status: EntryStatus
    let categoryID: ID<Category>?
}

struct Category: FirebaseCodable, Identifiable {
    let id: ID<Category>
    let name: String

    init(id: ID<Category> = .unsaved, name: String) {
        self.id = id
        self.name = name
    }
}

extension Category: Optionable {
    var optionId: String? {
        switch id {
        case let .saved(string):
            return string
        case let .unresolved(string):
            return string
        case .unsaved:
            return nil
        }
    }

    var subName: String? {
        return nil
    }
}

protocol Optionable {
    var optionId: String? { get }
    var name: String { get }
    var subName: String? { get }
}
