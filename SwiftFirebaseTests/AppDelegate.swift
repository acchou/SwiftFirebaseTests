//
//  AppDelegate.swift
//  SwiftFirebaseTests
//
//  Created by Andy Chou on 2/10/17.
//  Copyright © 2017 GiantSquidBaby. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import RxSwift
import RxCocoa
import GTMSessionFetcher

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    public var authEvents = PublishSubject<AuthEvent>()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FIRApp.configure()
        let signIn = GIDSignIn.sharedInstance()!
        signIn.clientID = FIRApp.defaultApp()?.options.clientID
        signIn.delegate = self

        // Request access to Gmail API.
        let scopes: NSArray = signIn.scopes as NSArray? ?? []
        signIn.scopes = scopes.addingObjects(from: global.rxGmail.serviceScopes)

        // Log all Google API requests. Location of log file is printed to console.
        GTMSessionFetcher.setLoggingEnabled(true)
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        let sourceApplication = options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String?
        if GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: [:]) {
            return true
        }
        return false
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

extension AppDelegate: GIDSignInDelegate {
    // TODO:
    // Continue following instructions at: https://firebase.google.com/docs/auth/ios/google-signin
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        let event = AuthEvent.googleSignIn(signIn: signIn, user: user, error: error)
        print("signin: \(event)")
        authEvents.onNext(event)
        if let error = error {
            print("Error signing in: \(error.localizedDescription)")
            return
        }

        guard let authentication = user.authentication else { return }
        let credential = FIRGoogleAuthProvider.credential(
            withIDToken: authentication.idToken,
            accessToken: authentication.accessToken
        )

        auth.signIn(with: credential) { (user, error) in
            self.authEvents.onNext(.firebaseSignIn(user: user, error: error))
            if let error = error {
                print("Error with firebase signin: \(error)")
            }
        }

        global.gmailService.authorizer = user.authentication.fetcherAuthorizer()
        assert(global.gmailService.authorizer?.canAuthorize == true)
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        let event = AuthEvent.googleSignOut(signIn: signIn, user: user, error: error)
        print("signout: \(event)")
        authEvents.onNext(event)
        if let error = error {
            print("Error disconnecting user: \(error.localizedDescription)")
            return
        }
    }
}
