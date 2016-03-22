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
    
    // MARK: - Perpar download from Flickr
    
    func downloadPhotosForPin(pin: Pin, completionHandler: (success: Bool, error: NSError?) -> Void) {
        
        var randomPageNumber: Int = 1
//        let numberPages = 1
        
        if let numberPages = pin.pageNumber?.integerValue {
            if numberPages > 0 {
                
                let pageLimit = min(numberPages, 20)
                randomPageNumber = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            }
        }
        
        // Parameters for request photos

        let parameters: [String : AnyObject] = [
            URLKeys.Method : Methods.Search,
            URLKeys.APIKey : Constants.APIKey,
            URLKeys.Format : URLValues.JSONFormat,
            URLKeys.NoJSONCallback : 1,
            URLKeys.Latitude : pin.latitude,
            URLKeys.Longitude : pin.longitude,
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
                    
                    pin.pageNumber = numberOfPhotoPages
                    
                    self.numberOfPhotoDownloaded = photosArray.count
                    
                    for photoDictionary in photosArray {
                        
                        guard let photoURLString = photoDictionary[URLValues.URLMediumPhoto] as? String else {
                            print("Error , photoDictionary")
                            continue
                        }
                        
                        let newPhoto = Photos(photoURL: photoURLString, pin: pin, context: self.sharedContext)
                
                        self.downloadPhotoImage(newPhoto, completionHandler: { (success, error) -> Void in
                            
                            self.numberOfPhotoDownloaded -= 1
                            
                            NSNotificationCenter.defaultCenter().postNotificationName("downloadPhotoImage.done", object: nil)
                            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                CoreDataStackManager.sharedInstacne().saveContext()
                            })
                        })
                    }
                    
                    completionHandler(success: true, error: nil)
            } else {
                
                completionHandler(success: false, error: NSError(domain: "downloadPhotosForPin", code: 0, userInfo: nil))
            }
        }
    }
    
    // MARK: - Download save image and change file path for photo
    
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
                print(fileURL)
                
                NSFileManager.defaultManager().createFileAtPath((fileURL.path)!, contents: result, attributes: nil)
                
                photo.filePath = fileURL.path
                
                completionHandler(success: true, error: nil)
            }
        }
    }
    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstacne().managedObjectContext
    }
}