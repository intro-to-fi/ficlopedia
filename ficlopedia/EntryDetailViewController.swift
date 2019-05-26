//
// Created 5/18/19
// Copyright © 2019 Intro To FI. All rights reserved.
//

import FirebaseFirestore
import UIKit

class EntryDetailViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var valueTextField: UITextField!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(didTapSave))
    
    private let db = Firestore.firestore()
    
    var entry: Entry?
    private var hasEdits: Bool = false {
        didSet {
            if hasEdits {
                navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapCancel))
                if !(navigationItem.rightBarButtonItems?.contains(saveButton) ?? false) {
                    navigationItem.rightBarButtonItems?.append(saveButton)
                }
            } else {
                navigationItem.leftBarButtonItem = nil
                navigationItem.rightBarButtonItems?.removeAll(where: { $0 === saveButton })
            }
        }
    }
    
    @objc
    private func didTapCancel() {
        load(from: entry)
        hasEdits = false
        view.endEditing(false)
    }
    
    @objc
    func didTapSave() {
        guard let entry = entry else { createNewEntry(); return }
        save(entry)
    }
    
    @IBAction func didtapTrash(_ sender: UIBarButtonItem) {
        guard let entry = entry else { return }
        delete(entry)
    }
    
    private func save(_ entry: Entry) {
        guard let id = entry.id, let value = valueTextField.text, let description = descriptionTextView.text else { return }
        db.document("entries/\(id)").updateData(["value": value, "description": description]) { error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func createNewEntry() {
        guard let value = valueTextField.text, let description = descriptionTextView.text else { return }
        let entry = Entry(id: nil, value: value, description: description, status: .draft)
        db.collection("entries").addDocument(data: entry.data) { error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func delete(_ entry: Entry) {
        guard let id = entry.id else { return }
        let alertController = UIAlertController(title: "Delete Entry", message: "Are you sure?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .destructive) { _ in
            self.db.document("entries/\(id)").delete { error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                self.navigationController?.popViewController(animated: true)
            }
        }
        alertController.addAction(yesAction)
        alertController.preferredAction = yesAction
        alertController.addAction(.init(title: "Cancel", style: .default))
        present(alertController, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        load(from: entry)
        valueLabel.text = "Value"
        valueTextField.delegate = self
        descriptionLabel.text = "Description"
        descriptionTextView.delegate = self
        descriptionTextView.layer.borderWidth = 0.5
        descriptionTextView.layer.borderColor = UIColor(white: 210.0/255.0, alpha: 1).cgColor
        descriptionTextView.layer.cornerRadius = 5
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func configure(with entry: Entry) {
        self.entry = entry
    }
    
    private func load(from entry: Entry?) {
        valueTextField.text = entry?.value
        descriptionTextView.text = entry?.description
    }
    
    @objc
    private func keyboardDidShow(notification: NSNotification) {
        guard let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        let keyboardEnd = value.cgRectValue
        scrollView.contentInset = .init(top: 0, left: 0, bottom: keyboardEnd.height, right: 0)
    }
    
    @objc
    private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .init(top: 0, left: 0, bottom: 0, right: 0)
    }
}

extension EntryDetailViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        hasEdits = true
        return true
    }
}

extension EntryDetailViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        hasEdits = true
        return true
    }
}
