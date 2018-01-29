//
//  VideoPlayerControlView.swift
//  player
//
//  Created by wanwu on 16/8/11.
//  Copyright © 2016年 wanwu. All rights reserved.
//


/**
 plist
 View controller-based status bar appearance =  no
 */

import UIKit
import MediaPlayer

protocol VideoPlayerControlViewDelegate: NSObjectProtocol {
    func shouldFullScreen(playerView: VideoPlayerControlView) -> Bool
    func shouldPlay(playerView: VideoPlayerControlView) -> Bool
    func canUseGesture(playerView: VideoPlayerControlView) -> Bool
    
    func didChangeRoate(playerView: VideoPlayerControlView)
    func didLocked(locked: Bool)
}

extension VideoPlayerControlViewDelegate {
    func shouldFullScreen(playerView: VideoPlayerControlView) -> Bool {
        return true
    }
    
    func shouldPlay(playerView: VideoPlayerControlView) -> Bool {
        return true
    }
    
    func canUseGesture(playerView: VideoPlayerControlView) -> Bool {
        return true
    }
    
    func didChangeRoate(playerView: VideoPlayerControlView) {
        
    }
    
    func didLocked(locked: Bool) {
        
    }
}

class VideoPlayerControlView: UIView {
    typealias whenButtonClick = (_ button: UIButton) -> Void
    
    enum PanDirection {
        case horizontal
        case vertical
    }
    
    ///设置url后，如果地址没问题， 就直接开始冲
    var url: URL? {
        didSet {
            if url != nil {
                setupPlayer(url: url!)
            } else {
                print("视频链接 为空")
            }
        }
    }
    
    var allowPlayInBackground = false
    
    ///如果为true。就是当前controller不允许旋转，只能改变transform来改变视频方向
    var changeDirByTransform = false
    
    var playLoop = false
    
    weak var delegate: VideoPlayerControlViewDelegate?
    
    var buffEnd = false
    
    var canLayoutByCustom = false
    
    var canFullScreen = true
    
    var isFullScreen = false
    
    weak var bottomView: UIView?
    
    var timeObserver: Any?
    
    fileprivate var timerCount = 0
    //自动隐藏，工具条
    fileprivate var timer: Timer?
    
    var barHeight: CGFloat = 62.0
    var barFadeOutTimeInterval = 12
    
    var backButton: UIButton!
    var lockButton: UIButton!
    var bufferProgressView: UIProgressView!
    var titleLabel: UILabel!
    var tipView: UILabel!
    var didEnterBackground = false
    
    var timePercent: Float = 0.0
    
    fileprivate var origenalFrame: CGRect = CGRect.zero
    
    var topBar: UIView!
    var bottomBar: UIView!
    var playButton: UIButton!
    var fullScreenButton: UIButton!
    var progressSlider: UISlider!
    var timeLabel: UILabel!
    
    var progressSliderFocus = false
    
    var indicatorView: UIActivityIndicatorView!
    var juhua: UIActivityIndicatorView!
    var centerPlayPauseBtn: UIButton? {
        didSet {
            if centerPlayPauseBtn == nil {
                oldValue?.removeFromSuperview()
            }
        }
    }
    var isPlayEnd = false
    
    var volumeSlider: UISlider!
    fileprivate var brightnessView = BrightnessView.shared
    fileprivate var timeIndicatorView: TimeIndicatorView!
    
    fileprivate var isPortraitByUser = false
    var shouldAutorotate: Bool {
        if self.lockButton.isSelected {
            return UIScreen.main.bounds.width > UIScreen.main.bounds.height && isPortraitByUser
        } else {
            return true
        }
    }
    
    ///返回事件
    var whenBack: whenButtonClick?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setlupUI()
        setupSetings()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setlupUI()
        setupSetings()
    }
    
    private var buffingAction: ((_ plaerView: VideoPlayerControlView) -> Void)?
    private var playAction: ((_ plaerView: VideoPlayerControlView) -> Void)?
    private var seekAction: ((_ plaerView: VideoPlayerControlView) -> Void)?
    
    func setSeekAction(action: ((_ plaerView: VideoPlayerControlView) -> Void)?) {
        seekAction = action
    }
    
    func setBuffingAction(action: ((_ plaerView: VideoPlayerControlView) -> Void)?) {
        buffingAction = action
    }
    
    func setPlayAction(action: ((_ plaerView: VideoPlayerControlView) -> Void)?) {
        playAction = action
    }
    
    //MARK: 初始化UI
    func setlupUI() {
        self.backgroundColor = UIColor.black
        let margin: CGFloat = 10.0
        let marginTop: CGFloat = 22
        
        topBar = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: barHeight))
        topBar.backgroundColor = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.3)
        bottomBar = UIView(frame: CGRect(x: 0, y: bounds.height - barHeight, width: frame.width, height: barHeight))
        bottomBar.backgroundColor = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.3)
        
        playButton = UIButton(frame: CGRect(x: margin, y: 0, width: barHeight, height: barHeight))
        playButton.setImage(UIImage(named: "kr-video-player-play"), for: .normal)
        playButton.setImage(UIImage(named: "kr-video-player-pause"), for: .selected)
        
        fullScreenButton = UIButton(frame: CGRect(x: frame.width - margin - barHeight, y: 0, width: barHeight, height: barHeight))
        fullScreenButton.setImage(UIImage(named: "kr-video-player-fullscreen"), for: .normal)
        fullScreenButton.setImage(UIImage(named: "kr-video-player-shrinkscreen"), for: .selected)
        
        progressSlider = UISlider(frame: CGRect(x: playButton.frame.maxX, y: 0, width: frame.width - playButton.frame.maxX * 2, height: barHeight))
        progressSlider.setThumbImage(UIImage(named: "kr-video-player-point"), for: .normal)
        progressSlider.minimumTrackTintColor = UIColor.white
        progressSlider.maximumTrackTintColor = UIColor(white: 1, alpha: 0.3)
        progressSlider.value = 0.0
        //滑块滑动中也可以监听
        progressSlider.isContinuous = true
        
        timeLabel = UILabel(frame: CGRect(x: progressSlider.frame.minX, y: barHeight - 20, width: progressSlider.frame.width, height: 20))
        timeLabel.textAlignment = .right
        timeLabel.font = UIFont.systemFont(ofSize: 10)
        timeLabel.backgroundColor = UIColor.clear
        timeLabel.textColor = UIColor.white
        
        indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
        
        backButton = UIButton(frame: CGRect(x: margin, y: marginTop, width: barHeight, height: barHeight))
        backButton.setImage(UIImage(named: "zx-video-banner-back"), for: .normal)
        
        lockButton = UIButton(frame: fullScreenButton.frame)
        lockButton.setImage(UIImage(named: "zx-video-player-unlock"), for: .normal)
        lockButton.setImage(UIImage(named: "zx-video-player-lock"), for: .highlighted)
        lockButton.setImage(UIImage(named: "zx-video-player-lock"), for: .selected)
        
        bufferProgressView = UIProgressView(progressViewStyle: .default)
        bufferProgressView.progressTintColor = UIColor(white: 1, alpha: 0.6)
        bufferProgressView.trackTintColor = UIColor.clear
        
        titleLabel = UILabel(frame: timeLabel.frame)
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.textColor = UIColor.white
        titleLabel.textAlignment = .center
        
        timeIndicatorView = TimeIndicatorView(frame: CGRect(x: 0, y: 0, width: 90, height: 70))
        timeIndicatorView.layer.cornerRadius = 5
        timeIndicatorView.layer.masksToBounds = true
        timeIndicatorView.alpha = 0
        
        tipView = UILabel(frame: CGRect(x: 0, y: 0, width: frame.width, height: 40))
        tipView.backgroundColor = UIColor.clear
        tipView.textColor = UIColor.white
        tipView.textAlignment = .center
        tipView.isHidden = true
        self.addSubview(tipView)
        
        juhua = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        
        juhua.bounds = CGRect(x: 0, y: 0, width: 40, height: 40)
        
        centerPlayPauseBtn = UIButton()
        centerPlayPauseBtn?.bounds = CGRect(x: 0, y: 0, width: 80, height: 80)
        centerPlayPauseBtn?.addTarget(self, action: #selector(VideoPlayerControlView.ac_play(sender:)), for: .touchUpInside)
        
        centerPlayPauseBtn?.isHidden = false
        centerPlayPauseBtn?.adjustsImageWhenHighlighted = false
        centerPlayPauseBtn?.imageView?.isHidden = false
        juhua.startAnimating()
        
        let mpVolumeView = MPVolumeView()
        for view in mpVolumeView.subviews {
            if NSStringFromClass(type(of: view)).contains("MPVolumeSlider") {
                self.volumeSlider = view as! UISlider
                self.volumeSlider.center = CGPoint(x: frame.width / 2, y: frame.height / 2)
                break
            }
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            NotificationCenter.default.addObserver(self, selector: #selector(VideoPlayerControlView.ac_listener(sender:)), name: NSNotification.Name.AVAudioSessionRouteChange, object: AVAudioSession.sharedInstance())
        } catch let err as NSError{
            print(err)
        }
        
        self.addSubview(topBar)
        self.addSubview(bottomBar)
        topBar.addSubview(backButton)
        topBar.addSubview(titleLabel)
        topBar.addSubview(lockButton)
        bottomBar.addSubview(playButton)
        bottomBar.addSubview(timeLabel)
        bottomBar.addSubview(fullScreenButton)
        //        bottomBar.addSubview(bufferProgressView)
        bottomBar.addSubview(progressSlider)
        self.addSubview(self.timeIndicatorView)
        self.addSubview(centerPlayPauseBtn!)
        
        self.addSubview(juhua)
        
        
        ///添加事件
        fullScreenButton.addTarget(self, action: #selector(VideoPlayerControlView.ac_changeFullScreen(sender:)), for: .touchUpInside)
        lockButton.addTarget(self, action: #selector(VideoPlayerControlView.ac_lock(sender:)), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(VideoPlayerControlView.ac_back(sender:)), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(VideoPlayerControlView.ac_play(sender:)), for: .touchUpInside)
        progressSlider.addTarget(self, action: #selector(VideoPlayerControlView.ac_progress(sender:)), for: .valueChanged)
        progressSlider.addTarget(self, action: #selector(VideoPlayerControlView.ac_progressDragEnd(sender:)), for: .touchUpInside)
        progressSlider.addTarget(self, action: #selector(VideoPlayerControlView.ac_progressDragEnd(sender:)), for: .touchUpInside)
        
        //滑动手势
        let pan = UIPanGestureRecognizer(target: self, action: #selector(VideoPlayerControlView.ac_pan(_:)))
        self.addGestureRecognizer(pan)
        
        //单击手势
        let tap = UITapGestureRecognizer(target: self, action: #selector(VideoPlayerControlView.ac_tap(_:)))
        addGestureRecognizer(tap)
        //双击手势
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(VideoPlayerControlView.ac_tap(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
        tap.require(toFail: doubleTap)
        
        //程序进入后台监听
        NotificationCenter.default.addObserver(self, selector: #selector(VideoPlayerControlView.ac_enterBackground), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VideoPlayerControlView.ac_enterPlayground), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        //定时器
        unowned let weakSelf = self
        timer = Timer.scheduledTimer(1, action: { (sender) in
            weakSelf.timerCount += 1
            if weakSelf.timerCount >= weakSelf.barFadeOutTimeInterval {
                weakSelf.timerCount = 0
                UIView.animate(withDuration: 0.5, animations: {
                    weakSelf.topBar.alpha = 0
                    weakSelf.bottomBar.alpha = 0
                    
                    if let de = weakSelf.delegate {
                        if de.shouldFullScreen(playerView: weakSelf) {
                            if weakSelf.isFullScreen {
                                UIApplication.shared.setStatusBarHidden(true, with: .fade)
                            }
                        }
                    } else {
                        if weakSelf.isFullScreen {
                            UIApplication.shared.setStatusBarHidden(true, with: .fade)
                        }
                    }
                    
                })
            }
        }, userInfo: nil, repeats: true)
        
    }
    
    // MARK: 视频进度监听
    func setupPlaerValue() {
        unowned let weakSelf = self
        
        if timeObserver != nil {
            self.player.removeTimeObserver(timeObserver!)
            timeObserver = nil
        }
        
        self.timeObserver = self.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: DispatchQueue.main, using: {(time) in
            let seekRanges = weakSelf.playerItem.seekableTimeRanges
            if seekRanges.count > 0 && weakSelf.playerItem.duration.timescale != 0 {
                
                if !weakSelf.progressSliderFocus {//防止同时更新
                    weakSelf.updateProgressSlider()
                    weakSelf.setTimeLableText()
                    weakSelf.juhua.stopAnimating()
                }
                
            }
            
        })
    }
    
    func updateProgressSlider() {
        let v = Float(CMTimeGetSeconds(self.playerItem.currentTime()) / Float64(self.playerItem.duration.value / Int64(self.playerItem.duration.timescale)))
        self.progressSlider.value = v
        
    }
    
    func setTimeLableText(by progress: Bool = false) {
        if self.playerItem == nil || self.playerItem.duration.timescale == 0 {
            return
        }
        var min = Int(CMTimeGetSeconds(self.playerItem.currentTime()) / 60) //当前分钟
        var sec = Int(CMTimeGetSeconds(self.playerItem.currentTime())) % 60 //当前秒
        
        let totalMin = Int(self.playerItem.duration.value / Int64(self.playerItem.duration.timescale) / 60)//总分钟
        let totalSec = Int(self.playerItem.duration.value / Int64(self.playerItem.duration.timescale) % 60)//总秒
        
        //更新
        if progress {
            let total = Float(self.playerItem.duration.value / Int64(self.playerItem.duration.timescale))
            min = Int(total * progressSlider.value / 60)
            sec = Int(total * progressSlider.value) % 60
        }
        
        let str = String(format: "%02zd:%02zd / %02zd:%02zd", min, sec, totalMin, totalSec)
        let attrStr = NSMutableAttributedString(string: str)
        let length = str.components(separatedBy: "/")[0].characters.count
        attrStr.addAttributes([NSForegroundColorAttributeName:UIColor.yellow], range: NSRange(location: 0, length: length))
        
        DispatchQueue.main.async {
            self.timeLabel.attributedText = attrStr
        }
        
        if let s = seekAction {
            s(self)
        }
        
        bufferProgressView.frame = progressSlider.bounds
        bufferProgressView.frame.origin.y += progressSlider.bounds.height / 2 - 1
        bufferProgressView.frame.size.width -= 4
        bufferProgressView.frame.origin.x = 2
        
        setupedTimeLabel = true
    }
    
    // MARK:player
    var player = AVPlayer()
    var playerLayer = AVPlayerLayer()
    var isPauseBySystem = false
    var playerItem: AVPlayerItem! {
        didSet {
            if playerItem != oldValue {
                if oldValue != nil {
                    //监听播放进度是否完成
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: oldValue)
                    
                    oldValue.removeObserver(self, forKeyPath: "status")
                    oldValue.removeObserver(self, forKeyPath: "loadedTimeRanges")
                    oldValue.removeObserver(self, forKeyPath: "playbackBufferEmpty")
                    oldValue.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
                }
                
                NotificationCenter.default.addObserver(self, selector: #selector(VideoPlayerControlView.ac_playEnd(sender:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
                
                playerItem.addObserver(self, forKeyPath: "status", options: .new, context: nil)
                playerItem.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
                playerItem.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
                playerItem.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
            }
        }
    }
    
    //MARK: 初始化播放器
    func setupPlayer(url: URL) {
        //在不缓冲的情况下计算时长
        //        let urlAsset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey:false])
        //        var allSec = Int32(urlAsset.duration.value) / urlAsset.duration.timescale
        //        let totalMin = Int(allSec / 60)//总分钟
        //        let totalSec = Int(allSec % 60)//总秒
        //
        //        let str = String(format: "00:00 / %02zd:%02zd", totalMin, totalSec)
        //        let attrStr = NSMutableAttributedString(string: str)
        //        let length = str.components(separatedBy: "/")[0].characters.count
        //        attrStr.addAttributes([NSForegroundColorAttributeName:UIColor.yellow], range: NSRange(location: 0, length: length))
        //
        //        DispatchQueue.main.async {
        //            self.timeLabel.attributedText = attrStr
        //        }
        
        self.progressSlider.value = 0
        self.pausePlayer(pause: true)
        
        
        if timeObserver != nil {
            self.player.removeTimeObserver(timeObserver!)
            timeObserver = nil
        }
        
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        let layer = AVPlayerLayer(player: self.player)
        layer.frame = bounds
        layer.backgroundColor = UIColor.black.cgColor
        
        self.layer.insertSublayer(layer, below: topBar.layer)
        
        player.volume = 1.0
        playerLayer = layer
        
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        self.setupPlaerValue()
        
        let str = "00:00/00:00"
        let attrStr = NSMutableAttributedString(string: str)
        let length = str.components(separatedBy: "/")[0].characters.count
        attrStr.addAttributes([NSForegroundColorAttributeName:UIColor.yellow], range: NSRange(location: 0, length: length))
        self.timeLabel.attributedText = attrStr
    }
    
    var setupedTimeLabel = false
    var setupedProgress = false
    // MARK: 监听
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let obj = object as? AVPlayerItem, let keyP = keyPath, obj == self.player.currentItem {
            switch keyP {
            case "status":
                if self.player.currentItem?.status == .failed {
                    tipView.text = "视频加载失败"
                    tipView.isHidden = false
                    self.bringSubview(toFront: tipView)
                } else {
                    tipView.isHidden = true
                    seekTo()
                }
            case "loadedTimeRanges":
                if !setupedTimeLabel {
                    self.setTimeLableText(by: true)
                    progressSlider.value = Float(timePercent)
                    
                    ///
                    if progressSlider.subviews.count > 0 {
                        bufferProgressView.frame = progressSlider.bounds
                        bufferProgressView.frame.origin.y += progressSlider.bounds.height / 2 - 1
                        bufferProgressView.frame.size.width -= 4
                        bufferProgressView.frame.origin.x = 2
                        let arr = progressSlider.subviews
                        progressSlider.insertSubview(bufferProgressView!, belowSubview: arr[arr.count - 2])
                    }
                }
                
                if let loadedRanges = player.currentItem?.loadedTimeRanges, let timeRange = loadedRanges.first?.timeRangeValue {
                    let start = CMTimeGetSeconds(timeRange.start)
                    let duration = CMTimeGetSeconds(timeRange.duration)
                    let timeInterval = start + duration
                    
                    let totalDuration = CMTimeGetSeconds(playerItem.duration)
                    bufferProgressView.setProgress(Float(timeInterval / totalDuration), animated: false)
                    // 缓冲和进度条的值超过0.05自动播放
                    //                    if isPauseBySystem && !didEnterBackground && bufferProgressView.progress - progressSlider.value > 0.05 {
                    //                        buffEnd = true
                    //                        ac_play(sender: playButton)
                    //                        if let p = playAction {
                    //                            unowned let ws = self
                    //                            p(ws)
                    //                        } else {
                    //                            juhua.stopAnimating()
                    //                        }
                    //                    } else {
                    //                        if bufferProgressView.progress - progressSlider.value > 0.05 {
                    //                            buffEnd = true
                    ////                            if let p = playAction {
                    ////                                unowned let ws = self
                    ////                                p(ws)
                    ////                            } else {
                    ////                                juhua.stopAnimating()
                    ////                            }
                    //
                    //                            juhua.stopAnimating()
                    //                        } else {
                    //                            buffEnd = false
                    //                            if let b = buffingAction {
                    //                                unowned let ws = self
                    //                                b(ws)
                    //                            } else {
                    //                                juhua.startAnimating()
                    //                            }
                    //                        }
                    //                    }
                }
            case "playbackBufferEmpty":
                if self.playerItem.isPlaybackBufferEmpty {
                    self.playButton.isSelected = false
                    self.player.pause()
                    isPauseBySystem = true
                    
                    if let b = buffingAction {
                        unowned let ws = self
                        b(ws)
                    } else {
                        juhua.isHidden = false
                        juhua.startAnimating()
                    }
                }
            case "playbackLikelyToKeepUp":
                if playerItem.isPlaybackLikelyToKeepUp {
                    if !setupedProgress {
                        progressSlider.value = Float(timePercent)
                        //                        seekTo()
                        setupedProgress = true
                    }
                    
                    buffEnd = true
                    if isPauseBySystem {
                        ac_play(sender: playButton)
                        isPauseBySystem = false
                        if let de = delegate {
                            if !de.shouldPlay(playerView: self) {
                                return
                            }
                        }
                        self.player.play()
                        self.playButton.isSelected = true
                    }
                    
                    if let p = playAction {
                        unowned let ws = self
                        p(ws)
                    }
                    
                    juhua.stopAnimating()
                }
                
            default:
                break
            }
        }
    }
    
    //    override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutableRawPointer) {
    //
    //    }
    
    
    
    
    override class func initialize() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }
    
    func setupSetings() {
        NotificationCenter.default.addObserver(self, selector: #selector(VideoPlayerControlView.deviceOrientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    //MARK: 添加到 顶层，返回时还原
    weak var topView: UIView?
    private var oldStateBarStyle = UIApplication.shared.statusBarStyle
    //MARK: 全屏切换
    func deviceOrientationDidChange() {
        if let de = delegate {
            if !de.shouldFullScreen(playerView: self) {
                return
            }
        }
        
        if self.superview == nil {
            return
        }
        
        if origenalFrame == CGRect.zero {
            origenalFrame = frame
        }
        
        if topView == nil {
            if let sv = self.superview {
                topView = sv
            }
        }
        
        if !lockButton.isSelected {
            switch UIDevice.current.orientation {
                
            case .portrait:
                UIApplication.shared.setStatusBarStyle(oldStateBarStyle, animated: true)
                self.removeFromSuperview()
                
                topView?.addSubview(self)
                self.fullScreenButton.isSelected = false
                
                UIApplication.shared.setStatusBarHidden(false, with: .fade)
                isFullScreen = false
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                if changeDirByTransform {
                    self.transform = CGAffineTransform.identity
                }
                self.frame = self.origenalFrame
                
            case .landscapeLeft, .landscapeRight:
                if let de = delegate {
                    if !de.shouldFullScreen(playerView: self) {
                        return
                    }
                }
                
                let f = self.convert(UIScreen.main.bounds, to: nil)
                if !canFullScreen || f.origin.y < -origenalFrame.height {
                    return
                }
                
                isFullScreen = true
                
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
                
                UIApplication.shared.setStatusBarHidden(topBar.alpha < 0.2, with: .fade)
                
                self.removeFromSuperview()
                
                if changeDirByTransform {
                    UIApplication.shared.setStatusBarHidden(true, with: .fade)
                    let w = UIScreen.main.bounds.width
                    let h = UIScreen.main.bounds.height
                    if UIDevice.current.orientation == .landscapeRight {
                        self.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
                    } else {
                        self.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
                    }
                    self.center = CGPoint(x: h / 2, y: w / 2)
                }
                self.frame = UIScreen.main.bounds
                
                self.fullScreenButton.isSelected = true
                if let bv = bottomView {
                    bv.addSubview(self)
                } else {
                    UIApplication.shared.keyWindow?.addSubview(self)
                }
                
            default:
                break
            }
        }
        
        if let de = delegate {
            de.didChangeRoate(playerView: self)
        }
        
        layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if canLayoutByCustom {//是否自己布局
            return
        }
        playerLayer.frame = bounds
        let margin: CGFloat = bounds.width > 400 ? 40 : 0
        let marginTop: CGFloat = 0
        
        //防止iphone x 无法点击
        let marginX: CGFloat = 0//bounds.width > 400 ? 40 : 0
        let toolbarW = bounds.width //> 400 ? bounds.width - marginX * 2 : bounds.width
        
        topBar.frame = CGRect(x: marginX, y: 0, width: toolbarW, height: barHeight)
        bottomBar.frame = CGRect(x: marginX, y: bounds.height - barHeight, width: toolbarW, height: barHeight)
        playButton.frame = CGRect(x: margin, y: 0, width: barHeight, height: barHeight)
        fullScreenButton.frame = CGRect(x: toolbarW - margin - barHeight, y: 0, width: barHeight, height: barHeight)
        progressSlider.frame = CGRect(x: playButton.frame.maxX, y: 0, width: toolbarW - playButton.frame.maxX * 2, height: barHeight)
        titleLabel.frame = CGRect(x: progressSlider.frame.minX, y: barHeight - 20, width: progressSlider.bounds.width, height: 20)
        indicatorView.center = self.center
        backButton.frame = CGRect(x: margin, y: marginTop, width: barHeight, height: barHeight)
        lockButton.frame = fullScreenButton.frame
        
        titleLabel.frame = timeLabel.frame
        titleLabel.center.y += marginTop
        lockButton.center.y += marginTop
        
        tipView.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        juhua.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        centerPlayPauseBtn?.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        
        if !lockButton.isSelected {
            //            if UIDevice.current.orientation != .portraitUpsideDown {
            //                centerPlayPauseBtn?.transform = CGAffineTransform(scaleX: 2, y: 2)
            //            } else {
            //                centerPlayPauseBtn?.transform = CGAffineTransform.identity
            //            }
        }
        timeLabel.frame = CGRect(x: progressSlider.frame.minX, y: barHeight - 20, width: progressSlider.frame.width, height: 20)
        self.timeIndicatorView.center = CGPoint(x: frame.width / 2, y: frame.height / 2)
    }
    
    private func pausePlayer(pause: Bool) {
        if let de = delegate {
            if !de.shouldPlay(playerView: self) {
                return
            }
        }
        playButton.isSelected = !pause
        if pause {
            player.pause()
        } else {
            if isPlayEnd {
                progressSlider.value = 0
                seekTo()
                isPlayEnd = false
            }
            player.play()
        }
        //        self.bringSubview(toFront: centerPlayPauseBtn!)
    }
    
    
    func play(notPause: Bool) {
        centerPlayPauseBtn?.isHidden = notPause
        pausePlayer(pause: !notPause)
    }
    
    //MARK: 事件
    func ac_enterBackground() {
        didEnterBackground = true
        //        pausePlayer(pause: true)
        if !allowPlayInBackground && playButton.isSelected {
            ac_play(sender: self.playButton)
        }
    }
    
    func ac_enterPlayground() {
        didEnterBackground = false
    }
    
    func ac_changeFullScreen(sender: UIButton) {
        
        if let de = delegate {
            if !de.shouldFullScreen(playerView: self) {
                return
            }
        }
        
        if lockButton.isSelected {
            return
        }
        sender.isSelected = !sender.isSelected
        
        var value = fullScreenButton.isSelected ? UIInterfaceOrientation.landscapeLeft.rawValue : UIInterfaceOrientation.portrait.rawValue
        
        UIDevice.current.setValue(value, forKey: "orientation")
    }
    
    func ac_lock(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if let de = delegate {
            de.didLocked(locked: sender.isSelected)
        }
    }
    
    func ac_back(sender: UIButton) {
        if lockButton.isSelected {
            return
        }
        let o = UIDevice.current.orientation
        isPortraitByUser = true
        if o == .landscapeLeft || o == .landscapeRight {
            self.frame = self.origenalFrame
            
            if (fullScreenButton.isSelected) {
                fullScreenButton.isSelected = false
                let value = UIInterfaceOrientation.portrait.rawValue
                UIDevice.current.setValue(value, forKey: "orientation")
            }
            return
        }
        if whenBack != nil {
            whenBack!(backButton)
        }
    }
    
    func ac_play(sender: UIButton) {
        UIView.animate(withDuration: 0.3, animations: {
            self.timeIndicatorView.alpha = 0
        })
        
        if isPlayEnd {
            progressSlider.value = 0
            seekTo()
            isPlayEnd = false
        }
        
        if let de = delegate {
            if !de.shouldPlay(playerView: self) {
                return
            }
        }
        
        playButton.isSelected = !playButton.isSelected
        if playButton.isSelected {
            player.play()
        } else {
            player.pause()
            isPauseBySystem = false
        }
        centerPlayPauseBtn?.isHidden = playButton.isSelected
        timerCount = 0
        //        self.bringSubview(toFront: centerPlayPauseBtn!)
    }
    
    func ac_progress(sender: UISlider) {
        //        seekTo()
        player.pause()
        setTimeLableText(by: true)
        progressSliderFocus = true
        timerCount = 0
        if playLoop && self.progressSlider.value > 0.99 {
            self.progressSlider.value = 0.0
            self.seekTo()
            self.player.play()
        }
    }
    
    func seekTo() {
        
        if self.playerItem != nil && self.playerItem.duration.timescale > 0 {
            let total = Float(self.playerItem.duration.value / Int64(self.playerItem.duration.timescale))
            var dragedTime: CMTime!
            
            dragedTime = CMTime(seconds: Double(self.progressSlider.value * total), preferredTimescale: 1)
            
            player.seek(to: dragedTime, toleranceBefore: kCMTimeZero, toleranceAfter: dragedTime)
            
            if player.currentItem?.status == .readyToPlay {
                
                
                
            }
        }
    }
    
    func ac_progressDragEnd(sender: UISlider) {
        let v = sender.value
        seekTo()
        
        sender.value = v
        if self.playButton.isSelected {
            pausePlayer(pause: false)
        }
        
        progressSliderFocus = false
        
        UIView.animate(withDuration: 0.3, animations: {
            self.timeIndicatorView.alpha = 0
        })
        
        if sender.value >= 1 {
            isPlayEnd = true
            pausePlayer(pause: true)
        } else {
            isPlayEnd = false
        }
    }
    
    func ac_listener(sender: Notification) {
        //耳机
        let dic = sender.userInfo
        if let a = dic?[AVAudioSessionRouteChangeReasonKey] as? NSNumber {
            let changeReason = a.intValue
            switch AVAudioSessionRouteChangeReason(rawValue: UInt(changeReason)) {
            case AVAudioSessionRouteChangeReason.newDeviceAvailable?://耳机插入
                break
                
            case AVAudioSessionRouteChangeReason.oldDeviceUnavailable?://耳机拔掉
                self.play(notPause: false)
                break
                
            default:
                break
            }
        }
        
    }
    
    func ac_playEnd(sender: Notification) {
        if playLoop {
            self.progressSlider.value = 0.0
            self.seekTo()
            self.player.play()
        } else {
            self.playButton.isSelected = false
            isPlayEnd = true
            self.pausePlayer(pause: true)
        }
    }
    
    var panDirection: PanDirection = .horizontal
    //Mark: 手势
    func ac_pan(_ sender: UIPanGestureRecognizer) {
        if let de = delegate {
            if !de.canUseGesture(playerView: self) {
                return
            }
        }
        
        //没有加载完成不允许使用手势
        if self.player.currentItem?.status != .readyToPlay {
            return
        }
        
        let location = sender.location(in: self) // 坐标
        let velocity = sender.velocity(in: self) // 速度
        let translation = sender.translation(in: self)//相对
        sender.setTranslation(CGPoint.zero, in: self)
        
        switch sender.state {
        case .began:
            progressSliderFocus = true
            let x = fabs(velocity.x)
            let y = fabs(velocity.y)
            
            if x > y {
                self.panDirection = .horizontal
                self.timeIndicatorView.alpha = 1
            } else {
                self.panDirection = .vertical
            }
            self.timer?.fireDate = NSDate.distantFuture
            
        case .changed:
            switch self.panDirection {
            case .horizontal:
                moveHorizontal(translation.x)
                
            case .vertical:
                if location.x > frame.width / 2 {
                    self.volumeSlider.value -= Float(translation.y / frame.height)
                } else {
                    UIScreen.main.brightness -= CGFloat(translation.y / frame.height)
                }
            }
            
        case .ended:
            progressSliderFocus = false
            if self.panDirection == .horizontal {
                self.ac_progressDragEnd(sender: self.progressSlider)
            } else {
                if location.x < frame.width / 2 {
                    UIView.animate(withDuration: 0.8, animations: {
                        BrightnessView.shared.alpha = 0
                    })
                }
            }
            self.timeIndicatorView.alpha = 0
            self.timer?.fireDate = NSDate.distantPast
            
        default:
            break
        }
    }
    
    func ac_tap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: self)
        if topBar.frame.contains(location) || bottomBar.frame.contains(location) {
            timerCount = 0
            if self.topBar.alpha < 0.2 {
                UIView.animate(withDuration: 0.5, animations: {
                    self.topBar.alpha = 1
                    self.bottomBar.alpha = 1
                    self.timer?.fireDate = NSDate.distantPast
                    if self.isFullScreen {
                        UIApplication.shared.setStatusBarHidden(true, with: .fade)
                    }
                })
            }
        } else {
            if sender.numberOfTapsRequired == 1 {
                timerCount = 0
                if isFullScreen {
                    UIApplication.shared.setStatusBarHidden(self.topBar.alpha > 0.6, with: .fade)
                }
                
                UIView.animate(withDuration: 0.5, animations: {
                    if self.topBar.alpha > 0.6 {
                        self.topBar.alpha = 0
                        self.bottomBar.alpha = 0
                        self.timer?.fireDate = NSDate.distantFuture
                    } else {
                        self.topBar.alpha = 1
                        self.bottomBar.alpha = 1
                        self.timer?.fireDate = NSDate.distantPast
                    }
                })
            } else if sender.numberOfTapsRequired == 2 {
                ac_play(sender: self.playButton)
            }
        }
        
    }
    
    func ac_doubleTap(_ sender: UITapGestureRecognizer) {
        //ac_play(sender: self.playButton)
    }
    
    func moveHorizontal(_ x: CGFloat) {
        timeIndicatorView.indicatorState = x < 0 ? .rewind : .forward
        timeIndicatorView.textLabel.attributedText = timeLabel.attributedText
        progressSlider.value += Float(x / frame.width)
        seekTo()
        //print(x.description + "   " + Float(x / frame.width).description)
    }
    
    
    // MARK: 清理
    func clear() {
        self.timer?.invalidate()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        if playerItem != nil {
            playerItem.removeObserver(self, forKeyPath: "status")
            playerItem.removeObserver(self, forKeyPath: "loadedTimeRanges")
            playerItem.removeObserver(self, forKeyPath: "playbackBufferEmpty")
            playerItem.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        }
        if let to = timeObserver {
            self.player.removeTimeObserver(to)
        }
        clear()
    }
    
    
    
    //--------------------------------------
    
    // MARK: 一些其他的view组件
    ///时间进度
    private class TimeIndicatorView: UIView {
        enum IndicatorState {
            case rewind
            case forward
        }
        
        static let autoFadeOutTime = 1.0
        var textLabel: UILabel!
        var stateImageView: UIImageView!
        var indicatorState: IndicatorState = .forward {
            didSet {
                stateImageView.image = UIImage(named: indicatorState == .rewind ? "zx-video-player-rewind" : "zx-video-player-fastForward")
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupUI()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            setupUI()
        }
        
        func setupUI() {
            self.backgroundColor = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.3)
            
            let imgMargin: CGFloat = 15.0
            let imgW: CGFloat = 45
            stateImageView = UIImageView(frame: CGRect(x: (frame.width - imgW) / 2, y: imgMargin, width: imgW, height: 25))
            
            textLabel = UILabel(frame: CGRect(x: 0, y: stateImageView.frame.maxY + 10, width: frame.width, height: 12))
            textLabel.font = UIFont.systemFont(ofSize: 12)
            textLabel.textAlignment = .center
            textLabel.textColor = UIColor.white
            
            self.addSubview(stateImageView)
            self.addSubview(textLabel)
        }
        
    }
    
    // MARK: 亮度
    fileprivate class BrightnessView: UIView {
        var backImage: UIImageView!
        var titleLabel: UILabel!
        var longView: UIView!
        
        fileprivate override init(frame: CGRect) {
            super.init(frame: frame)
            setupUI()
        }
        
        fileprivate required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            setupUI()
        }
        
        static var shared: BrightnessView = {
            let view = BrightnessView()
            return view
        }()
        
        func setupUI() {
            window?.addSubview(BrightnessView.shared)
            let screenW = UIScreen.main.bounds.width
            let screenH = UIScreen.main.bounds.height
            self.frame = CGRect(x: screenW / 2 - 78, y: screenH / 2 - 78, width: 156, height: 156)
            self.layer.cornerRadius = 10
            self.layer.masksToBounds = true
            
            let toolbar = UIToolbar(frame: self.bounds)
            toolbar.alpha = 0.97
            self.addSubview(toolbar)
            
            backImage = UIImageView(frame: CGRect(x: (frame.width - 79) / 2, y: (frame.height - 76) / 2, width: 79, height: 76))
            backImage.image = UIImage(named: "ZFPlayer_brightness")
            self.addSubview(backImage)
            
            titleLabel = UILabel(frame: CGRect(x: 0, y: 5, width: bounds.width, height: 30))
            titleLabel.font = UIFont.systemFont(ofSize: 16)
            titleLabel.textColor = UIColor.black
            titleLabel.textAlignment = .center
            titleLabel.text = "亮度"
            self.addSubview(titleLabel)
            
            longView = UIView(frame: CGRect(x: 13, y: 132, width: bounds.width - 26, height: 7))
            longView.backgroundColor = UIColor(colorLiteralRed: 0.25, green: 0.22, blue: 0.21, alpha: 1)
            self.addSubview(longView)
            
            let tipW = (longView.frame.width - 17) / 16
            let tipH = CGFloat(5)
            let tipY = CGFloat(1)
            for i in 0 ..< 16 {
                let index = CGFloat(i)
                let tipX = index * (tipW + 1) + 1
                let view = UIView(frame: CGRect(x: tipX, y: tipY, width: tipW, height: tipH))
                view.backgroundColor = UIColor.white
                longView.addSubview(view)
            }
            
            UIScreen.main.addObserver(self, forKeyPath: "brightness", options: .new, context: nil)
        }
        
        static var addedView = false
        //        fileprivate override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?) {
        //
        //
        //        }
        
        fileprivate override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if !BrightnessView.addedView {
                BrightnessView.addedView = true
                UIApplication.shared.keyWindow?.addSubview(BrightnessView.shared)
            }
            
            if let brightness = change?[NSKeyValueChangeKey(rawValue: "new")] as? CGFloat {
                showSoundView()
                updateLongView(brightness)
            }
        }
        
        func showSoundView() {
            self.center = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
            if (alpha == 0) {
                alpha = 1.0
            }
        }
        
        func hideSoundView() {
            if self.alpha == 1.0 {
                UIView.animate(withDuration: 0.8, animations: {
                    self.alpha = 0.0
                    
                })
            }
        }
        
        func updateLongView(_ brightness: CGFloat) {
            let level = Int(brightness * 16)
            for i in 0 ..< 16 {
                if i >= level {
                    longView.subviews[i].isHidden = true
                } else {
                    longView.subviews[i].isHidden = false
                }
            }
        }
        
        deinit {
            BrightnessView.shared.alpha = 0
            UIScreen.main.removeObserver(self, forKeyPath: "brightness")
        }
    }
    
}













