//
//  BaseClient.swift
//  Virtual Tourist
//
//  Created by Jeff Tilson on 2016-03-01.
//  Copyright © 2016 Jeff Tilson. All rights reserved.
//

import Foundation

class FlickrClient: NSObject {
    // MARK: - Class Properties
    var session: NSURLSession // Shared session
    var isDownloading: Bool = false
    
    // MARK: - Init
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    // MARK: - GET
    func performGET(url: String, parameters: [String : AnyObject], additionalHTTPHeaders: [String:String]?, completionHandler: (result: NSData!, error: NSError?) -> Void) -> NSURLSessionDataTask {
    
        /* Build the URL and configure the request */
        let urlString = url + FlickrClient.escapedParameters(parameters)
        
        let url = NSURL(string: urlString)!
        
        let request = FlickrClient.buildRequest(url, method: "GET", additionalHTTPHeaders: additionalHTTPHeaders)
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                completionHandler(result: nil, error: error)
                return
            }
            
            if let validationError = FlickrClient.validateDataAndResponse(response, data: data) as NSError? {
                completionHandler(result: nil, error: validationError)
            }
            
            
            completionHandler(result: data!, error: nil)
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }
    
    
    // MARK: - FlickrClient Convenience
    
    /* Get photos locations from flickr for a given latitude/longitude */
    func getPhotosForLatitudeLongitude(latitude: NSNumber, longitude: NSNumber, completionHandler: (result: [AnyObject]?, error: NSError?) -> Void) {

        let url = Constants.BaseURL
        
        let parameters = [
            QueryStringKeys.Method: Methods.Search,
            QueryStringKeys.ApiKey: Constants.FlickrApiKey,
            QueryStringKeys.Format: QueryStringValues.FormatJSON,
            QueryStringKeys.RawJSON: 1,  // Force raw json results (no callback)
            QueryStringKeys.PerPage: "24", // Nice round number for our collection view
            QueryStringKeys.Latitude: latitude,
            QueryStringKeys.Longitude: longitude,
            QueryStringKeys.Extras: QueryStringValues.URLMedium,
            QueryStringKeys.Media: QueryStringValues.MediaPhotos
        ]
        
        performGET(url, parameters: parameters, additionalHTTPHeaders: [String: String]()) {data, error in
            if let error = error {
                completionHandler(result: nil, error: error)
            } else {
                
                FlickrClient.parseJSONWithCompletionHandler(data, completionHandler: { (JSONResult, error) in
                    if let error = error {
                        completionHandler(result: nil, error: error)
                    } else {
                    
                        // We should get a dictionary of String:AnyObjects from the photos key here
                        guard let photos = JSONResult[FlickrClient.JSONResponseKeys.Photos] as? [String : AnyObject] else {
                            completionHandler(result: nil, error: NSError(domain: "getPhotosForLatitudeLongitude parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse 'photos' from getPhotosForLatitudeLongitude"]))
                            return
                        }
                        
                        // The photos key will return an array of objects
                        guard let photoArray = photos[FlickrClient.JSONResponseKeys.Photo] as? [AnyObject] else {
                            completionHandler(result: nil, error: NSError(domain: "getPhotosForLatitudeLongitude parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse 'photo' array from getPhotosForLatitudeLongitude"]))
                            return
                        }
                        
                        completionHandler(result: photoArray, error: nil)
                    }
                })
            }
        }
    }
    
    func downloadImageFromUrl(imageUrl: String, completionHandler: (imageData: NSData?, error: NSError?) -> Void) {
        // Try downloaidng the image
        performGET(imageUrl, parameters: [String: String](), additionalHTTPHeaders: [String: String]()) {data, error in
            if let error = error {
                completionHandler(imageData: nil, error: error)
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }

    }
    
    // MARK: - Helper functions
    class func buildRequest(url: NSURL, method: String, additionalHTTPHeaders: [String:String]?) -> NSMutableURLRequest {
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = method
        
        if let additionalHTTPHeaders = additionalHTTPHeaders {
            for (field, value) in additionalHTTPHeaders {
                request.addValue(value, forHTTPHeaderField: field)
            }
        }
        
        return request
    }
    
    /* Convert a dictionary of parameters to a string for a url (From movie manager app) */
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    /* Check the data and response from a request for valid data */
    class func validateDataAndResponse(response: AnyObject?, data: AnyObject?) -> NSError? {
        /* GUARD: Did we get a successful 2XX response? */
        guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
            if let response = response as? NSHTTPURLResponse {
                return NSError(domain: "invalid status code", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: "Invalid Status Code: (\(response.statusCode))"]);
            } else if let response = response {
                print("Your request returned an invalid response! Response: \(response)!")
                return NSError(domain: "invalid respomse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Your request returned an invalid response! Response: \(response)!"]);
            } else {
                print("Your request returned an invalid response! (Invalid response object)")
                return NSError(domain: "invalid respomse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Your request returned an invalid response!"]);
            }
        }
        
        /* GUARD: Was there any data returned? */
        guard let _ = data else {
            return NSError(domain: "invalid data", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data!"]);
        }
        
        return nil
    }
    
    /* Return a legit object from from JSON data (From movie manager app) */
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsedResult: AnyObject!
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandler(result: nil, error: NSError(domain: "parseJSONWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandler(result: parsedResult, error: nil)
    }
    
    // Class variable to get access to a static shared instance
    class func sharedInstance() -> FlickrClient {
        struct Static {
            static let instance = FlickrClient()
        }
        return Static.instance
    }
}
