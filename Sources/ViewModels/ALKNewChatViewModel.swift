//
//  ALKNewChatViewModel.swift
//  
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
import Applozic

final class ALKNewChatViewModel {
    
    var friendList = [ALKContactProtocol]()    // For UI presentation
    var bufferFriendList = [ALKContactProtocol]() {
        didSet {
            self.friendList = bufferFriendList
        }
    }
    
//    let friendDataService: FriendDataService

    init() {

    }
    
    func filter(keyword: String) {
        if keyword.isEmpty {
            self.friendList = self.bufferFriendList
        } else {
            self.friendList = self.bufferFriendList.filter({($0.friendProfileName != nil) ? $0.friendProfileName!.lowercased().contains(keyword.lowercased()): false})
        }
    }
    
    func getAllFriends(completion: @escaping () -> ()) {
        let dbHandler = ALDBHandler.sharedInstance()

        let fetchReq = NSFetchRequest<DB_CONTACT>(entityName: "DB_CONTACT")

        var predicate = NSPredicate()
        fetchReq.returnsDistinctResults = true
        if !ALUserDefaultsHandler.getLoginUserConatactVisibility() {
            predicate = NSPredicate(format: "userId!=%@ AND deletedAtTime == nil", ALUserDefaultsHandler.getUserId())
        }

        fetchReq.predicate = predicate
        do {
            let list = try dbHandler?.managedObjectContext.fetch(fetchReq)
            if let db = list {
                for dbContact in db {
                    let contact = ALContact()
                    contact.userId = dbContact.userId
                    contact.fullName = dbContact.fullName
                    contact.contactNumber = dbContact.contactNumber
                    contact.displayName = dbContact.displayName
                    contact.contactImageUrl = dbContact.contactImageUrl
                    contact.email = dbContact.email
                    contact.localImageResourceName = dbContact.localImageResourceName
                    contact.contactType = dbContact.contactType
                    self.bufferFriendList.append(contact)
                }
                completion()
            }

        } catch(let _) {

            completion()
        }
    }
    
    func numberOfSection() -> Int {
        return 2
    }
    
    func numberOfRowsInSection(section: Int) -> Int {
        
        return self.friendList.count
    }
    
    func friendForRow(indexPath: IndexPath) -> ALKContactProtocol {
        return self.friendList[indexPath.row]
    }
    
    // Internal class
    final class CreateGroup: ALKContactProtocol {
        
        var friendProfileName: String? = NSLocalizedString("CreateGroupTitle", value: "Create Group", comment: "")
        var friendUUID: String? = ""
        var friendMood: String? = ""
        var friendDisplayImgURL: URL? = nil
    }
    
    func createGroupCell() -> ALKContactProtocol {
        return CreateGroup()
    }
}
