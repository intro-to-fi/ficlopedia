//
//  Created on 5/16/19.
//  Copyright © 2019 Intro To Fi. All rights reserved.
//

import FirebaseUI
import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
  @IBAction func didTapLogin(_ sender: UIButton) {
    let authUI = FUIAuth.defaultAuthUI()
    authUI?.delegate = self
    authUI?.providers = [FUIGoogleAuth()]
    if let authViewController = authUI?.authViewController() {
      present(authViewController, animated: true, completion: nil)
    }
  }
}

extension ViewController: FUIAuthDelegate {
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        
    }
    func authUI(_ authUI: FUIAuth, didFinish operation: FUIAccountSettingsOperationType, error: Error?) {
        
    }
}
