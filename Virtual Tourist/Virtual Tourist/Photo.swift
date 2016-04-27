//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Jeff Tilson on 2016-04-26.
//  Copyright © 2016 Jeff Tilson. All rights reserved.
//

import CoreData

@objc(Photo)

class Photo: NSManagedObject {
    // MARK: - Dictionary Keys
    struct Keys {
        static let ImagePath = "ImagePath"
    }
    
    // MARK: - Properties
    @NSManaged var imagePath: String?
    @NSManaged var pin: Pin?
    
    // MARK: - NSManagedObject
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    /** Init a photo with a path dictionary **/
    init(path: String, context: NSManagedObjectContext) {
        // Get the entity associated with the Pin class
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        // Call the super's init (NSManagedObject) to insert the entity into the context
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Init the class properties
        imagePath = path
    }

}
