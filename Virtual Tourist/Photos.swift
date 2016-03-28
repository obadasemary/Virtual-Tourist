//
//  Photos.swift
//  Virtual Tourist
//
//  Created by Abdelrahman Mohamed on 3/21/16.
//  Copyright © 2016 Abdelrahman Mohamed. All rights reserved.
//

import UIKit
import CoreData


class Photos: NSManagedObject {

    var image: UIImage? {
        
        if let filePath = filePath {
            
            if filePath == "error" {
                return UIImage(named: "404.jpg")
            }
            
            let fileName = (filePath as NSString).lastPathComponent
            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            let pathArray = [dirPath,fileName]
            let fileURL = NSURL.fileURLWithPathComponents(pathArray)
            
            return UIImage(contentsOfFile: (fileURL!.path)!)
        }
        
        return nil
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(photoURL: String, pin: Pin, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Photos", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.url = photoURL
        self.pin = pin
        
        print("init from photos.swift \(url)")
    }
    
    override func prepareForDeletion() {
        super.prepareForDeletion()
        
        if filePath != nil {
            
//            let fileName = (filePath! as NSString).lastPathComponent
//            
//            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentationDirectory, .UserDomainMask, true)[0]
//            
//            let pathArray = [dirPath, fileName]
//            
//            let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
//            
//            do {
//                try NSFileManager.defaultManager().removeItemAtURL(fileURL)
//            } catch let error as NSError {
//                print("Error from prepareForDeletion - \(error)")
//            }
//        } else {
//            print("filepath is empty")
//        }
            
            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            let pathArray = [dirPath, filePath]
            
            let fileURL = NSURL.fileURLWithPath(pathArray)
            
            do {
                try NSFileManager.defaultManager().removeItemAtURL(fileURL)
            } catch let error as NSError {
                print("Error from prepareForDeletion - \(error)")
            }
        } else {
            print("filepath is empty")
        }
    }
}
