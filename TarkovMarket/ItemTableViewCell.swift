//
//  ItemTableViewCell.swift
//  TarkovMarket
//
//  Created by Will Chew on 2020-03-12.
//  Copyright © 2020 Will Chew. All rights reserved.
//

import UIKit

class ItemTableViewCell: UITableViewCell {

    @IBOutlet weak var itemImageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet weak var slotsLabel: UILabel!
    
    @IBOutlet weak var updatedLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        itemImageView.image = nil
    }

}
