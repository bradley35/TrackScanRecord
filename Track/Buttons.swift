//
//  Buttons.swift
//  Track
//
//  Created by Bradley on 7/9/20.
//  Copyright © 2020 Bradley. All rights reserved.
//

import Foundation
import UIKit

class ContextMenuButton:UIButton{
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.addTarget(self, action: #selector(darken(sender:)), for: .touchDown)
        self.addTarget(self, action: #selector(darken(sender:)), for: .touchDragEnter)
        self.addTarget(self, action: #selector(lighten(sender:)), for: .touchUpInside)
        self.addTarget(self, action: #selector(lighten(sender:)), for: .touchUpOutside)
        self.addTarget(self, action: #selector(lighten(sender:)), for: .touchDragExit)
        self.addTarget(self, action: #selector(lighten(sender:)), for: .touchCancel)
    }
    
    @objc func darken(sender:UIButton){
        self.backgroundColor = UIColor(displayP3Red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
    }
    @objc func lighten(sender:UIButton){
        self.backgroundColor = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 1)
    }
}
