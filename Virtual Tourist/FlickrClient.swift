//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Abdelrahman Mohamed on 3/21/16.
//  Copyright © 2016 Abdelrahman Mohamed. All rights reserved.
//

import UIKit
import CoreData

class FlickrClient: NSObject {
    
    var numberOfPhotoDownloaded = 0
    
    var session: NSURLSession
    
    // MARK: - Shared session
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    // MARK: - GET Request
    func taskForGETMethodWithParameters(parameters: [String : AnyObject], completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        let urlString = Constants.BaseURL + self.escapedParameters(parameters)
        let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            
            guard (error == nil) else {
                let newError = self.errorForResponse(data, response: response, error: error!)
                completionHandler(result: nil, error: newError)
                return
            }
            self.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
        }
        
        task.resume()
    }
    
    // MARK: - POST
    func taskForGETMethod(urlString: String, completionHandler: (result: NSData?, error: NSError?) -> Void) {
        
        let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            
            guard (error == nil) else {
                let newError = self.errorForResponse(data, response: response, error: error!)
                completionHandler(result: nil, error: newError)
                return
            }
            
            completionHandler(result: data, error: nil)
        }
        task.resume()
    }
    
    // MARK: - Given row JSON, Return Data
    func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsingError: NSError?
        let parsedResult: AnyObject?
        
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
            print("Parse error - \(parsingError?.localizedDescription)")
            return
        }
        
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            completionHandler(result: parsedResult, error: nil)
        }
    }
    
    // MARK: - GET Error for Response
    func errorForResponse(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        if let parsedResult = (try? NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)) as? [String : AnyObject] {
            
            if let status = parsedResult[JSONResponseKeys.Status] as? String,
                let message = parsedResult[JSONResponseKeys.Message] as? String {
                    
                    if status == JSONResponseValues.Fail {
                        
                        let userInfo = [NSLocalizedDescriptionKey: message]
                        
                        return NSError(domain: "Virtual Tourist Error", code: 1, userInfo: userInfo)
                    }
            }
        }
        return error
    }
    
    // MARK: - Escape HTML Parameters
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
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
    
    class func sharedInstance() -> FlickrClient {
        
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }
}