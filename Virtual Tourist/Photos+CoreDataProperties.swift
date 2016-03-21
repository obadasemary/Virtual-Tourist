//
//  Photos+CoreDataProperties.swift
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

extension Photos {

    @NSManaged var id: String?
    @NSManaged var title: String?
    @NSManaged var url: String?
    @NSManaged var filePath: String?
    @NSManaged var pin: Pin?

}
