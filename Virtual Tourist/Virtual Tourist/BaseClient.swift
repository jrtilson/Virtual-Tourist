//
//  BaseClient.swift
//  Virtual Tourist
//
//  Created by Jeff Tilson on 2016-03-01.
//  Copyright © 2016 Jeff Tilson. All rights reserved.
//

import Foundation

class BaseClient: NSObject {
    // MARK: - Class Properties
    var session: NSURLSession // Shared session
    var baseURL: String!
    
    // MARK: - Init
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    // MARK: - GET
    func performGET(method: String, parameters: [String : AnyObject], additionalHTTPHeaders: [String:String]?, completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        // Borrowed from the movie manager app
        
        /* 1. Set the parameters */
        let mutableParameters = parameters
        
        /* 2/3. Build the URL and configure the request */
        let urlString = baseURL + method + BaseClient.escapedParameters(mutableParameters)
        let url = NSURL(string: urlString)!
        
        let request = BaseClient.buildRequest(url, method: "GET", additionalHTTPHeaders: additionalHTTPHeaders)
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                completionHandler(result: nil, error: error)
                return
            }
            
            if let validationError = BaseClient.validateDataAndResponse(response, data: data) as NSError? {
                completionHandler(result: nil, error: validationError)
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            self.dynamicType.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }
    
    // MARK: - POST
    func performPOST(method: String, parameters: [String : AnyObject], jsonBody: [String:AnyObject], additionalHTTPHeaders: [String:String]?, completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        // Borrowed from the movie manager app
        
        /* 1. Set the parameters */
        let mutableParameters = parameters
        
        /* 2/3. Build the URL and configure the request */
        let urlString = baseURL + method + BaseClient.escapedParameters(mutableParameters)
        let url = NSURL(string: urlString)!
        
        let request = BaseClient.buildRequest(url, method: "POST", additionalHTTPHeaders: additionalHTTPHeaders)
        
        do {
            request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(jsonBody, options: .PrettyPrinted)
        }
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                completionHandler(result: nil, error: error)
                return
            }
            
            if let validationError = BaseClient.validateDataAndResponse(response, data: data) as NSError? {
                completionHandler(result: nil, error: validationError)
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            self.dynamicType.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }
    
    // MARK: - DELETE
    func performDELETE(method: String, parameters: [String: AnyObject], additionalHTTPHeaders: [String:String]?, completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        /* 1. Set the parameters */
        let mutableParameters = parameters
        
        /* 2/3. Build the URL and configure the request */
        let urlString = baseURL + method + BaseClient.escapedParameters(mutableParameters)
        let url = NSURL(string: urlString)!
        
        let request = BaseClient.buildRequest(url, method: "DELETE", additionalHTTPHeaders: additionalHTTPHeaders)
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { data, response, error in
            
            /* Check for an error */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                completionHandler(result: nil, error: error)
                return
            }
            
            if let validationError = BaseClient.validateDataAndResponse(response, data: data) as NSError? {
                completionHandler(result: nil, error: validationError)
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            self.dynamicType.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
        }
        
        task.resume()
        return task
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
    
    /* Helper: Substitute the key for the value that is contained within the method name */
    class func substituteKeyInMethod(method: String, key: String, value: String) -> String? {
        if method.rangeOfString("{\(key)}") != nil {
            return method.stringByReplacingOccurrencesOfString("{\(key)}", withString: value)
        } else {
            return nil
        }
    }
}
