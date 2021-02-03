//
//  BasicVC.swift
//  BCPlayer_Example
//
//  Created by mtAdmin on 2021/2/2.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import BCPlayer

class BasicVC: UIViewController {
    override func viewDidLoad() {
        title = "基础"
        
        let playerView = VideoPlayerView()
        playerView.frame(forAlignmentRect: CGRect(x: 0, y: 100, width: 300, height: 200))
        self.view.addSubview(playerView)
        
//        playerView.sta
    }
}
