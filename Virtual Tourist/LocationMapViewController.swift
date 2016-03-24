//
//  LocationMapViewController.swift
//  Virtual Tourist
//
//  Created by Abdelrahman Mohamed on 3/23/16.
//  Copyright © 2016 Abdelrahman Mohamed. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class LocationMapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    var pins = [Pin]()
    var selectedPin: Pin? = nil
    
    var editingPins: Bool = false
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstacne().managedObjectContext
    }
    
    func fetchAllPins() -> [Pin] {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch {
            print("error in fetch")
            return [Pin]()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: "handLongPress:")
        
        longPressRecogniser.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecogniser)
        
        mapView.delegate = self
        
        addSavedPinsToMap()
    }
    
    func addSavedPinsToMap() {
        
        pins = fetchAllPins()
        print("Pins Count in core data is \(pins.count)")
        
        for pin in pins {
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = pin.coordinate
            annotation.title = pin.pinTitle
            mapView.addAnnotation(annotation)
        }
    }
    
    @IBAction func editClicked(sender: UIBarButtonItem) {
        
        if editingPins == false {
            editingPins = true
            navigationItem.rightBarButtonItem?.title = "Done"
        } else if editingPins {
            navigationItem.rightBarButtonItem?.title = "Edit"
            editingPins = false
        }
    }
    
    func handLongPress(gestureRecognizer: UIGestureRecognizer) {
        
        if (editingPins) {
            return
        } else {
            
            if gestureRecognizer.state != .Began {
                return
            }
            
            // take point
            let touchPoint = gestureRecognizer.locationInView(self.mapView)
            
            // convert point to coordinate from view
            let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            
            // init annotation
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchMapCoordinate
            
            // init new pin
            let newPin = Pin(lat: annotation.coordinate.latitude, long: annotation.coordinate.longitude, context: sharedContext)
            
            // save to core data
            CoreDataStackManager.sharedInstacne().saveContext()
            
            // adding newpin to pins array
            pins.append(newPin)
            
            // add newpin to map
            mapView.addAnnotation(annotation)
            
            FlickrClient.sharedInstance().downloadPhotosForPin(newPin, completionHandler: { (success, error) -> Void in
                
                let coordinates = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
                
                let geoCoder = CLGeocoder()
                
                geoCoder.reverseGeocodeLocation(coordinates, completionHandler: { (placemark, error) -> Void in
                    
                    guard (error == nil) else {
                        print("Error: \(error?.localizedDescription)")
                        return
                    }
                    
                    if placemark!.count > 0 {
                        let pm = placemark![0] as CLPlacemark
                        if (pm.locality != nil) && (pm.country != nil) {
                            annotation.title = "\(pm.locality), \(pm.country)"
                        } else {
                            print("Error in placemark")
                        }
                    }
                })
            })
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        annotationView.canShowCallout = false
        
        return annotationView
    }

    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        guard let annotation = view.annotation else {
            return
        }
        
        let title = annotation.title!
        print(annotation.title)
        
        selectedPin = nil
        
        for pin in pins {
            
            if annotation.coordinate.latitude == pin.latitude && annotation.coordinate.longitude == pin.longitude {
                
                selectedPin = pin
                
                if editingPins {
                    
                    print("Deleting pin")
                    sharedContext.deleteObject(selectedPin!)
                    
                    // delete selected pin on map
                    self.mapView.removeAnnotation(annotation)
                    
                    // save changes in core data
                    CoreDataStackManager.sharedInstacne().saveContext()
                } else {
                    
                    if title != nil {
                        pin.pinTitle = title!
                    } else {
                        pin.pinTitle = "This pin has no name"
                    }
                    
                    // Move to the Phone Album View Controller
                    self.performSegueWithIdentifier("PhotoAlbum", sender: nil)
                }
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if (segue.identifier == "PhotoAlbum") {
            
            let viewController = segue.destinationViewController as! PhotoAlbumViewController
            viewController.pin = selectedPin
        }
    }
    
    // Change map type (satellite) via segmented control
    @IBAction func segmentedControlAction(sender: UISegmentedControl) {
        
        switch (sender.selectedSegmentIndex) {
        case 0:
            mapView.mapType = .Standard
        case 1:
            mapView.mapType = .Satellite
        case 2:
            mapView.mapType = .Hybrid
        default:
            mapView.mapType = .Standard
        }
    }
}
