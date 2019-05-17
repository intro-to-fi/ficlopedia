//
// Created 5/16/19
// Copyright © 2019 Intro To FI. All rights reserved.
//

import UIKit

class EntryListViewController: UIViewController {
    var entries: [String] = ["Test", "Foobar"]

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension EntryListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "entryListViewCell", for: indexPath)
        let entry = entries[indexPath.row]
        cell.textLabel?.text = entry
        return cell
    }
}

extension EntryListViewController: UITableViewDelegate {
    
}
