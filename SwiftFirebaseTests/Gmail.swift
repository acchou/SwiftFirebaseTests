//
//  Gmail.swift
//  SwiftFirebaseTests
//
//  Created by Andy Chou on 2/15/17.
//  Copyright © 2017 GiantSquidBaby. All rights reserved.
//

import GoogleAPIClientForREST
import RxSwift

let gmailServiceScopes = [kGTLRAuthScopeGmailReadonly]
let gmailService = GTLRGmailService()

let info = Bundle.main.infoDictionary!
let GoogeClientID = info["GoogleClientID"] as! String

func getGmailLabels(forUserId userId: String = "me") -> Observable<[GTLRGmail_Label]> {
    return Observable.create { observer in
        let query = GTLRGmailQuery_UsersLabelsList.query(withUserId: userId)
        let serviceTicket = gmailService.executeQuery(query) { (ticket: GTLRServiceTicket, object: Any?, error: Error?) in
            if let error = error {
                observer.onError(error)
            } else {
                let response = object as? GTLRGmail_ListLabelsResponse
                observer.onNext(response?.labels ?? [])
                observer.onCompleted()
            }
        }
        return Disposables.create {
            serviceTicket.cancel()
        }
    }
}
