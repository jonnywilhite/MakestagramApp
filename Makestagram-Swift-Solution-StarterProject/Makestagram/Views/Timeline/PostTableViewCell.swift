//
//  PostTableViewCell.swift
//  Makestagram
//
//  Created by Jonathan Wilhite on 6/27/15.
//  Copyright (c) 2015 Make School. All rights reserved.
//

import UIKit
import Bond
import Parse

class PostTableViewCell: UITableViewCell {
    
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var likesIconImageView: UIImageView!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    
    //This array represents list of users who have liked a certain post
    var likeBond : Bond<[PFUser]?>!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        //This closure runs whenever the Bond receives a new value. unowned self is a capture list that is needed to avoid retain cycles
        likeBond = Bond<[PFUser]?>() { [unowned self] likeList in
            
            //If likeList is not nil, change UI
            if let likeList = likeList {
                
                //UILabel!.text is used to change the text of a label... obviously
                self.likesLabel.text = self.stringFromUserList(likeList)
                
                //UIButton! has a selected property than can be toggled with true/false
                self.likeButton.selected = contains(likeList, PFUser.currentUser()!)
                
                self.likesIconImageView.hidden = (likeList.count == 0)
                
            } else {
                
                self.likesLabel.text = ""
                self.likeButton.selected = false
                self.likesIconImageView.hidden = true
            }
        }
    }
    
    @IBAction func moreButtonTapped(sender: AnyObject) {
        
    }
    
    @IBAction func likeButtonTapped(sender: AnyObject) {
        post?.toggleLikePost(PFUser.currentUser()!)
    }
    
    var post: Post? {
        didSet {
            //free memory of image no longer displayed
            //oldValue is available automatically in didSet. Allows us to access previous value
            if let oldValue = oldValue where oldValue != post {
                
                //When you have binding code, you should have code that unbinds when no longer needed
                //These two lines destroy the bonds created in the next if-statement
                likeBond.unbindAll()
                postImageView.designatedBond.unbindAll()
                
                //Only free up memory if image has no bonds remaining
                if (oldValue.image.bonds.count == 0) {
                    oldValue.image.value = nil
                }
            }
            
            if let post = post {
                //bind the image of the post to 'postImage' view
                post.image ->> postImageView
                post.likes ->> likeBond
            }
        }
    }
    
    func stringFromUserList(userList: [PFUser]) -> String {
        let usernameList = userList.map { user in user.username! }
        
        let commaSeparatedUserList = ", ".join(usernameList)
        
        return commaSeparatedUserList
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
