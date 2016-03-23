//
//  PhotoCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Abdelrahman Mohamed on 3/23/16.
//  Copyright © 2016 Abdelrahman Mohamed. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var photoView: UIImageView!
    
    @IBOutlet weak var deleteButton: UIButton!
    
    override func prepareForReuse() {
        
        super.prepareForReuse()
        
        if photoView.image == nil {
            activityIndicator.startAnimating()
        }
    }
}
