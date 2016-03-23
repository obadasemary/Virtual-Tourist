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

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
