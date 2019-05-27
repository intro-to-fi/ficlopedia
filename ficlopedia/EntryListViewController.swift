//
// Created 5/16/19
// Copyright © 2019 Intro To FI. All rights reserved.
//

import FirebaseAuth
import FirebaseFirestore
import UIKit

class EntryListViewController: UIViewController {
    let db = Firestore.firestore()
    let spinner = UIActivityIndicatorView()
    let searchController = UISearchController(searchResultsController: nil)

    @IBOutlet weak var tableview: UITableView!

    var entries: [Entry] = [] {
        didSet {
            let set = Set(entries.map { ($0.category ?? "[No Category]") + ": " + $0.status.rawValue })
            categories = set
                .sorted(by: { $0 < $1 })
                .map { section in (section, entries.filter { ($0.category ?? "[No Category]") + ": " + $0.status.rawValue == section }) }
            tableview.reloadData()
            entries.isEmpty ? spinner.startAnimating() : spinner.stopAnimating()
        }
    }
    
    private var filteredEntries: [Entry] = []  {
        didSet {
            let set = Set(filteredEntries.map { ($0.category ?? "[No Category]") + ": " + $0.status.rawValue })
            filteredCategories = set
                .sorted(by: { $0 < $1 })
                .map { section in (section, filteredEntries.filter { ($0.category ?? "[No Category]") + ": " + $0.status.rawValue == section }) }
            tableview.reloadData()
        }
    }
    
    private var categories: [(category: String?, entries: [Entry])] = []
    private var filteredCategories: [(category: String?, entries: [Entry])] = []
    var tableData: [(category: String?, entries: [Entry])] {
        return searchController.isActive ? filteredCategories : categories
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshData()
    }
    
    @IBAction func didTapSignout(_ sender: UIBarButtonItem) {
        transitionToLoggedOut()
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
    
    private func transitionToLoggedOut() {
        if let window = UIApplication.shared.keyWindow {
            do {
                try Auth.auth().signOut()
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
                UIView.transition(with: window, duration: 0.3, options: .transitionFlipFromLeft, animations: {
                    window.rootViewController = vc
                }, completion: { completed in
                    // maybe do something here
                })
            } catch {
                print(error)
            }
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
        navigationItem.searchController = searchController


        let refreshControl = UIRefreshControl()
        tableview.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableview.tableFooterView = UIView()
    }
    
    func filterResults(searchText: String?) {
        guard let searchText = searchText,
            !searchText.isEmpty else { self.filteredEntries = self.entries; return }
        let searchEntries = searchText.split(separator: " ")
        self.filteredEntries = self.entries.filter { entry in
            return searchEntries.map { searchEntry in
                entry.value.lowercased().contains(searchEntry.lowercased()) ||
                    entry.description.lowercased().contains(searchEntry.lowercased())
                
                }
                .reduce(true, { $0 && $1 })
        }
    }
}

extension EntryListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterResults(searchText: searchController.searchBar.text)
    }
}

extension EntryListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableData[section].category ?? "[No Category]"
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
