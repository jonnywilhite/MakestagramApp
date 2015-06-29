//
//  TimelineViewController.swift
//  Makestagram
//
//  Created by Jonathan Wilhite on 6/27/15.
//  Copyright (c) 2015 Make School. All rights reserved.
//

import UIKit
import Parse
import ConvenienceKit

class TimelineViewController: UIViewController, TimelineComponentTarget {
   
    @IBOutlet weak var tableView: UITableView!
    
    var photoTakingHelper: PhotoTakingHelper?
    
    let defaultRange = 0...4
    let additionalRangeSize = 5
    
    //Provide Type you are displaying AND the class that will be the target of TimelineComponent in < >
    var timelineComponent : TimelineComponent<Post,TimelineViewController>!
    
    func loadInRange(range: Range<Int>, completionBlock: ([Post]?) -> Void) {
        ParseHelper.timelineRequestForCurrentUser(range) { (result: [AnyObject]?, error: NSError?) -> Void in
            let posts = result as? [Post] ?? []
            completionBlock(posts)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        timelineComponent = TimelineComponent(target: self)
        self.tabBarController?.delegate = self
    }
    //Called as soon as TableView becomes available
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        //This method only gets called if table view is becoming visible for the first time
        timelineComponent.loadInitialIfRequired()
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
        return timelineComponent.content.count
    }
    
    //This func gets called right before a cell gets displayed!!
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as! PostTableViewCell
        let post = timelineComponent.content[indexPath.row]
        
        //Trigger download directly before post is displayed
        post.downloadImage()
        post.fetchLikes()
        
        cell.post = post
        return cell
    }
}

//Directly call TimelineComponent and inform it that a cell has been displayed
extension TimelineViewController: UITableViewDelegate {
    //This method gets called whenever we are about to display a cell
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        timelineComponent.targetWillDisplayEntry(indexPath.row)
    }
}
