//
// Created 7/20/19
// Copyright © 2019 Intro To FI. All rights reserved.
//

import FirebaseDatabase

extension DataSnapshot {
    var decoder: JSONDecoder { .init() }
    func jsonDict() -> [String: Any] {
        var json = value as? [String: Any] ?? [:]
        json["id"] = key
        return json
    }

    func jsonArray() -> [[String: Any]] {
        guard let children = children.allObjects as? [DataSnapshot] else { return [] }
        return children.map { $0.jsonDict() }
    }

    func data() throws -> Data {
        return try JSONSerialization.data(withJSONObject: jsonDict())
    }

    func decode<T: Decodable>() throws -> T {
        return try decoder.decode(T.self, from: data())
    }

    // TODO: Return [Result] here
    func data() -> [Data] {
        return jsonArray().compactMap { try? JSONSerialization.data(withJSONObject: $0) }
    }

    // TODO: Return [Result] here
    func multiDecode<T: Decodable>() -> [T] {
        let oneDecoder = decoder
        return data().compactMap { try? oneDecoder.decode(T.self, from: $0) }
    }
}

extension FirebaseCodable {
    init?(snapshot: DataSnapshot) {
        do {
            self = try snapshot.decode()
        } catch {
            print(error)
            return nil
        }
    }
}
