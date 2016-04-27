//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Jeff Tilson on 2016-04-26.
//  Copyright © 2016 Jeff Tilson. All rights reserved.
//

import CoreData

@objc(Pin)

class Pin: NSManagedObject {
    // MARK: - Dictionary Keys
    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let Photos = "photos"
    }
    
    // MARK: - Properties
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var photos: [Photo]
    
    // MARK: - NSManagedObject
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    /** Init a pin from a dictionary **/
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        // Get the entity associated with the Pin class
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        // Call the super's init (NSManagedObject) to insert the entity into the context
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Init the class properties
        latitude = dictionary[Keys.Latitude] as! NSNumber
        longitude = dictionary[Keys.Longitude] as! NSNumber
    }
}