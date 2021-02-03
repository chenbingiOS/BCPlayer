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
    
    @IBOutlet weak var playerView: VideoPlayerView!
    @IBOutlet weak var stateLabel: UILabel!
    
    deinit {
        print("BasicVC 释放")
    }
    
    override func viewDidLoad() {
        title = "基础"
        
        playerView.play(for: URL(string: "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")!)
        
        playerView.stateDidChanged = { [weak self] state in
            guard let self = self else {
                return
            }
            
            switch state {
            case .none:
                self.stateLabel.text = "none"
            case .loading:
                self.stateLabel.text = "loading"
            case .playing:
                self.stateLabel.text = "playing"
            case .paused:
                self.stateLabel.text = "paused"
            case .error:
                self.stateLabel.text = "error"
            }
        }
        
        

    }
}
