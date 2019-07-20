//
// Created 5/16/19.
// Copyright © 2019 Intro To Fi. All rights reserved.
//

import FirebaseUI
import FirebaseAuth
import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Auth.auth().currentUser != nil {
            transitionToLoggedIn()
        }
    }
    
    @IBAction func didTapLogin(_ sender: UIButton) {
        let authUI = FUIAuth.defaultAuthUI()
        authUI?.delegate = self
        authUI?.providers = [FUIGoogleAuth()]
        if let authViewController = authUI?.authViewController() {
            present(authViewController, animated: true, completion: nil)
        }
    }
    
    private func transitionToLoggedIn() {
        if let window = UIApplication.shared.keyWindow {
            Store.fetchCategories()
            let vc = UIStoryboard(name: "EntryList", bundle: nil).instantiateInitialViewController()
            UIView.transition(with: window, duration: 0.3, options: .transitionFlipFromLeft, animations: {
                window.rootViewController = vc
            }, completion: { completed in
                // maybe do something here
            })
        }
    }
}

extension ViewController: FUIAuthDelegate {
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        transitionToLoggedIn()
    }
    func authUI(_ authUI: FUIAuth, didFinish operation: FUIAccountSettingsOperationType, error: Error?) {
        
    }
}
