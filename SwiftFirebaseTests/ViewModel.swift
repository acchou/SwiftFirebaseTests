//
//  ViewModel.swift
//  SwiftFirebaseTests
//
//  Created by Andy Chou on 2/16/17.
//  Copyright © 2017 GiantSquidBaby. All rights reserved.
//

import RxSwift
import GoogleSignIn
import FirebaseAuth

enum AuthEvent {
    case googleSignIn(signIn: GIDSignIn?, user: GIDGoogleUser?, error: Error?)
    case googleSignOut(signIn: GIDSignIn?, user: GIDGoogleUser?, error: Error?)
    case firebaseSignIn(user: FIRUser?, error: Error?)
}

extension AuthEvent: CustomStringConvertible {
    var description: String {
        switch self {
        case let .googleSignIn(_, user, error):
            if let error = error { return error.localizedDescription }
            let name = user?.profile.name
            return "Google signin \(name)"
        case let .googleSignOut(_, user, error):
            if let error = error { return error.localizedDescription }
            let name = user?.profile.name
            return "Google signout \(name)"
        case let .firebaseSignIn(user, error):
            if let error = error { return error.localizedDescription }
            let name = user?.displayName
            return "Firebase signin \(name)"
        }
    }

    var isFirebaseSignIn: Bool {
        if case .firebaseSignIn(_, _) = self { return true } else { return false }
    }
}

protocol ViewModelType {
    associatedtype Input
    associatedtype Output

    func transform(_ input: Input) -> Output
}

class ViewModel: ViewModelType {
    struct Input {
        var authEvents: Observable<AuthEvent>
    }

    struct Output {
        var message: Observable<String>
        var status: Observable<String>
    }

    func transform(_ input: Input) -> Output {
        let message = Observable.just("Sign in to a test Google account to enable the testsuite.")
        let eventStatus = input.authEvents.map { String(describing: $0) }

        let gmailStatus = input.authEvents
            .filter { $0.isFirebaseSignIn }
            .flatMapLatest { _ in
                global.rxGmail.getLabels()
            }
            .map {
                $0.map { "\($0.name):\($0.messagesUnread)/\($0.messagesTotal)" }.joined(separator: " ")
            }

        let status = Observable.of(eventStatus, gmailStatus)
            .merge()
            .shareReplay(1)
            
        return Output(message: message, status: status)
    }
}
