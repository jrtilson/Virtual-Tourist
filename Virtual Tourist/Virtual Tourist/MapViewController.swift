//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Jeff Tilson on 2016-04-26.
//  Copyright © 2016 Jeff Tilson. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: - Properties
    var pinPhotosReady: Bool = false
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add a long press gesture recognizer to the map view
        let longPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addPin))
        mapView.addGestureRecognizer(longPress)
        
        // Attempt to restore the map region
        restoreMapRegion(false)
        
        // Attempt to fetch our Pin data from the fetchedResultsController
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        
        // Set fetchedResultsController delegate
        fetchedResultsController.delegate = self
        
        self.populateMap()
    }

    
    // lazy fetchedResultsController property
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.sharedContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        
        return fetchedResultsController
        
    }()

    
    // MARK: - Map region persistence
    
    /* Save the current map region */
    func saveMapRegion() {
        // Save the map view's latitude, longitude (and deltas)
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        
        // Archive the dictionary into the filePath
        NSUserDefaults.standardUserDefaults().setObject(dictionary, forKey: "mapRegion")
    }
    
    /* Restore the map region  */
    func restoreMapRegion(animated: Bool) {
        
        // Attempt to load and restore the the map region from the file archive
        if let regionDictionary = NSUserDefaults.standardUserDefaults().objectForKey("mapRegion") {
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            mapView.setRegion(savedRegion, animated: animated)
        }
    }
    
    // MARK: - MKMapViewDelegate Implementation
    
    /* Save the map view region to our keyed archiver when the region changes */
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
   
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
         /* Animate the annotation (actually drop the pin) */
        
        // I thought this would be straightforward, boy was I wrong. 
        // Found a good solution here: http://stackoverflow.com/a/34967157/1202510
        
        var i = -1;
        for view in views {
            i += 1;
            if view.annotation is MKUserLocation {
                continue;
            }
            
            // Check if current annotation is inside visible map rect, else go to next one
            let point:MKMapPoint  =  MKMapPointForCoordinate(view.annotation!.coordinate);
            if (!MKMapRectContainsPoint(self.mapView.visibleMapRect, point)) {
                continue;
            }
            
            let endFrame:CGRect = view.frame;
            
            // Move annotation out of view
            view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y - self.view.frame.size.height, view.frame.size.width, view.frame.size.height);
            
            // Animate drop
            let delay = 0.03 * Double(i)
            UIView.animateWithDuration(0.5, delay: delay, options: UIViewAnimationOptions.CurveEaseIn, animations:{() in
                view.frame = endFrame
                // Animate squash
                }, completion:{(Bool) in
                    UIView.animateWithDuration(0.05, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations:{() in
                        view.transform = CGAffineTransformMakeScale(1.0, 0.6)
                        
                        }, completion: {(Bool) in
                            UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations:{() in
                                view.transform = CGAffineTransformIdentity
                                }, completion: nil)
                })
            })
        }
        
        
    }
    
    /* Handle tapping on a map annotation - seque to the photo collection controller */
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        if let pin = getManagedPinFromCoordinate((view.annotation?.coordinate)!) {
            
            let controller = storyboard!.instantiateViewControllerWithIdentifier("PhotoCollectionViewController") as! PhotoCollectionViewController
            
            controller.pin = pin
            
            CoreDataStackManager.sharedInstance().saveContext()
            
            // De-select (fix for can't select the same pin again)
            mapView.deselectAnnotation(view.annotation, animated: false)
            
            self.navigationController!.pushViewController(controller, animated: true)
        } else {
            

            
            print("Counted: \(fetchedResultsController.fetchedObjects?.count) objects in fetched results")
            print("Counted: \(mapView.annotations.count) pins on map")
        }
    }
    
    // MARK: - FetchedResultsControllerDelegate 
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        do {
            try fetchedResultsController.performFetch()
        } catch {}
    }
    
    // MARK: - Helpers
    
    /* Action for a long press gesture recognizer */
    func addPin(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let coordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinates
            mapView.addAnnotation(annotation)
            
            // Create a new Pin object with lat/long
            let dictionary: [String: AnyObject] = [
                Pin.Keys.Longitude: coordinates.longitude,
                Pin.Keys.Latitude: coordinates.latitude
            ]
            
            // Create with sharedContext
            let addedPin = Pin(dictionary: dictionary, context: sharedContext)
            
            CoreDataStackManager.sharedInstance().saveContext()
            
            FlickrClient.sharedInstance().getPhotosForLatitudeLongitude(addedPin.latitude, longitude: addedPin.longitude) { (result, error) in
                // Check for an error fetching the photos from the api
                guard (error == nil) else {
                    print(error)
                    return
                }
                
                // Create photo entities
                for apiPhoto in result! {
                    
                    // New entity
                    let newPhoto = Photo(
                        id: apiPhoto[FlickrClient.JSONResponseKeys.Id]! as! String,
                        url: apiPhoto[FlickrClient.QueryStringValues.URLMedium]! as! String,
                        context: self.sharedContext
                    )
                    
                    // Set this new pin to this photo
                    newPhoto.pin = addedPin
                    
                    FlickrClient.sharedInstance().downloadImageFromUrl(newPhoto.imageUrl!) {(data, error) in
                        guard (error == nil) else {
                            print(error?.localizedDescription)
                            return
                        }
                        
                        if let data = data {
                            newPhoto.imageData = data
                            NSNotificationCenter.defaultCenter().postNotificationName("photoDownloadComplete", object: nil)
                            
                            dispatch_async(dispatch_get_main_queue(), {
                                CoreDataStackManager.sharedInstance().saveContext()
                            })
                        }
                    }
                }
            }
        }
    }
    
    /* Helper function to populate the MapView */
    func populateMap() {
        // Set up an array of MKPointAnnotations
        var annotations = [MKPointAnnotation]()
            
        for object in fetchedResultsController.fetchedObjects!  {
            // Get the individual pin object
            if let pin = object as? Pin {
                
                let lat = CLLocationDegrees(pin.latitude)
                let long = CLLocationDegrees(pin.longitude)
                
                // Generate coordinate and annotations
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotations.append(annotation)
            }
        }
        // When the array is loaded, we add the annotations to the map.
        self.mapView.addAnnotations(annotations)
        
    }
    
    /* Determine which pin from our fetchedResults matches the given coordinates */
    func getManagedPinFromCoordinate(coordinate: CLLocationCoordinate2D) -> Pin? {
        for object in fetchedResultsController.fetchedObjects!  {
            if let pin = object as? Pin {
                if (NSNumber(double: coordinate.latitude) == pin.latitude && NSNumber(double: coordinate.longitude) == pin.longitude) {
                    return pin
                }
            }
        }
        return nil
    }
}

