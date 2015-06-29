//
//  TimelineViewController.swift
//  Makestagram
//
//  Created by Jonathan Wilhite on 6/27/15.
//  Copyright (c) 2015 Make School. All rights reserved.
//

import UIKit
import Parse

class TimelineViewController: UIViewController {
   
    @IBOutlet weak var tableView: UITableView!
    
    var photoTakingHelper: PhotoTakingHelper?
    var posts : [Post] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tabBarController?.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        ParseHelper.timelineRequestForCurrentUser { (result: [AnyObject]?, error: NSError?) -> Void in
            self.posts = result as? [Post] ?? []
            
            self.tableView.reloadData()
        
        }
    }
    
    func takePhoto() {
        //Instantiate Photo Taking class, providing callback for when photo is selected
        //Tab Bar Controller is the Root View Controller (RVC). Usually present popups on the RVC!!
        photoTakingHelper = PhotoTakingHelper(viewController: self.tabBarController!) {
            //This is a closure (fxn without a name). Enclosed in curly braces. Parameters in parentheses
            //Callback here receives a UIImage? from PhotoTakingHelper. "in" marks beginning of closure
            //Trailing closure here is located outside the argument list since the last arg is a closure
            (image: UIImage?) in
            
            let newPost = Post()
            //image is dynamic, so must use .value at the end!!
            newPost.image.value = image!
            newPost.uploadPost()
        }
    }
}

// MARK: Tab Bar Delegate

extension TimelineViewController: UITabBarControllerDelegate {
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        if (viewController is PhotoViewController) {
            takePhoto()
            return false
        } else {
            return true
        }
    }
}

extension TimelineViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    //This func gets called right before a cell gets displayed!!
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as! PostTableViewCell
        let post = posts[indexPath.row]
        
        //Trigger download directly before post is displayed
        post.downloadImage()
        post.fetchLikes()
        
        cell.post = post
        return cell
    }
}
