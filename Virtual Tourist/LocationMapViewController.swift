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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
