//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Abdelrahman Mohamed on 3/23/16.
//  Copyright © 2016 Abdelrahman Mohamed. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var pin: Pin? = nil
    
    // Flag for deletong photo
    var isDeleting = false

    var editingFlage: Bool = false

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    // Array of IndexPath - keeping track of index of selected cells
    var selectedIndexOfCollectionViewCells = [NSIndexPath]()
    
    // MARK: - Core Data
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstacne().managedObjectContext
    }
    
    // MARK: - Fetched Results Controller
    
    // Lazily computed property pointing to the Photos entity objects, sorted by title, predicated on the pin.
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        // Create fetch request for photos which match the sent Pin.
        let fetchRequest = NSFetchRequest(entityName: "Photos")
        
        // Limit the fetch request to just those photos related to the Pin.
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin!)

        // Sort the fetch request by title, ascending.
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        // Create fetched results controller with the new fetch request.
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    }()
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        newCollectionButton.hidden = false
        noImagesLabel.hidden = true
        
        loadMapView()
        
        mapView.delegate = self
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
//        do {
//            try fetchedResultsController.performFetch()
//        } catch let error as NSError {
//            print("\(error)")
//        }
        reFetch()
        
        fetchedResultsController.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "photoReload", name: "downloadPhotoImage.done", object: nil)
    }
    
    // Inserting dispatch_async to ensure the closure always run in the main thread
    func photoReload(notification: NSNotification) {
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            self.collectionView.reloadData()
            
            // If no photos remaining, show the 'New Collection' button
            let numberRemainig = FlickrClient.sharedInstance().numberOfPhotoDownloaded
            print("numberRemaining is from photoReload \(numberRemainig)")
            
            if numberRemainig <= 0 {
                self.newCollectionButton.hidden = false
            }
        }
    }
    
    private func reFetch() {
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("reFetch - \(error)")
        }
    }
    
    func loadMapView() {
        
        let point = MKPointAnnotation()
        
        point.coordinate = CLLocationCoordinate2DMake((pin?.latitude)!, (pin?.longitude)!)
        point.title = pin?.pinTitle
        mapView.addAnnotation(point)
        mapView.centerCoordinate = point.coordinate
        
        mapView.selectAnnotation(point, animated: true)
    }

    @IBAction func newCollection(sender: UIButton) {
        
        newCollectionButton.hidden = true
        
        if isDeleting == true {
            
            for indexPath in selectedIndexOfCollectionViewCells {
                
                let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photos
                print("Deleting this - \(photo)")
                
                sharedContext.deleteObject(photo)
            }
            
            selectedIndexOfCollectionViewCells.removeAll()
            
            CoreDataStackManager.sharedInstacne().saveContext()
            
            reFetch()
            
            collectionView.reloadData()
            
            newCollectionButton.setTitle("New Collection", forState: UIControlState.Normal)
            newCollectionButton.hidden = false
            
            isDeleting = false
        } else {
            
            for photo in fetchedResultsController.fetchedObjects as! [Photos] {
                sharedContext.deleteObject(photo)
            }
            
            CoreDataStackManager.sharedInstacne().saveContext()
            
            FlickrClient.sharedInstance().downloadPhotosForPin(pin!, completionHandler: { (success, error) -> Void in
                
                if success {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                        CoreDataStackManager.sharedInstacne().saveContext()
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        print("Error downloading a new set of photos")
                        self.newCollectionButton.hidden = false
                    })
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.reFetch()
                    self.collectionView.reloadData()
                })
            })
        }
    }
    
    @IBAction func editCollection(sender: UIBarButtonItem) {
        
        if editingFlage == false {
            editingFlage = true
            navigationItem.rightBarButtonItem?.title = "Done"
            print(editingFlage)
        } else if editingFlage {
            navigationItem.rightBarButtonItem?.title = "Edit"
            editingFlage = false
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let sectionInfo = self.fetchedResultsController.sections![section]
        print("Number of photos returned from fetchedResultsController #\(sectionInfo.numberOfObjects)")

        // If numberOfObjects is not zero, hide the noImagesLabel
        noImagesLabel.hidden = sectionInfo.numberOfObjects != 0
        
        return sectionInfo.numberOfObjects
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if editingFlage == false {
            
            let myImageViewPage: ImageViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ImageViewController") as! ImageViewController
            
            let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photos
            
            myImageViewPage.selectedImage = photo.url!
            
            self.navigationController?.pushViewController(myImageViewPage, animated: true)
        } else if editingFlage == true {
            
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
            
            if let indexPath = selectedIndexOfCollectionViewCells.indexOf(indexPath) {
                selectedIndexOfCollectionViewCells.removeAtIndex(indexPath)
                cell.deleteButton.hidden = true
            } else {
                selectedIndexOfCollectionViewCells.append(indexPath)
                cell.deleteButton.hidden = false
            }
        }
        
        if selectedIndexOfCollectionViewCells.count > 0 {
            
            print("Delete array has \(selectedIndexOfCollectionViewCells.count) photo(s).")
            if selectedIndexOfCollectionViewCells.count == 1 {
                newCollectionButton.setTitle("Delete \(selectedIndexOfCollectionViewCells.count) photo", forState: UIControlState.Normal)
            } else {
                newCollectionButton.setTitle("Delete \(selectedIndexOfCollectionViewCells.count) photos", forState: .Normal)
            }
            isDeleting = true
        } else {
            newCollectionButton.setTitle("New Collection", forState: .Normal)
            isDeleting = false
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photos
        
        cell.photoView.image = photo.image
        
        cell.deleteButton.hidden = true
        cell.deleteButton.layer.setValue(indexPath, forKey: "indexPath")
        
        cell.deleteButton.addTarget(self, action: "deletePhoto", forControlEvents: .TouchUpInside)
        
        return cell
    }
    
    func deletePhoto(sender: UIButton) {
        
        let indexOfTheItem = sender.layer.valueForKey("indexPath") as! NSIndexPath
        
        let photo = fetchedResultsController.objectAtIndexPath(indexOfTheItem) as! Photos
        
        if let index = selectedIndexOfCollectionViewCells.indexOf(indexOfTheItem) {
            selectedIndexOfCollectionViewCells.removeAtIndex(index)
        }
        
        sharedContext.deleteObject(photo)
        
        CoreDataStackManager.sharedInstacne().saveContext()
        
        reFetch()
        collectionView.reloadData()
    }
}
