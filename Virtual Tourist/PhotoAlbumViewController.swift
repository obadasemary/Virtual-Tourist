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
        
        mapView.delegate = self
        
        // Load the map
        loadMapView()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
//        // Perform the fetch
//        do {
//            try fetchedResultsController.performFetch()
//        } catch let error as NSError {
//            print("\(error)")
//        }

        // Perform the fetch
        reFetch()
        
        
        // Set the delegate to this view controller
        fetchedResultsController.delegate = self
        
        // Subscirbe to notification so photos can be reloaded - catches the notification from FlickrConvenient
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "photoReload:", name: "downloadPhotoImage.done", object: nil)

        
    }
    
    // MARK: - photoReload
    
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
    
    // MARK: - reFetch fetchedResultsController
    
    private func reFetch() {
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("reFetch - \(error)")
        }
        
        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "photoReload", name: "downloadPhotoImage.done", object: nil)
    }
    
    // MARK: - loadMapView
    
    // Load map view for the current pin
    func loadMapView() {
        
        let point = MKPointAnnotation()
        
        point.coordinate = CLLocationCoordinate2DMake((pin?.latitude)!, (pin?.longitude)!)
        point.title = pin?.pinTitle
        mapView.addAnnotation(point)
        mapView.centerCoordinate = point.coordinate
        
        // Select the annotation so the title can be shown
        mapView.selectAnnotation(point, animated: true)
    }
    
    // MARK: - New Collection Button

    // Note: "new' images might overlap with previous collections of images
    @IBAction func newCollection(sender: UIButton) {
        
        // Hiding the button once it's tapped, because I want to finish either deleting or reloading first
        newCollectionButton.hidden = true
        
        // If deleting flag is true, delete the photo
        if isDeleting == true {
            
            // Removing the photo that user selected one by one
            for indexPath in selectedIndexOfCollectionViewCells {
                
                // Get photo associated with the indexPath.
                let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photos
                
                print("Deleting this - \(photo)")
                
                // Remove the photo
                sharedContext.deleteObject(photo)
            }
            
            // Empty the array of indexPath after deletion
            selectedIndexOfCollectionViewCells.removeAll()
            
            // Save the chanages to core data
            CoreDataStackManager.sharedInstacne().saveContext()
            
            // Update cells
            reFetch()
            collectionView.reloadData()
            
            // Change the button to say 'New Collection' after deletion
            newCollectionButton.setTitle("New Collection", forState: UIControlState.Normal)
            newCollectionButton.hidden = false
            
            isDeleting = false
            
            // Else "New Collection" button is tapped
        } else {
            
            // 1. Empty the photo album from the previous set
            for photo in fetchedResultsController.fetchedObjects as! [Photos] {
                sharedContext.deleteObject(photo)
            }
            
            // 2. Save the chanages to core data
            CoreDataStackManager.sharedInstacne().saveContext()
            
            // 3. Download a new set of photos with the current pin
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
                
                // Update cells
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.reFetch()
                    self.collectionView.reloadData()
                })
            })
        }
    }
    
    // MARK: - edit Collection Button
    
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
    
    // MARK: - Collection View Protcols
    
    // Return the number of photos from fetchedResultsController
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let sectionInfo = self.fetchedResultsController.sections![section]
        print("Number of photos returned from fetchedResultsController #\(sectionInfo.numberOfObjects)")

        // If numberOfObjects is not zero, hide the noImagesLabel
        noImagesLabel.hidden = sectionInfo.numberOfObjects != 0
        
        return sectionInfo.numberOfObjects
    }

    // Remove photos from an album when user select a cell or multiple cells
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if editingFlage == false {
            
            //performSegueWithIdentifier("ImageViewController", sender: nil)
            let myImageViewPage: ImageViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ImageViewController") as! ImageViewController
            
            let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photos
            
            // pass image
            myImageViewPage.selectedImage = photo.url!
            
            self.navigationController?.pushViewController(myImageViewPage, animated: true)
        } else if editingFlage == true {
            
            // Configure the UI of the collection item
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
            
            // When user deselect the cell, remove it from the selectedIndexofCollectionViewCells array
            if let indexPath = selectedIndexOfCollectionViewCells.indexOf(indexPath) {
                selectedIndexOfCollectionViewCells.removeAtIndex(indexPath)
                cell.deleteButton.hidden = true
            } else {
                // Else, add it to the selectedIndexofCollectionViewCells array
                selectedIndexOfCollectionViewCells.append(indexPath)
                cell.deleteButton.hidden = false
            }
        }
        
        // If the selectedIndexofCollectionViewCells array is not empty, show the 'Delete all' button
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
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photos
        
        cell.photoView.image = photo.image
        
        cell.deleteButton.hidden = true
        cell.deleteButton.layer.setValue(indexPath, forKey: "indexPath")
        
        // Trigger the action 'deletePhoto' when the button is tapped
        cell.deleteButton.addTarget(self, action: "deletePhoto", forControlEvents: .TouchUpInside)
        
        return cell
    }
    
    // MARK: - Delete Photo
    
    func deletePhoto(sender: UIButton) {
        
        // I want to know if the cell is selected giving the indexPath
        let indexOfTheItem = sender.layer.valueForKey("indexPath") as! NSIndexPath
        
        // Get the photo associated with the indexPath
        let photo = fetchedResultsController.objectAtIndexPath(indexOfTheItem) as! Photos
        print("Delete cell selected from 'deletePhoto' is \(photo)")

        // When user deselected it, remove it from the selectedIndexofCollectionViewCells array
        if let index = selectedIndexOfCollectionViewCells.indexOf(indexOfTheItem) {
            selectedIndexOfCollectionViewCells.removeAtIndex(index)
        }
        
        // Remove the photo
        sharedContext.deleteObject(photo)
        
        // Save to core data
        CoreDataStackManager.sharedInstacne().saveContext()
        
        // Update selected cell
        reFetch()
        collectionView.reloadData()
    }
}
