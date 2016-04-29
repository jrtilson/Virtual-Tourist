//
//  FlickrConstants.swift
//  Virtual Tourist
//
//  Created by Jeff Tilson on 2016-04-27.
//  Copyright © 2016 Jeff Tilson. All rights reserved.
//

import Foundation

/* Provide handy constants for the FlickrClient */
extension FlickrClient {
    struct Methods {
        static let Search = "flickr.photos.search"
    }
    
    struct Constants {
        static let BaseURL: String = "https://api.flickr.com/services/rest/"
        static let FlickrApiKey = "8c05877b95a924123f90ca10bd12b00d"
    }
    
    struct QueryStringKeys {
        static let ApiKey = "api_key"
        static let Method = "method"
        static let Latitude = "lat"
        static let Longitude = "lon"
        static let Format = "format"
        static let RawJSON = "nojsoncallback"
        static let PerPage = "per_page"
        static let Extras = "extras"
        static let Media = "media"
        static let Page = "page"
    }
    
    struct QueryStringValues {
        static let URLMedium = "url_m"
        static let FormatJSON = "json"
        static let MediaPhotos = "photos"
    }
    
    struct JSONResponseKeys {
        static let Photos = "photos"
        static let Photo = "photo"
        static let Id = "id"
    }
}
