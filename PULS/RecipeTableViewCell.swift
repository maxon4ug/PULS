//
//  RecipeTableViewCell.swift
//  PULS
//
//  Created by Max Surgai on 29.07.17.
//  Copyright © 2017 Max Surgai. All rights reserved.
//

import UIKit

class RecipeTableViewCell: UITableViewCell {
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var ingredientsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.height / 2.0
        titleLabel.font = UIFont(name: "IowanOldStyle-Bold", size: 16.0)
        ingredientsLabel.font = UIFont(name: "IowanOldStyle-Roman", size: 10.0)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
