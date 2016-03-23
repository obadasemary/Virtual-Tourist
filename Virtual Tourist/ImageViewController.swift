//
//  ImageViewController.swift
//  Virtual Tourist
//
//  Created by Abdelrahman Mohamed on 3/23/16.
//  Copyright © 2016 Abdelrahman Mohamed. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {
    
    @IBOutlet weak var myImageView: UIImageView!

    var selectedImage: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(selectedImage)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let imageUrl = NSURL(string: self.selectedImage)
        let imageData = NSData(contentsOfURL: imageUrl!)
        if (imageData != nil) {
            self.myImageView.image = UIImage(data: imageData!)
        }
    }
}
