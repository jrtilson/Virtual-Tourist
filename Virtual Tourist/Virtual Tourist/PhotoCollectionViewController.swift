//
//  PhotoCollectionViewController.swift
//  Virtual Tourist
//
//  Created by Jeff Tilson on 2016-04-27.
//  Copyright © 2016 Jeff Tilson. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoCollectionViewController: UIViewController, NSFetchedResultsControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    // MARK: - Properties
    var pin: Pin!

    let zoomedRegionRadius: CLLocationDistance = 100000
    var photosDownloaded = 0 // Track downloaded photos
    

    // Need to store the photos to update/insert/delete for batch processing
    var insertedPhotos: [NSIndexPath]!
    var updatedPhotos: [NSIndexPath]!
    var deletedPhotos: [NSIndexPath]!
    
    
    // MARK: - Outlets

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var noPhotosLabel: UILabel!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sort out cell layout
        //layoutCells()
        
        // Set collection view delegate/datasource
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Get the pin location on our map view
        let lat = CLLocationDegrees(pin.latitude)
        let long = CLLocationDegrees(pin.longitude)
        
        // Set location for setting the map region
        let location = CLLocation(latitude: lat, longitude: long)
        
        // Generate coordinate and annotations
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate

        // When the array is loaded, we add the annotations to the map.
        mapView.addAnnotation(annotation)
        
        // Perform the fetch
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        
        // Set the delegate to this view controller
        fetchedResultsController.delegate = self
        
        
        // Center Map
        centerMapOnLocation(location, radius: zoomedRegionRadius)
        
        // Disable the new collection button initially
        newCollectionButton.enabled = false
        
        // Register to be notified that a photo has finished downloading
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PhotoCollectionViewController.reloadCollectionView(_:)), name: "photoDownloadComplete", object: nil)
        
        // Do an initial check of photo download status (may have downloaded already in the map view controller)
        checkPhotoDownloads()
    }
    
    // Mark: - Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "imageId", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.sharedContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        
        return fetchedResultsController
        
    }()

    // MARK: - NSFetchedResultsControllerDelegate
    
    /* Set up arrays for batch updates */
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // Instantiate empty arrays for batch updates
        insertedPhotos = [NSIndexPath]()
        updatedPhotos = [NSIndexPath]()
        deletedPhotos = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController,
                    didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?,
                                    forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
            case .Insert:
                insertedPhotos.append(newIndexPath!)
            case .Delete:
                deletedPhotos.append(indexPath!)
            case .Update:
                updatedPhotos.append(indexPath!)
            default:
                return
        }
    }
    
    /* Handle the batched photo updates */
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        // Batch all updates, animated
        self.collectionView.performBatchUpdates({() -> Void in
           
            self.collectionView.insertItemsAtIndexPaths(self.insertedPhotos)
            self.collectionView.reloadItemsAtIndexPaths(self.updatedPhotos)
            self.collectionView.deleteItemsAtIndexPaths(self.deletedPhotos)

            }, completion: {(finished: Bool) -> Void in
                print("Finished updates: \(finished)")
        })
    }
    
    
    // MARK: - UICollectionViewDelegate
    
    /* Handle selection of a photo cell in the collection view */
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        // collection view cell selected
        if (self.newCollectionButton.enabled == true) {
            let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
            sharedContext.deleteObject(photo)
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }
    
    /* Get the numer of photos from the fetched resutls */
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        let sectionInfo = self.fetchedResultsController.sections![section]
        
        if (sectionInfo.numberOfObjects > 0) {
            noPhotosLabel.hidden = true
        } else {
            noPhotosLabel.hidden = false
            newCollectionButton.enabled = true
        }
        
        return sectionInfo.numberOfObjects
    }

    /* Handle loading individual cells with our photo data */
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if let photoImage = photo.imageData {
            cell.imageView.image = UIImage(data: photoImage)
            cell.activityView.hidden = true
        } else {
            cell.activityView.startAnimating()
        }
        
        return cell
    }
    
    // MARK: - Actions

    /* Handle new collection button - will delete and refresh all photos in the fetched data */
    @IBAction func newCollectionButtonTapped(sender: AnyObject) {
 
        for photo in fetchedResultsController.fetchedObjects! {
            if let photo = photo as? Photo {
                sharedContext.deleteObject(photo)
            }
        }
        
        reloadPhotoData()

    }
    
    // MARK: - Helpers
    
    func checkPhotoDownloads() -> Void {
        var completedPhotoCount = 0
        
        for object in fetchedResultsController.fetchedObjects! {
            if let photo = object as? Photo {
                if photo.imageData != nil {
                    completedPhotoCount += 1
                }
            }
        }
        
        // See if the amount of photos downloaded add's up to the amount in the fetched results
        if fetchedResultsController.fetchedObjects!.count == completedPhotoCount {
            newCollectionButton.enabled = true
        }
    }
    
    /* Reload collection view cells */
    func reloadPhotoData() {
        print("Reloading data")
        newCollectionButton.enabled = false
        FlickrClient.sharedInstance().getPhotosForLatitudeLongitude(self.pin.latitude, longitude: self.pin.longitude) { (result, error) in
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
                newPhoto.pin = self.pin
                
                
                
                FlickrClient.sharedInstance().downloadImageFromUrl(newPhoto.imageUrl!) {(data, error) in
                    guard (error == nil) else {
                        print(error?.localizedDescription)
                        return
                    }
                    
                    if let data = data {
                        newPhoto.imageData = data
                        NSNotificationCenter.defaultCenter().postNotificationName("photoDownloadComplete", object: nil)
                    }
                }
            }
            do {
                try self.fetchedResultsController.performFetch()
            } catch {}
        }
    }
    
    /* Reload collection view cells */
    func reloadCollectionView(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), {
            self.checkPhotoDownloads()
            self.collectionView.reloadData()
        })
    }
    
    /* Center map on the location of our pin */
    func centerMapOnLocation(location: CLLocation, radius: CLLocationDistance) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, radius, radius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    /* Helper to sort out our collection view layout */
    func layoutCells() {
        // Using flow layout
        let layout = UICollectionViewFlowLayout()
        
        // Set insets
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 10, right: 10)
        
        // Line/item spacing
        layout.minimumInteritemSpacing = 5
        
        // Set the item size to fit within the screen in rows of 3
        layout.minimumLineSpacing = 5.0
        layout.itemSize = CGSize(width: (UIScreen.mainScreen().bounds.size.width - 40)/3, height: ((UIScreen.mainScreen().bounds.size.width - 40)/3))
        collectionView!.collectionViewLayout = layout
    }
    
}
