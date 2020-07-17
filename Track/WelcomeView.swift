//
//  WelcomeView.swift
//  Track
//
//  Created by Bradley on 7/16/20.
//  Copyright © 2020 Bradley. All rights reserved.
//

import Foundation
import UIKit

class WelcomeView:UIView{
    
    @IBOutlet weak var iconView: UIImageView!
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        iconView.layer.masksToBounds = true
        iconView.contentMode = .scaleAspectFit
        iconView.layer.shouldRasterize = true
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 20
        
//        iconView.layer.borderWidth = 5
//        iconView.layer.borderColor  = UIColor.systemGray4.cgColor
    }
    @IBAction func downloadANchor(_ sender: UIButton) {
        Help.downloadAnchor(vc: self.parentViewController!, sender: sender)
    }
}
