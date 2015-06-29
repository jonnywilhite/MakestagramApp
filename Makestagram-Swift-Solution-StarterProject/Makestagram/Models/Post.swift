//
//  Post.swift
//  Makestagram
//
//  Created by Jonathan Wilhite on 6/27/15.
//  Copyright (c) 2015 Make School. All rights reserved.
//

import Foundation
import Parse
import Bond

class Post: PFObject, PFSubclassing {
    
    @NSManaged var imageFile : PFFile?
    @NSManaged var user : PFUser?
    
    //Dynamic allows us to listen to changes for wrapped value
    var image : Dynamic<UIImage?> = Dynamic(nil)
    var photoUploadTask : UIBackgroundTaskIdentifier?
    
    //likes is an array of Users. Could be empty hence the optional
    var likes = Dynamic<[PFUser]?>(nil)
    
    //MARK: Subclassing Protocol
    
    static func parseClassName() -> String {
        return "Post"
    }
    
    override init() {
        super.init()
    }
    
    override class func initialize() {
        var onceToken : dispatch_once_t = 0;
        dispatch_once(&onceToken) {
            //Inform Parse about this subclass
            self.registerSubclass()
        }
    }
    //init() and initialize() are pure boilerplate: copy these into any custom Parse class you make
    //Follow these steps when you want to create custom Parse classes
    
    func uploadPost() {
        let imageData = UIImageJPEGRepresentation(image.value, 0.8)
        let imageFile = PFFile(data: imageData)
        
        // This is boilerplate code: Come back here when you wanna create a background job
        photoUploadTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler { () -> Void in
            UIApplication.sharedApplication().endBackgroundTask(self.photoUploadTask!)
        }
        
        imageFile.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
            UIApplication.sharedApplication().endBackgroundTask(self.photoUploadTask!)
        }
        //End boilerplate code
        
        //PFUser.currentUser() allows us to access the user currently logged in
        user = PFUser.currentUser()
        self.imageFile = imageFile
        saveInBackgroundWithBlock(nil)
    }
    
    func downloadImage() {
        // if image is not downloaded yet, get it
        if (image.value == nil) {
            
            //Start download (in background this time!!)
            imageFile?.getDataInBackgroundWithBlock { (data: NSData?, error: NSError?) -> Void in
                if let data = data {
                    let image = UIImage(data: data, scale:1.0)!
                    
                    //Download complete, update image
                    self.image.value = image
                }
            }
        }
    }
    
    func fetchLikes() {
        
        //If likes already has a value stored, skip method
        if likes.value != nil {
            return
        }
        
        //Fetch likes
        ParseHelper.likesForPost(self, completionBlock: { (var likes: [AnyObject]?, error: NSError?) -> Void in
            
            //filter takes in a closure, returns subset of array s.t. all elements meet requirement in closure
            //closure gets called for each element in array, passing current element each time
            //We filter because we remove likes from users that no longer exist
            likes = likes?.filter { like in like[ParseHelper.ParseLikeFromUser] != nil }
            
            //like filter, map takes in closure that gets called for each element in array
            //map replaces likes in the array with users associated with said like
            self.likes.value = likes?.map { like in
                let like = like as! PFObject
                let fromUser = like[ParseHelper.ParseLikeFromUser] as! PFUser
                
                return fromUser
            }
        })
    }
    
    func doesUserLikePost(user: PFUser) -> Bool {
        if let likes = likes.value {
            return contains(likes, user)
        } else {
            return false
        }
    }
    
    func toggleLikePost(user: PFUser) {
        if (doesUserLikePost(user)) {
            //if user does like Post, unlike it
            
            //remove user from local cache stored in Likes property
            likes.value = likes.value?.filter { $0 != user }
            ParseHelper.unlikePost(user, post: self)
        } else {
            //else like the post
            
            //add user to local cache stored in Likes property
            likes.value?.append(user)
            ParseHelper.likePost(user, post: self)
        }
    }
}
