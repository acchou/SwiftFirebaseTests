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

protocol PagedQuery {
    var pageToken: String? { get set }
}

protocol PagedResponse {
    var nextPageToken: String? { get }
}

extension RxGmail.MessageListQuery: PagedQuery { }
extension RxGmail.MessageListResponse: PagedResponse { }

extension RxGmail.DraftsListQuery: PagedQuery { }
extension RxGmail.DraftsListResponse: PagedResponse { }

extension RxGmail.HistoryQuery: PagedQuery { }
extension RxGmail.HistoryResponse: PagedResponse { }

extension RxGmail.ThreadListQuery: PagedQuery { }
extension RxGmail.ThreadListResponse: PagedResponse { }

class RxGmail {
    let GoogleClientID: String

    let serviceScopes = [kGTLRAuthScopeGmailReadonly]
    let service: GTLRGmailService

    init(gmailService: GTLRGmailService) {
        self.service = gmailService
        let info = Bundle.main.infoDictionary!
        self.GoogleClientID = info["GoogleClientID"] as! String
    }

    // MARK: - Types
    typealias GmailService = GTLRGmailService
    typealias Query = GTLRQueryProtocol
    typealias Response = GTLRObject
    typealias Label = GTLRGmail_Label
    typealias Message = GTLRGmail_Message
    typealias LabelsListQuery = GTLRGmailQuery_UsersLabelsList
    typealias LabelsListResponse = GTLRGmail_ListLabelsResponse
    typealias LabelsCreateQuery = GTLRGmailQuery_UsersLabelsCreate
    typealias LabelsDeleteQuery = GTLRGmailQuery_UsersLabelsDelete
    typealias LabelsGetQuery = GTLRGmailQuery_UsersLabelsGet
    typealias LabelsPatchQuery = GTLRGmailQuery_UsersLabelsPatch
    typealias LabelsUpdateQuery = GTLRGmailQuery_UsersLabelsUpdate
    typealias MessageListQuery = GTLRGmailQuery_UsersMessagesList
    typealias MessageListResponse = GTLRGmail_ListMessagesResponse
    typealias MessageBatchDeleteQuery = GTLRGmailQuery_UsersMessagesBatchDelete
    typealias MessageBatchDeleteRequest = GTLRGmail_BatchDeleteMessagesRequest
    typealias MessageBatchModifyQuery = GTLRGmailQuery_UsersMessagesBatchModify
    typealias MessageBatchModifyRequest = GTLRGmail_BatchModifyMessagesRequest
    typealias MessageDeleteQuery = GTLRGmailQuery_UsersMessagesDelete
    typealias MessageGetQuery = GTLRGmailQuery_UsersMessagesGet
    typealias MessageImportQuery = GTLRGmailQuery_UsersMessagesImport
    typealias MessageInsertQuery = GTLRGmailQuery_UsersMessagesInsert
    typealias MessageModifyQuery = GTLRGmailQuery_UsersMessagesModify
    typealias MessageModifyRequest = GTLRGmail_ModifyMessageRequest
    typealias MessageSendQuery = GTLRGmailQuery_UsersMessagesSend
    typealias MessageTrashQuery = GTLRGmailQuery_UsersMessagesTrash
    typealias MessageUntrashQuery = GTLRGmailQuery_UsersMessagesUntrash
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
    typealias DraftsSendQuery = GTLRGmailQuery_UsersDraftsSend
    typealias DraftsUpdateQuery = GTLRGmailQuery_UsersDraftsUpdate
    typealias HistoryQuery = GTLRGmailQuery_UsersHistoryList
    typealias HistoryResponse = GTLRGmail_ListHistoryResponse

    typealias ThreadListQuery = GTLRGmailQuery_UsersThreadsList
    typealias ThreadListResponse = GTLRGmail_ListThreadsResponse

    // MARK: - Generic request helper functions
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

    /**
     Execute a query.
 
     - Parameter query: the query to execute.
     - Returns: An observable with the fetched response. This variant of `execute` returns an optional, which will be `nil` only for queries that explicitly return `nil` to signal success. Most responses will return an instance of `GTLRObject`.

     */
    func execute<R: Response>(query: Query) -> Observable<R?> {
        return Observable<Any?>.create { [weak self] observer in
            let serviceTicket = self?.createRequest(observer: observer, query: query)
            return Disposables.create {
                serviceTicket?.cancel()
            }
        }
        .map { $0 as! R? }
    }

    /**
     Execute a query.
     
     - Parameter query: the query to execute.
     - Returns: an instance of GTLRObject fetched by the query upon success.
     */
    func execute<R: Response>(query: Query) -> Observable<R> {
        return execute(query: query).map { $0! }
    }

    func execute(query: Query) -> Observable<Void> {
        let response: Observable<Response?> = execute(query: query)
        return response.map { _ in () }
    }

    /**
     Execute a query returning a paged response.

     - Parameter query: the query to execute, the result of the query should
       be a paged response.

     - Returns: an observable that sends one event per page.
    */
    func executePaged<Q, R>(query: Q) -> Observable<R>
        where Q: Query, Q: PagedQuery, R: Response, R: PagedResponse {
            func getRemainingPages(after previousPage: R?) -> Observable<R> {
                let nextPageToken = previousPage?.nextPageToken
                if previousPage != nil && nextPageToken == nil {
                    return .empty()
                }
                var query = query.copy() as! Q
                query.pageToken = nextPageToken
                let response: Observable<R> = execute(query: query)
                return response.flatMap { page -> Observable<R> in
                    return Observable.just(page).concat(getRemainingPages(after: page))
                }
            }
            return getRemainingPages(after: nil)
    }

    // MARK: - Users

    func getProfile(forUserId userId: String = "me") -> Observable<Profile> {
        let query = ProfileQuery.query(withUserId: userId)
        return getProfile(query: query)
    }

    func getProfile(query: ProfileQuery) -> Observable<Profile> {
        return execute(query: query)
    }

    func watchRequest(request: WatchRequest, forUserId userId: String = "me") -> Observable<WatchResponse> {
        let query = WatchQuery.query(withObject: request, userId: userId)
        return watchRequest(query: query)
    }

    func watchRequest(query: WatchQuery) -> Observable<WatchResponse> {
        return execute(query: query)
    }

    func stopNotifications(forUserId userId: String = "me") -> Observable<Void> {
        let query = StopQuery.query(withUserId: userId)
        return stopNotifications(query: query)
    }

    func stopNotifications(query: StopQuery) -> Observable<Void> {
        return execute(query: query)
    }

    // MARK: - Drafts

    func createDraft(draft: Draft, uploadParameters: UploadParameters? = nil, forUserId userId: String = "me") -> Observable<Draft> {
        let query = DraftsCreateQuery.query(withObject: draft, userId: userId, uploadParameters: uploadParameters)
        return createDraft(query: query)
    }

    func createDraft(query: DraftsCreateQuery) -> Observable<Draft> {
        return execute(query: query)
    }

    func deleteDraft(draftID: String, forUserId userId: String = "me") -> Observable<Void> {
        let query = DraftsDeleteQuery.query(withUserId: userId, identifier: draftID)
        return deleteDraft(query: query)
    }

    func deleteDraft(query: DraftsDeleteQuery) -> Observable<Void> {
        return execute(query: query)
    }

    func getDraft(draftID: String, format: String? = nil, forUserId userId: String = "me") -> Observable<Draft> {
        let query = DraftsGetQuery.query(withUserId: userId, identifier: draftID)
        query.format = format
        return getDraft(query: query)
    }

    func getDraft(query: DraftsGetQuery) -> Observable<Draft> {
        return execute(query: query)
    }

    func listDrafts(forUserId userId: String = "me") -> Observable<DraftsListResponse> {
        let query = DraftsListQuery.query(withUserId: userId)
        return listDrafts(query: query)
    }

    func listDrafts(query: DraftsListQuery) -> Observable<DraftsListResponse> {
        return executePaged(query: query)
    }

    func sendDraft(draft: Draft, uploadParameters: UploadParameters? = nil, forUserId userId: String = "me") -> Observable<Message> {
        let query = DraftsSendQuery.query(withObject: draft, userId: userId, uploadParameters: uploadParameters)
        return sendDraft(query: query)
    }

    func sendDraft(query: DraftsSendQuery) -> Observable<Message> {
        return execute(query: query)
    }

    func updateDraft(draftID: String, draft: Draft, uploadParameters: UploadParameters? = nil, forUserId userId: String = "me") -> Observable<Draft> {
        let query = DraftsUpdateQuery.query(withObject: draft, userId: userId, identifier: draftID, uploadParameters: uploadParameters)
        return updateDraft(query: query)
    }

    func updateDraft(query: DraftsUpdateQuery) -> Observable<Draft> {
        return execute(query: query)
    }

    // MARK: - History

    func history(startHistoryId: UInt64, forUserId userId: String = "me") -> Observable<HistoryResponse> {
        let query = HistoryQuery.query(withUserId: userId)
        query.startHistoryId = startHistoryId
        return history(query: query)
    }

    func history(query: HistoryQuery) -> Observable<HistoryResponse> {
        return executePaged(query: query)
    }

    // MARK: - Labels

    func listLabels(forUserId userId: String = "me") -> Observable<LabelsListResponse> {
        let query = LabelsListQuery.query(withUserId: userId)
        return self.listLabels(query: query)
    }

    func listLabels(query: LabelsListQuery) -> Observable<LabelsListResponse> {
        return execute(query: query)
    }

    func createLabel(label: Label, forUserId userId: String = "me") -> Observable<Label> {
        let query = LabelsCreateQuery.query(withObject: label, userId: userId)
        return createLabel(query: query)
    }

    func createLabel(query: LabelsCreateQuery) -> Observable<Label> {
        return execute(query: query)
    }

    func deleteLabel(labelId: String, forUserId userId: String = "me") -> Observable<Void> {
        let query = LabelsDeleteQuery.query(withUserId: userId, identifier: labelId)
        return deleteLabel(query: query)
    }

    func deleteLabel(query: LabelsDeleteQuery) -> Observable<Void> {
        return execute(query: query)
    }

    func getLabel(labelId: String, forUserId userId: String = "me") -> Observable<Label> {
        let query = LabelsGetQuery.query(withUserId: userId, identifier: labelId)
        return getLabel(query: query)
    }

    func getLabel(query: LabelsGetQuery) -> Observable<Label> {
        return execute(query: query)
    }

    func patchLabel(labelId: String, updatedLabel: Label, forUserId userId: String = "me") -> Observable<Label> {
        let query = LabelsPatchQuery.query(withObject: updatedLabel, userId: userId, identifier: userId)
        return patchLabel(query: query)
    }

    func patchLabel(query: LabelsPatchQuery) -> Observable<Label> {
        return execute(query: query)
    }

    func updateLabel(labelId: String, updatedLabel: Label, forUserId userId: String = "me") -> Observable<Label> {
        let query = LabelsUpdateQuery.query(withObject: updatedLabel, userId: userId, identifier: labelId)
        return updateLabel(query: query)
    }

    func updateLabel(query: LabelsUpdateQuery) -> Observable<Label> {
        return execute(query: query)
    }

    // MARK: - Messages

    // Each event returns a page of messages.
    func listMessages(forUserId userId: String = "me") -> Observable<MessageListResponse> {
        let query = MessageListQuery.query(withUserId: userId)
        return listMessages(query: query)
    }

    func listMessages(query: MessageListQuery) -> Observable<MessageListResponse> {
        return executePaged(query: query)
    }

    func batchDeleteMessages(request: MessageBatchDeleteRequest, forUserId userId: String = "me") -> Observable<Void> {
        let query = MessageBatchDeleteQuery.query(withObject: request, userId: userId)
        return batchDeleteMessages(query: query)
    }

    func batchDeleteMessages(query: MessageBatchDeleteQuery) -> Observable<Void> {
        return execute(query: query)
    }

    func batchModifyMessages(request: MessageBatchModifyRequest, forUserId userId: String = "me") -> Observable<Void> {
        let query = MessageBatchModifyQuery.query(withObject: request, userId: userId)
        return batchModifyMessages(query: query)
    }

    func batchModifyMessages(query: MessageBatchModifyQuery) -> Observable<Void> {
        return execute(query: query)
    }

    func deleteMessage(messageId: String, forUserId userId: String = "me") -> Observable<Void> {
        let query = MessageDeleteQuery.query(withUserId: userId, identifier: messageId)
        return deleteMessage(query: query)
    }

    func deleteMessage(query: MessageDeleteQuery) -> Observable<Void> {
        return execute(query: query)
    }

    func getMessage(messageId: String, forUserId userId: String = "me") -> Observable<Message> {
        let query = MessageGetQuery.query(withUserId: userId, identifier: messageId)
        return getMessage(query: query)
    }

    func getMessage(query: MessageGetQuery) -> Observable<Message> {
        return execute(query: query)
    }

    func importMessage(message: Message, uploadParameters: UploadParameters? = nil, forUserId userId: String = "me") -> Observable<Message> {
        let query = MessageImportQuery.query(withObject: message, userId: userId, uploadParameters: uploadParameters)
        return importMessage(query: query)
    }

    func importMessage(query: MessageImportQuery) -> Observable<Message> {
        return execute(query: query)
    }

    func insertMessage(message: Message, uploadParameters: UploadParameters? = nil, forUserId userId: String = "me") -> Observable<Message> {
        let query = MessageInsertQuery.query(withObject: message, userId: userId, uploadParameters: uploadParameters)
        return insertMessage(query: query)
    }

    func insertMessage(query: MessageInsertQuery) -> Observable<Message> {
        return execute(query: query)
    }

    func modifyMessage(messageId: String, request: MessageModifyRequest, forUserId userId: String = "me") -> Observable<Message> {
        let query = MessageModifyQuery.query(withObject: request, userId: userId, identifier: messageId)
        return modifyMessage(query: query)
    }

    func modifyMessage(query: MessageModifyQuery) -> Observable<Message> {
        return execute(query: query)
    }

    func sendMessage(message: Message, uploadParameters: UploadParameters? = nil, forUserId userId: String = "me") -> Observable<Message> {
        let query = MessageSendQuery.query(withObject: message, userId: userId, uploadParameters: uploadParameters)
        return sendMessage(query: query)
    }

    func sendMessage(query: MessageSendQuery) -> Observable<Message> {
        return execute(query: query)
    }

    func trashMessage(messageId: String, forUserId userId: String = "me") -> Observable<Message> {
        let query = MessageTrashQuery.query(withUserId: userId, identifier: messageId)
        return trashMessage(query: query)
    }

    func trashMessage(query: MessageTrashQuery) -> Observable<Message> {
        return execute(query: query)
    }

    func untrashMessage(messageId: String, forUserId userId: String = "me") -> Observable<Message> {
        let query = MessageUntrashQuery.query(withUserId: userId, identifier: messageId)
        return untrashMessage(query: query)
    }

    func untrashMessage(query: MessageUntrashQuery) -> Observable<Message> {
        return execute(query: query)
    }
}
