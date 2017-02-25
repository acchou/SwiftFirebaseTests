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

class ViewController: UIViewController, GIDSignInUIDelegate {

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
        let input = ViewModel.Input(
            authEvents: (UIApplication.shared.delegate as! AppDelegate).authEvents.debug("Auth event")
        )
        let output = viewModel.transform(input)

        output.message
            .bindTo(messageLabel.rx.text)
            .addDisposableTo(disposeBag)

        output.status
            .bindTo(statusLabel.rx.text)
            .addDisposableTo(disposeBag)
    }
}
