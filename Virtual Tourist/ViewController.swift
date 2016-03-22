//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Abdelrahman Mohamed on 3/20/16.
//  Copyright © 2016 Abdelrahman Mohamed. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print(error)
        }
        
        fetchedResultsController.delegate = self
        
        let currentphoto = fetchedResultsController.fetchedObjects?.count
//        let photo = fetchedResultsController.indexPathForObject(indexpath) as? NSData
        
//        imageView.image = UIImage(data: photo!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstacne().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photos")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    }()
}

