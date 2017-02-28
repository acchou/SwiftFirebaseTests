//
//  RxGmail.swift
//  SwiftFirebaseTests
//
//  Created by Andy Chou on 2/27/17.
//  Copyright © 2017 GiantSquidBaby. All rights reserved.
//

import GoogleAPIClientForREST
import RxSwift
import RxSwiftExt

// Protocols used to retroactively model all paged query types in the Gmail API.
protocol PagedQuery: NSCopying, RxGmail.Query {
    var pageToken: String? { get set }
}

protocol PagedResult {
    var nextPageToken: String? { get }
}

extension RxGmail.MessageResponse: PagedResult { }
extension RxGmail.MessageQuery: PagedQuery { }

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
    typealias Query = GTLRQueryProtocol
    typealias ServiceTicket = GTLRServiceTicket
    typealias ProfileQuery = GTLRGmailQuery_UsersGetProfile
    typealias Profile = GTLRGmail_Profile
    typealias WatchRequest = GTLRGmail_WatchRequest
    typealias WatchResponse = GTLRGmail_WatchResponse
    typealias WatchQuery = GTLRGmailQuery_UsersWatch
    typealias StopQuery = GTLRGmailQuery_UsersStop
    typealias DraftsCreateQuery = GTLRGmailQuery_UsersDraftsCreate
    typealias Draft = GTLRGmail_Draft
    typealias UploadParameters = GTLRUploadParameters
    typealias DraftsDeleteQuery = GTLRGmailQuery_UsersDraftsDelete
    typealias DraftsGetQuery = GTLRGmailQuery_UsersDraftsGet
    typealias DraftsListQuery = GTLRGmailQuery_UsersDraftsList
    typealias DraftsListResponse = GTLRGmail_ListDraftsResponse
    typealias GmailCollection = GTLRCollectionObject

    fileprivate func createRequest(observer: AnyObserver<Any?>, query: Query) -> ServiceTicket {
        let serviceTicket = service.executeQuery(query) { ticket, object, error in
            if let error = error {
                observer.onError(error)
            } else {
                observer.onNext(object)
                observer.onCompleted()
            }
        }
        return serviceTicket
    }

    // Execute a query.
    func execute(query: Query) -> Observable<Any?> {
        return Observable.create { [weak self] observer in
            let serviceTicket = self?.createRequest(observer: observer, query: query)
            return Disposables.create {
                serviceTicket?.cancel()
            }
        }
    }

    func getLabels(forUserId userId: String = "me") -> Observable<[Label]> {
        let query = LabelQuery.query(withUserId: userId)
        return self.getLabels(query: query)
    }

    func getLabels(query: LabelQuery) -> Observable<[Label]> {
        return execute(query: query)
            .map { $0! as! LabelResponse }
            .map { $0.labels! }
    }

    // Each event returns a page of messages.
    // TODO: Generalize to arbitrary query. Need to copy queries each time they are executed.
    func getMessages(forUserId userId: String = "me") -> Observable<MessageResponse> {
        let query = MessageQuery.query(withUserId: userId)
        return getMessages(query: query)
    }

    // TODO: Refactor to use extensions on the collection and query, then constraint the parameters to these protocols.
    func loadPages<C: PagedResult, Q: PagedQuery> (query: Q) -> Observable<C> {
        func getRemainingPages(after previousPage: C?) -> Observable<C> {
            let nextPageToken = previousPage?.nextPageToken
            if previousPage != nil && nextPageToken == nil {
                return .empty()
            }
            let query = query.copy() as! Q
            query.pageToken = nextPageToken
            return execute(query: query)
                .map { $0! as! C }
                .flatMap { page -> Observable<C> in
                    let first = Observable.just(page)
                    let rest = getRemainingPages(after: page)
                    return first.concat(rest)
                }
        }
        return getRemainingPages(after: nil)
    }

    // TODO: Replace getMessages with this generic implementation.
    func getMessages2(query: MessageQuery) -> Observable<MessageResponse> {
        return loadPages(query: query)
    }

    // TODO: Remove.
    func getMessages(query: MessageQuery) -> Observable<MessageResponse> {
        func getRemainingMessages(after previousPage: MessageResponse?) -> Observable<MessageResponse> {
            let nextPageToken = previousPage?.nextPageToken
            if previousPage != nil && nextPageToken == nil {
                return .empty()
            }
            let query = query.copy() as! MessageQuery
            query.pageToken = nextPageToken
            return execute(query: query)
                .map { $0! as! MessageResponse }
                .flatMap { page -> Observable<MessageResponse> in
                    let first = Observable.just(page)
                    let rest = getRemainingMessages(after: page)
                    return first.concat(rest)
                }
        }
        return getRemainingMessages(after: nil)
    }

    func getProfile(forUserId userId: String = "me") -> Observable<Profile> {
        let query = ProfileQuery.query(withUserId: userId)
        return execute(query: query)
            .map { $0! as! Profile }
    }

    func watch(request: WatchRequest, forUserId userId: String = "me") -> Observable<WatchResponse> {
        let query = WatchQuery.query(withObject: request, userId: userId)
        return execute(query: query)
            .map { $0! as! WatchResponse }
    }

    func stop(forUserId userId: String = "me") -> Observable<Void> {
        let query = StopQuery.query(withUserId: userId)
        return execute(query: query)
            .map { _ in () }
    }

    // MARK: - Drafts

    func createDraft(draft: Draft, uploadParameters: UploadParameters?,forUserId userId: String = "me") -> Observable<Draft> {
        let query = DraftsCreateQuery.query(withObject: draft, userId: userId, uploadParameters: uploadParameters)
        return execute(query: query)
            .map { $0! as! Draft }
    }

    func deleteDraft(draftID: String, forUserId userId: String = "me") -> Observable<Void> {
        let query = DraftsDeleteQuery.query(withUserId: userId, identifier: draftID)
        return execute(query: query)
            .map { _ in () }
    }

    func getDraft(draftID: String, format: String? = nil, forUserId userId: String = "me") -> Observable<Draft> {
        let query = DraftsGetQuery.query(withUserId: userId, identifier: draftID)
        query.format = format
        return execute(query: query)
            .map { $0! as! Draft }
    }

    // TODO: These are paged APIs.

//    func listDrafts(forUserId userId: String = "me") {
//        let query = DraftsListQuery.query(withUserId: userId)
//        return listDrafts(query: query)
//    }
//
//    func listDrafts(query: DraftsListQuery) {
//        return execute(query: query)
//            .map { $0! as! DraftsListResponse }
//    }
}
