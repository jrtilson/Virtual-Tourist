//
//  ViewHelpers.swift
//  Virtual Tourist
//
//  Created by Jeff Tilson on 2016-04-29.
//  Copyright © 2016 Jeff Tilson. All rights reserved.
//

import UIKit
import Foundation
import CoreData

/* Collection of helpers for view controllers */
public extension UIViewController {
    /* Display an error message in an alert */
    func displayError(errorMessage: String?) {
        dispatch_async(dispatch_get_main_queue()) {
            let alert = UIAlertController(title: "Error", message: errorMessage!, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - Core Data Convenience
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
}