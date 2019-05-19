//
// Created 5/19/19
// Copyright © 2019 Intro To FI. All rights reserved.
//

import FirebaseFirestore

extension DocumentSnapshot {
    func decode<T: FirebaseCodable>() -> T?{
        let decoder = JSONDecoder()
        guard var data = data() else { return nil }
        data["id"] = documentID
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            return try decoder.decode(T.self, from: jsonData)
        } catch {
            print(error)
        }
        return nil
    }
}
