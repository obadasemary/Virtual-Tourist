//
//  FlickrConvenient.swift
//  Virtual Tourist
//
//  Created by Abdelrahman Mohamed on 3/21/16.
//  Copyright © 2016 Abdelrahman Mohamed. All rights reserved.
//

import UIKit
import CoreData

extension FlickrClient {
    
    func downloadPhotosForPin(text: String, completionHandler: (success: Bool, error: NSError?) -> Void) {
        
        var randomPageNumber: Int = 1
        let numberPages = 1
        
        if numberPages > 0 {
            
            let pageLimit = min(numberPages, 20)
            randomPageNumber = Int(arc4random_uniform(UInt32(pageLimit))) + 1
        }
        
        let parameters: [String : AnyObject] = [
            URLKeys.Method : Methods.Search,
            URLKeys.APIKey : Constants.APIKey,
            URLKeys.Format : URLValues.JSONFormat,
            URLKeys.NoJSONCallback : 1,
            URLKeys.Text : text,
            URLKeys.Extras : URLValues.URLMediumPhoto,
            URLKeys.Page : randomPageNumber,
            URLKeys.PerPage : 21
        ]
        
        taskForGETMethodWithParameters(parameters) { (result, error) -> Void in
            
            guard (error == nil) else {
                completionHandler(success: false, error: error)
                return
            }
            
            if let photosDictionary = result.valueForKey(JSONResponseKeys.Photos) as? [String : AnyObject],
                photosArray = photosDictionary[JSONResponseKeys.Photo] as? [[String : AnyObject]],
                numberOfPhotoPages = photosDictionary[JSONResponseKeys.Pages] as? Int {
                    
                    self.numberOfPhotoDownloaded = photosArray.count
                    
                    for photoDictionary in photosArray {
                        
                        guard let photoURLString = photoDictionary[URLValues.URLMediumPhoto] as? String else {
                            print("Error , photoDictionary")
                            continue
                        }
                        
//                        let newPhoto = Photos(photoURL: photoURLString, pin: pin, context: self.sharedContext)
                        
                        let newPhoto = Photos(photoURL: photoURLString, context: self.sharedContext)
                        
                        self.downloadPhotoImage(newPhoto, completionHandler: { (success, error) -> Void in
                            
                            self.numberOfPhotoDownloaded -= 1
                            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                CoreDataStackManager.sharedInstacne().saveContext()
                            })
                        })
                    }
                    
                    completionHandler(success: true, error: nil)
            }
            
            completionHandler(success: false, error: NSError(domain: "downloadPhotosForPin", code: 0, userInfo: nil))
        }
    }
    
    func downloadPhotoImage(photo: Photos, completionHandler: (success: Bool, error: NSError?) -> Void) {
        
        let imageURLString = photo.url
        
        taskForGETMethod(imageURLString!) { (result, error) -> Void in
            
            guard (error == nil) else {
                print("Error from downloadPhotoImage \(error?.localizedDescription)")
                completionHandler(success: false, error: error)
                return
            }
            
            if let result = result {
                
                let fileName = (imageURLString! as NSString).lastPathComponent
                let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
                let pathArray = [dirPath, fileName]
                let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
                
                NSFileManager.defaultManager().createFileAtPath((fileURL.path)!, contents: result, attributes: nil)
                
                photo.filePath = fileURL.path
                
                completionHandler(success: true, error: nil)
            }
        }
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstacne().managedObjectContext
    }
}