//
//  ProfileTableViewCell.swift
//  ArcFaceTest
//
//  Created by 李博文 on 20/02/2018.
//  Copyright © 2018 王宇鑫. All rights reserved.
//

import UIKit

class ProfileTableViewCell: UITableViewCell {
    
    

    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
            profileImageView.clipsToBounds = true
        }
    }
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
