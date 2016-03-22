//
//  Pin+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Abdelrahman Mohamed on 3/21/16.
//  Copyright © 2016 Abdelrahman Mohamed. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Pin {

    @NSManaged var longitude: Double
    @NSManaged var latitude: Double
    @NSManaged var pageNumber: NSNumber?
    @NSManaged var pinTitle: String?
    @NSManaged var photos: NSSet?

}
