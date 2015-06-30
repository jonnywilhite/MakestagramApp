//
//  PostSectionHeaderView.swift
//  Makestagram
//
//  Created by Jonathan Wilhite on 6/30/15.
//  Copyright (c) 2015 Make School. All rights reserved.
//

import UIKit

class PostSectionHeaderView: UITableViewCell {
    
    @IBOutlet weak var postTimeLabel : UILabel!
    @IBOutlet weak var usernameLabel : UILabel!
    
    var post : Post? {
        didSet {
            if let post = post {
                usernameLabel.text = post.user?.username
                //Reading the createdAt data from Parse Post class. 
                //shortTimeAgoSinceDate(_:) takes a comparison date, which we create with NSDate()
                postTimeLabel.text = post.createdAt?.shortTimeAgoSinceDate(NSDate()) ?? ""
            }
        }
    }
}
