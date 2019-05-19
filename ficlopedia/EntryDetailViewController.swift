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
    
    private let db = Firestore.firestore()
    
    var entry: Entry?
    private var hasEdits: Bool = false {
        didSet {
            if hasEdits {
                navigationItem.leftBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .cancel, target: self, action: #selector(didTapCancel))
                navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .save, target: self, action: #selector(didTapSave))
            } else {
                navigationItem.leftBarButtonItem = nil
                navigationItem.rightBarButtonItem = nil
            }
        }
    }
    
    @objc
    private func didTapCancel() {
        if let entry = entry {
            load(from: entry)
        }
        hasEdits = false
    }
    
    @objc
    func didTapSave() {
        guard let entry = entry else { return }
        db.document("entries/\(entry.id)").updateData(["value": valueTextField.text, "description": descriptionTextView.text]) { error in
            guard error == nil else {
                print(error)
                return
            }
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let entry = entry {
            load(from: entry)
        }
        valueTextField.delegate = self
        descriptionTextView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func configure(with entry: Entry) {
        self.entry = entry
    }
    
    private func load(from entry: Entry) {
        valueLabel.text = "Value"
        valueTextField.text = entry.value
        descriptionLabel.text = "Description"
        descriptionTextView.text = entry.description
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
