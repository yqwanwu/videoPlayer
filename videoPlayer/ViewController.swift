//
//  ViewController.swift
//  videoPlayer
//
//  Created by wanwu on 2017/4/20.
//  Copyright © 2017年 wanwu. All rights reserved.
//

import UIKit

class ViewController: UIViewController, VideoPlayerControlViewDelegate {
    
    var vv: VideoPlayerControlView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        //播放器
        let url = URL(string: "http://baobab.wdjcdn.com/1451897812703c.mp4")
        vv = VideoPlayerControlView(frame: UIScreen.main.bounds)
        vv.frame.size.height = UIScreen.main.bounds.width * 9 / 16
        vv.center.y += 100
//        vv.changeDirByTransform = true
        
        
        //        let img = UIImage(named: "playPauseBtn12")
        //        vv.centerPlayPauseBtn?.bounds = CGRect(x: 0, y: 0, width: 80, height: 35)
        //        vv.centerPlayPauseBtn?.setImage(img, for: .normal)
        //        var imgsArr = [UIImage]()
        //        for i in 12...31 {
        //            imgsArr.append(UIImage(named: "playPauseBtn\(i)")!)
        //        }
        //        vv.centerPlayPauseBtn?.imageView?.animationImages = imgsArr
        //        vv.centerPlayPauseBtn?.imageView?.animationDuration = 1
        //        vv.centerPlayPauseBtn?.imageView?.animationRepeatCount = 10000
        //        vv.centerPlayPauseBtn?.imageView?.startAnimating()
        //        vv.setBuffingAction { (v) in
        //            if !(v.centerPlayPauseBtn?.imageView?.isAnimating ?? false) {
        //                v.centerPlayPauseBtn?.imageView?.startAnimating()
        //            }
        //            v.centerPlayPauseBtn?.isHidden = false
        //        }
        
        //        var cbhided = false
        //        vv.setPlayAction { [weak self] (v) in
        //            if v.centerPlayPauseBtn?.imageView?.isAnimating ?? false {
        //                v.centerPlayPauseBtn?.imageView?.stopAnimating()
        //                if !cbhided {
        //                    cbhided = true
        //                    v.centerPlayPauseBtn?.isHidden = true
        //                }
        //            }
        //        }
        
        self.view.addSubview(vv)
//        vv.delegate = self
        
        vv.url = url
        
        vv.whenBack = { [unowned self] _ in
            self.dismiss(animated: true, completion: nil)
        }
    }

    @IBAction func ac_change(_ sender: Any) {
        vv.url = Bundle.main.url(forResource: "test", withExtension: "mov")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

}

