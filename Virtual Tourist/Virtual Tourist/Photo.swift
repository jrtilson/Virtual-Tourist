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
    // MARK: - Properties
    @NSManaged var imageUrl: String?
    @NSManaged var imageId: String?
    @NSManaged var imageName: String?
    @NSManaged var pin: Pin?
    
    // Image property
    var imageData: NSData? {
        get {
            return loadImageData()
        }
        set {
            saveImageData(newValue)
        }
    }
    
    // MARK: - NSManagedObject
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    override func prepareForDeletion() {
        super.prepareForDeletion()
        deleteImageData()
    }
    
    /** Init a photo with a path dictionary **/
    init(id: String, url: String, context: NSManagedObjectContext) {
        // Get the entity associated with the Pin class
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        // Call the super's init (NSManagedObject) to insert the entity into the context
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Init the class properties
        imageUrl = url
        imageId = id
        imageName = NSURL(string: imageUrl!)?.lastPathComponent
    }
        
    // MARK: - Helpers 
    
    /* Get the path to our image on the filesystem */
    private func getLocalImageLocation() -> String? {
        if let name = imageName {
            let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
            return documentsDirectoryURL.URLByAppendingPathComponent(name as String).path
        }
        return nil
    }
    
    /* Load image data */
    private func loadImageData() -> NSData? {
        let imageLocation = getLocalImageLocation()
        
        guard (imageLocation != nil) else {
            return nil
        }
        
        guard let imageData = NSData(contentsOfFile: imageLocation!) else {
            return nil
        }
        
        return imageData
    }
    
    /* Save image to local filesystem */
    private func saveImageData(data: NSData!) {
        if let path = getLocalImageLocation() {
            data.writeToFile(path as String, atomically: true)
        }
    }
    
    /* Delete a photo from the documents directory */
    private func deleteImageData() -> Bool {
        
        if let path = getLocalImageLocation()  {
            let fileManger = NSFileManager.defaultManager()
            
            if (fileManger.fileExistsAtPath(path)) {
                do {
                    try fileManger.removeItemAtPath(path)
                    return true
                } catch {}
            }
        }
        return false
    }
    
}
