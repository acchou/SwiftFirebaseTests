//
//  ViewController.swift
//  SwiftFirebaseTests
//
//  Created by Andy Chou on 2/10/17.
//  Copyright © 2017 GiantSquidBaby. All rights reserved.
//

import UIKit
import GoogleSignIn
import RxSwift
import RxCocoa

class ViewController: UIViewController {

    @IBOutlet weak var googleSignInButton: GIDSignInButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signIn()

        googleSignInButton.style = .wide
        let viewModel = ViewModel()
        let inputs = ViewModelInputs(
            authEvents: (UIApplication.shared.delegate as! AppDelegate).authEvents.debug("Auth event")
        )
        let outputs = viewModel(inputs)

        outputs.message
            .bindTo(messageLabel.rx.text)
            .addDisposableTo(disposeBag)

        outputs.status
            .bindTo(statusLabel.rx.text)
            .addDisposableTo(disposeBag)
    }
}

extension ViewController: GIDSignInUIDelegate {

    // The sign-in flow has finished selecting how to proceed, and the UI should no longer display
    // a spinner or other "please wait" element.
    func sign(inWillDispatch signIn: GIDSignIn!, error: Error!) {
        print("sign in will dispatch: \(signIn.currentUser.profile.name), error: \(error)")
    }

    // If implemented, this method will be invoked when sign in needs to display a view controller.
    // The view controller should be displayed modally (via UIViewController's |presentViewController|
    // method, and not pushed unto a navigation controller's stack.
    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        self.present(viewController, animated: true)
    }

    // If implemented, this method will be invoked when sign in needs to dismiss a view controller.
    // Typically, this should be implemented by calling |dismissViewController| on the passed
    // view controller.
    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        viewController.dismiss(animated: true)
    }
}
