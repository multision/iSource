//
//  TabBar.swift
//  Nebular
//
//  Created by user on 4/30/18.
//  Copyright © 2018 MasonD3V. All rights reserved.
//

import UIKit

class TabBar: UITabBar {
    override var traitCollection: UITraitCollection {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            return super.traitCollection
        }
        
        return UITraitCollection(horizontalSizeClass: .compact)
    }
}
