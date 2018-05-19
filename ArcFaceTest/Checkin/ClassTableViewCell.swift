//
//  ClassTableViewCell.swift
//  ArcFaceTest
//
//  Created by 张睿恺 on 2018/4/7.
//  Copyright © 2018年 王宇鑫. All rights reserved.
//

import UIKit

class ClassTableViewCell: UITableViewCell {

    @IBOutlet weak var Classname: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
