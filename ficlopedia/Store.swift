//
// Created 7/28/19
// Copyright © 2019 Intro To FI. All rights reserved.
//

import Foundation
import FirebaseDatabase

class Store {
    static var categories: [Category] = [] {
        didSet {
            guard categories != oldValue else { return }
            categoryListener?(categories)
        }
    }
    static let db: Database = Database.database()
    static let categoryRef: DatabaseReference = db.reference(withPath: "categories")

    static var categoryListenerHandle: DatabaseHandle?

    static var categoryListener: (([Category]) -> Void)? = nil
    static func onCategoryChanges(closure: @escaping (([Category]) -> Void)) {
        categoryListener = closure
    }

    static let encoder: JSONEncoder = .init()
    static let decoder: JSONDecoder = .init()

    static func setupRealtimeDatabase() {
        Database.database().isPersistenceEnabled = true
    }

    static func listenForCategoryChanges() {
        guard categoryListenerHandle == nil else { return }
        categoryListenerHandle = categoryRef.observe(.value, with: { snapshot in
            categories = (snapshot.children.allObjects as? [DataSnapshot])?.compactMap(Category.init) ?? []
        }) { error in
            guard let handle = categoryListenerHandle else { return }
            categoryRef.removeObserver(withHandle: handle)
        }
    }

    static func fetchCategories(completion: (() -> Void)? = nil) {
        guard categoryListenerHandle == nil else { return }
        categoryRef.observeSingleEvent(of: .value) { snapshot in
            categories = snapshot.multiDecode()
            completion?()
        }
    }

    static func add(_ category: Category) throws {
        categoryRef.childByAutoId().setValue(try category.json())
    }
}
