//
//  ParseHelper.swift
//  Makestagram
//
//  Created by Jonathan Wilhite on 6/27/15.
//  Copyright (c) 2015 Make School. All rights reserved.
//

import Foundation
import Parse

class ParseHelper {
    
    //Use constants instead of strings to reduce ambiguity AND number of errors!!
    //Following Relation
    static let ParseFollowClass         = "Follow"
    static let ParseFollowFromUser      = "fromUser"
    static let ParseFollowToUser        = "toUser"
    
    //Like Relation
    static let ParseLikeClass           = "Like"
    static let ParseLikeFromUser        = "fromUser"
    static let ParseLikeToPost          = "toPost"
    
    //Post Relation
    static let ParsePostUser            = "user"
    static let ParsePostCreatedAt       = "createdAt"
    
    //Flagged Content Relation
    static let ParseFlaggedContentClass     = "Flagged"
    static let ParseFlaggedContentFromUser  = "fromUser"
    static let ParseFlaggedContentToPost    = "toPost"
    
    //User Relation
    static let ParseUserUsername        = "username"
    
    //static means we can call it without having to create instance of ParseHelper. Do this for all helper fxns!!
    //Range defines which portions of timeline get loaded
    static func timelineRequestForCurrentUser(range: Range<Int>, completionBlock: PFArrayResultBlock) {
        let followingQuery = PFQuery(className: ParseFollowClass)
        followingQuery.whereKey(ParseLikeFromUser, equalTo: PFUser.currentUser()!)
        
        let postsFromFollowedUsers = Post.query()
        postsFromFollowedUsers!.whereKey(ParsePostUser, matchesKey: ParseFollowToUser, inQuery: followingQuery)
        
        let postsFromThisUser = Post.query()
        postsFromThisUser!.whereKey(ParsePostUser , equalTo: PFUser.currentUser()!)
        
        let query = PFQuery.orQueryWithSubqueries([postsFromFollowedUsers!, postsFromThisUser!])
        query.includeKey(ParsePostUser)
        query.orderByDescending(ParsePostCreatedAt)
        
        //Skipping posts that have already been loaded
        query.skip = range.startIndex
        query.limit = range.endIndex - range.startIndex
        
        query.findObjectsInBackgroundWithBlock(completionBlock)
    }
    
    //MARK: Likes
    
    static func likePost(user: PFUser, post: Post) {
        let newLike = PFObject(className: ParseLikeClass)
        newLike[ParseLikeFromUser] = user
        newLike[ParseLikeToPost] = post
        
        newLike.saveInBackgroundWithBlock(ErrorHandling.errorHandlingCallback)
    }
    
    static func unlikePost(user: PFUser, post: Post) {
        let newQuery = PFQuery(className: ParseLikeClass)
        newQuery.whereKey(ParseLikeFromUser, equalTo: user)
        newQuery.whereKey(ParseLikeToPost, equalTo: post)
        
        newQuery.findObjectsInBackgroundWithBlock { (results: [AnyObject]?, error: NSError?) -> Void in
            if let error = error {
                ErrorHandling.defaultErrorHandler(error)
            }
            
            if let results = results as? [PFObject] {
                for likes in results {
                    //Passing nil because we don't want to do any code after we perform background deletion
                    //Now we are passing an error handling callback so we can be informed of any errors
                    likes.deleteInBackgroundWithBlock(ErrorHandling.errorHandlingCallback)
                }
            }
        }
    }
    
    //takes in var of type PFArrayResultBlock, which has signature ([AnyObject}?, NSError?) -> Void. This is
    //default signature for callback of most Parse queries. Takes in optional result and optional error!
    static func likesForPost(post: Post, completionBlock: PFArrayResultBlock) {
        let query = PFQuery(className: ParseLikeClass)
        query.whereKey(ParseLikeToPost, equalTo: post)
        
        //Using includeKey because we want to remember the names of the users who like the post
        query.includeKey(ParseLikeFromUser)
        
        query.findObjectsInBackgroundWithBlock(completionBlock)
    }
    
    //MARK: Following
    
    //Fetches all users that current user is following. completionBlock is called when query completes
    static func getFollowingUsersForUser(user: PFUser, completionBlock: PFArrayResultBlock) {
        let query = PFQuery(className: ParseFollowClass)
        
        query.whereKey(ParseFollowFromUser, equalTo: user)
        
        query.findObjectsInBackgroundWithBlock(completionBlock)
    }
    
    static func addFollowRelationshipFromUser(user: PFUser, toUser: PFUser) {
        let followObject = PFObject(className: ParseFollowClass)
        followObject.setObject(user, forKey: ParseFollowFromUser)
        followObject.setObject(toUser, forKey: ParseFollowToUser)
        
        followObject.saveInBackgroundWithBlock(ErrorHandling.errorHandlingCallback)
    }
    
    static func removeFollowRelationshipFromUser(user: PFUser, toUser: PFUser) {
        let query = PFQuery(className: ParseFollowClass)
        
        query.whereKey(ParseFollowFromUser, equalTo: user)
        query.whereKey(ParseFollowToUser, equalTo: toUser)
        
        query.findObjectsInBackgroundWithBlock { (results: [AnyObject]?, error: NSError?) -> Void in
            let results = results as? [PFObject] ?? []
            
            for follow in results {
                follow.deleteInBackgroundWithBlock(ErrorHandling.errorHandlingCallback)
            }
        }
    }
    
    //MARK: Users
    
    static func allUsers(completionBlock: PFArrayResultBlock) -> PFQuery {
        let query = PFUser.query()!
        query.whereKey(ParseHelper.ParseUserUsername, notEqualTo: PFUser.currentUser()!.username!)
        query.orderByAscending(ParseHelper.ParseUserUsername)
        
        query.limit = 20
        
        query.findObjectsInBackgroundWithBlock(completionBlock)
        
        return query
    }
    
    static func searchUsers(searchText: String, completionBlock: PFArrayResultBlock) -> PFQuery {
        
        //Regex allows case insensitive search. Not recommneded for large datasets (store lowercase name in separate column
        let query = PFUser.query()!.whereKey(ParseHelper.ParseUserUsername, matchesRegex: searchText, modifiers: "i")
        query.whereKey(ParseHelper.ParseUserUsername, notEqualTo: PFUser.currentUser()!.username!)
        
        query.orderByAscending(ParseHelper.ParseUserUsername)
        query.limit = 20
        
        query.findObjectsInBackgroundWithBlock(completionBlock)
        
        return query
    }
}

extension PFObject: Equatable {

}

public func ==(lhs: PFObject, rhs: PFObject) -> Bool {
    
    //This line is necessary in order to ensure that users aren't cloned (different objects with same ID)
    return lhs.objectId == rhs.objectId
}
