//
// Created 5/16/19
// Copyright © 2019 Intro To FI. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import FirebaseCore
import FirebaseFirestore
import UIKit

class EntryListViewController: UIViewController {
    let db = Firestore.firestore()
    let spinner = UIActivityIndicatorView()
    let searchController = UISearchController(searchResultsController: nil)
    let filterDebouncer = Debouncer()

    @IBOutlet weak var tableview: UITableView!

    var entries: [Entry] = [] {
        didSet {
            let set = Set(entries.map { categoryFor(id: $0.categoryID) + ": " + $0.status.rawValue })
            categories = set
                .sorted(by: { $0 < $1 })
                .map { section in (section, entries.filter { categoryFor(id: $0.categoryID) + ": " + $0.status.rawValue == section }) }
            tableview.reloadData()
            entries.isEmpty ? spinner.startAnimating() : spinner.stopAnimating()

//            entries.forEach { entry in
//                guard entry.value == "Triple Value of Income" else { return }
//                guard case let .saved(id) = entry.id, let json = try? entry.json() else { return }
//                print(entry.value, entry.category)
//                let ref = Database.database().reference(withPath: "entries").childByAutoId()
//                ref.setValue(json)
//                let key = ref.key!
//                Firestore.firestore().collection("entries").document(id).updateData(["rtdKey": key])
//                Firestore.firestore().collection("entries").document(id).updateData(["categoryID": categoryID])
//            }
        }
    }

    func categoryFor(string: String) -> Category? {
        let categories = Store.categories
        return categories.first { $0.name == string }
    }

    func categoryFor(id: ID<Category>) -> String {
        let categories = Store.categories
        return categories.first { $0.id == id }?.name ?? "[Unknown Category]"
    }

    private var filteredEntries: [Entry] = []  {
        didSet {
            let set = Set(filteredEntries.map { categoryFor(id: $0.categoryID) + ": " + $0.status.rawValue })
            filteredCategories = set
                .sorted(by: { $0 < $1 })
                .map { section in (section, filteredEntries.filter { categoryFor(id: $0.categoryID) + ": " + $0.status.rawValue == section }) }
            tableview.reloadData()
        }
    }
    
    private var categories: [(category: String, entries: [Entry])] = []
    private var filteredCategories: [(category: String, entries: [Entry])] = []
    var tableData: [(category: String, entries: [Entry])] {
        return searchController.isActive ? filteredCategories : categories
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        Store.fetchCategories()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshData()
    }
    
    @IBAction func didTapAdd(_ sender: UIBarButtonItem) {
        navigateToEntryView(with: nil)
    }
    
    @objc
    private func refreshData() {
        db.collection("entries").getDocuments() { (querySnapshot, err) in
            self.tableview.refreshControl?.endRefreshing()
            self.entries = querySnapshot?.documents
                .compactMap { $0.decode() }
                .sorted { $0.value < $1.value } ?? []
        }
    }
    
    private func navigateToEntryView(with entry: Entry?) {
        guard let vc = UIStoryboard(name: "EntryList", bundle: nil)
            .instantiateViewController(withIdentifier: "entryDetailViewController") as? EntryDetailViewController else { return }
        navigationController?.pushViewController(vc, animated: true)
        if let entry = entry {
            vc.configure(with: entry)
        }
    }
    
    private func setupView() {
        title = "Entry List"
        spinner.hidesWhenStopped = true
        spinner.startAnimating()
        view.addSubview(spinner)
        spinner.style = .whiteLarge
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        spinner.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        spinner.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        spinner.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        spinner.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
        
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        searchController.searchResultsUpdater = self
        searchController.searchBar.scopeButtonTitles = ["All"] + EntryStatus.statuses.map { $0.name }
        searchController.searchBar.delegate = self
        searchController.searchBar.autocapitalizationType = .words
        searchController.searchBar.spellCheckingType = .yes
        searchController.searchBar.autocorrectionType = .yes
        navigationItem.searchController = searchController


        let refreshControl = UIRefreshControl()
        tableview.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableview.tableFooterView = UIView()
    }
    
    func filterResults(_ searchBar: UISearchBar?) {
        filterDebouncer.debounce {
            var filtered = self.entries
            defer { self.filteredEntries = filtered}
            if let scopeIndex = searchBar?.selectedScopeButtonIndex,
                scopeIndex != 0,
                let status = EntryStatus(rawValue: EntryStatus.statuses[scopeIndex - 1].name) {
                filtered = filtered.filter { $0.status == status }
            }
            guard let searchText = searchBar?.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                !searchText.isEmpty else { return }
            let searchEntries = searchText.split(separator: " ")
            filtered = filtered.filter { entry in
                return searchEntries.map { searchEntry in
                    entry.value.lowercased().contains(searchEntry.lowercased()) ||
                    entry.description.lowercased().contains(searchEntry.lowercased()) ||
                    self.categoryFor(id: entry.categoryID).lowercased().contains(searchEntry.lowercased()) ||
                    entry.status.rawValue.lowercased().contains(searchEntry.lowercased())
                }
                .reduce(true, { $0 && $1 })
            }
            if !filtered.contains(where: { $0.value.lowercased() == searchText.lowercased() }) {
                let title = searchText.split(separator: " ").map { $0.prefix(1).uppercased() + $0.lowercased().dropFirst() }.joined(separator: " ")
                filtered += [Entry(id: .unsaved, value: title, description: "", status: .draft, categoryID: .unsaved, rtdKey: .unsaved)]
            }
        }
    }
}

extension EntryListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterResults(searchController.searchBar)
    }
}

extension EntryListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterResults(searchBar)
    }
}

extension EntryListViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableData[section].category
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].entries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "entryListViewCell", for: indexPath)
        let entry = tableData[indexPath.section].entries[indexPath.row]
        cell.textLabel?.text = entry.value
        cell.detailTextLabel?.text = entry.description
        return cell
    }
}

extension EntryListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let entry = tableData[indexPath.section].entries[indexPath.row]
        navigateToEntryView(with: entry)
    }
}
