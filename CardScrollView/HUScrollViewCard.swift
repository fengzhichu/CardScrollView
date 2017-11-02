//
//  HUScrollViewCard.swift
//  CardScrollView
//
//  Created by Hummer on 16/7/8.
//  Copyright © 2016年 Hummer. All rights reserved.
//

import UIKit

class HUScrollViewCard: UIView {
    
    var contentView = UIView()
    var identifier: String?
    var index: Int = -1
    var selected = false
        
    override var description: String {
        return "<HUScrollViewCard: \(Unmanaged.passUnretained(self).toOpaque()): index: \(index)>\n"
    }
}
