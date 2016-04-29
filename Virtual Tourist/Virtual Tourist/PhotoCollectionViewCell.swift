//
//  PhotoCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Jeff Tilson on 2016-04-28.
//  Copyright © 2016 Jeff Tilson. All rights reserved.
//


// Great tutorial on custom cells: http://www.ioscreator.com/tutorials/custom-collection-view-cell-tutorial-ios8-swift


import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Outlets
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    @IBOutlet weak var imageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // This fixes an issue with the cells appearing to 
        // trade places while slowly downloading
        imageView.image = nil
        
        // Make sure the spinner is visible and animating once we've nil'd the image
        activityView.hidden = false;
        activityView.startAnimating()
    }
}
