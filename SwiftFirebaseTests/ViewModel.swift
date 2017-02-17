//
//  ViewModel.swift
//  SwiftFirebaseTests
//
//  Created by Andy Chou on 2/16/17.
//  Copyright © 2017 GiantSquidBaby. All rights reserved.
//

import RxSwift
import GoogleSignIn

enum AuthEvent {
    case googleSignIn(signIn: GIDSignIn?, user: GIDGoogleUser?, error: Error?)
    case googleSignOut(signIn: GIDSignIn?, user: GIDGoogleUser?, error: Error?)
}

extension AuthEvent: CustomStringConvertible {
    var description: String {
        switch self {
        case let .googleSignIn(signIn, user, error):
            let name = user?.profile.name
            return "Google signin \(name)"
        case let .googleSignOut(signIn, user, error):
            let name = user?.profile.name
            return "Google signout \(name)"
        }
    }
}

struct ViewModelInputs {
    var authEvents: Observable<AuthEvent>
}

struct ViewModelOutputs {
    var message: Observable<String>
    var status: Observable<String>
}

typealias ViewModelType = (ViewModelInputs) -> ViewModelOutputs

func ViewModel() -> ViewModelType {
    return { inputs in
        let message = Observable.just("Sign in to a test Google account to enable the testsuite.")
        let status = inputs.authEvents.map { String(describing: $0) }
        return ViewModelOutputs(message: message, status: status)
    }
}
