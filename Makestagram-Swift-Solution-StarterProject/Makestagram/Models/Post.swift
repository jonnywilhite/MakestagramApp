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
}
