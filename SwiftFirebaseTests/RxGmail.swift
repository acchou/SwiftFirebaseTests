//
//  RxGmail.swift
//  SwiftFirebaseTests
//
//  Created by Andy Chou on 2/27/17.
//  Copyright © 2017 GiantSquidBaby. All rights reserved.
//

import GoogleAPIClientForREST
import RxSwift

class RxGmail {
    let GoogleClientID: String

    let serviceScopes = [kGTLRAuthScopeGmailReadonly]
    let service: GTLRGmailService

    init(gmailService: GTLRGmailService) {
        self.service = gmailService
        let info = Bundle.main.infoDictionary!
        self.GoogleClientID = info["GoogleClientID"] as! String
    }

    typealias GmailService = GTLRGmailService
    typealias Label = GTLRGmail_Label
    typealias Message = GTLRGmail_Message
    typealias LabelQuery = GTLRGmailQuery_UsersLabelsList
    typealias LabelResponse = GTLRGmail_ListLabelsResponse
    typealias MessageQuery = GTLRGmailQuery_UsersMessagesList
    typealias MessageResponse = GTLRGmail_ListMessagesResponse

    func getLabels() -> Observable<[GTLRGmail_Label]> {
        return getLabels(forUserId: "me")
    }

    func getLabels(forUserId userId: String) -> Observable<[Label]> {
        return Observable.create { [weak self] observer in
            let query = LabelQuery.query(withUserId: userId)
            let serviceTicket = self?.service.executeQuery(query) { ticket, object, error in
                if let error = error {
                    observer.onError(error)
                } else {
                    let response = object as? LabelResponse
                    observer.onNext(response?.labels ?? [])
                    observer.onCompleted()
                }
            }
            return Disposables.create {
                serviceTicket?.cancel()
            }
        }
    }

    func getMessages() -> Observable<[GTLRGmail_Message]?> {
        return getMessages(forUserId: "me")
    }

    // Each event returns a page of messages.
    func getMessages(forUserId userId: String = "me") -> Observable<[Message]?> {
        func getPage(nextPageToken: String?) -> Observable<MessageResponse> {
            let response: Observable<MessageResponse> = Observable.create { [weak self] observer in
                let query = MessageQuery.query(withUserId: userId)
                query.pageToken = nextPageToken
                let serviceTicket = self?.service.executeQuery(query) { ticket, object, error -> Void in
                    if let error = error {
                        observer.onError(error)
                    } else {
                        let response = object as! MessageResponse
                        observer.onNext(response)
                        observer.onCompleted()
                    }
                }
                return Disposables.create {
                    serviceTicket?.cancel()
                }
            }
            return response.flatMap { (response: MessageResponse) -> Observable<MessageResponse> in
                if let nextPageToken = response.nextPageToken {
                    return Observable.just(response).concat(getPage(nextPageToken: nextPageToken))
                } else {
                    return Observable.just(response)
                }
            }
        }
        return getPage(nextPageToken: nil).map { $0.messages }
    }
}
