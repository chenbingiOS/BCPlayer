//
//  ViewPlayerView.swift
//  BCPlayer
//
//  Created by mtAdmin on 2021/2/2.
//

import UIKit
import AVFoundation

open class VideoPlayerView: UIView {
    /// 管理播放器视觉输出的对象
    let playerLayer = AVPlayerLayer()
    /// 当前正在播放的网址
    public private(set) var playerURL: URL?
    /// 播放器
    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
    
    //----------------------------------------
    /// 是否加载
    var isLoaded = false
    /// 视频的状态
    public enum State {
        /// 无
        case none
        /// 加载中 ，从第一次加载开始获得视频的第一帧
        case loading
        /// 播放中
        case playing
        /// 暂停，当缓冲区进度更改时将反复调用
        case paused
        /// 错误
        case error
    }
    /// 获取当前视频状态
    public private(set) var state: State = .none {
        // 计算属性，在state发生变化后，进行后续操作
        didSet { stateDidChange(state: state, previous: oldValue) }
    }
    /// 播放状态外部回掉，例如从 playing -> paused
    public var stateDidChanged: ((State) -> Void)?
    //----------------------------------------
    /// 是否重播
    var isReplay = false
    /// 暂停理由
    public enum PausedReason {
        /// 等待资源完成缓冲，默认行为
        case waitingKeepUp
        /// 由用户互动触发的暂停
        case userInteraction
        /// 因为播放器不可见而暂停，所以当缓冲区进度更改时，不会调用stateDidChanged
        case hidden
    }
    /// 视频暂停的原因，默认为等待资源缓存
    var pausedReason: PausedReason = .waitingKeepUp
    //----------------------------------------
    // KVO
    /// 播放器层已准备好进行显示
    private var playerLayerReadyForDisplayObservation: NSKeyValueObservation?
    /// 播放器时间控制状态
    private var playerTimeControlStatusObservation: NSKeyValueObservation?
    /// 播放器缓冲
    private var playerBufferingObservation: NSKeyValueObservation?
    /// 播放载体缓冲状态
    private var playerItemKeepUpObservation: NSKeyValueObservation?
    /// 播放载体状态
    private var playerItemStatusObservation: NSKeyValueObservation?
    //----------------------------------------
    public init() {
        super.init(frame: .zero)
        setupInit()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupInit()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        guard playerLayer.superlayer == layer else {
            return
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }
}

private extension VideoPlayerView {
    /// 初始化
    func setupInit() {
        // 默认隐藏
        isHidden = true
        
        // 播放播放状态监听
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd(notification:)),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: nil)
        
        layer.addSublayer(playerLayer)
    }
    
    @objc func playerItemDidReachEnd(notification: Notification) {
        
    }
    
    /// 播放状态改变
    /// - Parameters:
    ///   - state: 当前状态
    ///   - previous: 之前状态
    func stateDidChange(state: State, previous: State) {
        // 状态相同不改变
        if state == previous { return }
        
        switch state {
        case .playing, .paused: isHidden = false // 播放中，暂停，播放容器不隐藏
        default:                isHidden = true   // 其他状态隐藏
        }
     
        // 播放状态回掉外部
        stateDidChanged?(state)
    }
    
    /// 播放器监听初始化
    func observe(player: AVPlayer?) {
        guard let player = player else {
            playerLayerReadyForDisplayObservation = nil
            playerTimeControlStatusObservation = nil
            return
        }
        
        /*
         内存泄漏的解决
         [weak self] 与 [unowned self] 介绍
         我们只需将闭包捕获列表定义为弱引用（weak）、或者无主引用（unowned）即可解决问题
         这二者的使用场景分别如下：
         如果捕获（比如 self）可以被设置为 nil，也就是说它可能在闭包前被销毁，那么就要将捕获定义为 weak。
         如果它们一直是相互引用，即同时销毁的，那么就可以将捕获定义为 unowned
         */
        // playerLayerReadyForDisplayObservation 和  playerLayer 是相互引用
        // 播放器层已准备好进行显示
        playerLayerReadyForDisplayObservation = playerLayer.observe(\.isReadyForDisplay) { [unowned self] playerLayer, _ in
            // 开始播放，状态转入播放中
            if playerLayer.isReadyForDisplay, player.rate > 0 {
                self.isLoaded = true
                self.state = .playing
            }
        }
        
        // 播放器时间控制状态
        playerTimeControlStatusObservation = player.observe(\.timeControlStatus) { [unowned self] player, _ in
            switch player.timeControlStatus {
            case .paused:
                // 不是重播
                guard !self.isReplay else { break }
                // 播放状态：暂停
                self.state = .paused
                // 播放原因：等待资源加载，则视频进行加载
                if self.pausedReason == .waitingKeepUp  {
                    player.play()
                }
            case .waitingToPlayAtSpecifiedRate:
                break
            case .playing:
                // 播放中
                if self.playerLayer.isReadyForDisplay, player.rate > 0 {
                    // 是加载
                    self.isLoaded = true
                    //todo 判断播放进度
                    // 状态：播放中
                    self.state = .playing
                }
            @unknown default:
                break
            }
        }
    }
    
    /// 播放载体监听初始化
    func observe(playerItem: AVPlayerItem?) {
        guard let playerItem = playerItem else {
            playerBufferingObservation = nil
            playerItemStatusObservation = nil
            playerItemKeepUpObservation = nil
            return
        }
        // 播放器缓冲
        playerBufferingObservation = playerItem.observe(\.loadedTimeRanges) { [unowned self] item, _ in
            if self.state == .paused, self.pausedReason != .hidden {
                self.state = .paused
            }
        }
        
        // 播放载体状态
        playerItemStatusObservation = playerItem.observe(\.status) { [unowned self] item, _ in
            // 播放错误
            if item.status == .failed, let error = item.error as NSError? {
                self.state = .error
                print(error)
            }
        }
        
        // 播放载体缓冲状态
        playerItemKeepUpObservation = playerItem.observe(\.isPlaybackLikelyToKeepUp) { [unowned self] item, _ in
            if item.isPlaybackLikelyToKeepUp {
                if self.player?.rate == 0, self.pausedReason == .waitingKeepUp {
                    self.player?.play()
                }
            }
        }
    }
}

/// 对外暴露方法
@objc extension VideoPlayerView {
    
    /// 播放指定网址的视频
    /// - Parameter url: 可以是本地或远程URL
    open func play(for url: URL) {
        
        guard playerURL != url else {
            pausedReason = .waitingKeepUp
            player?.play()
            return
        }
        
        // 移除播放器状态监听
        observe(player: nil)
        observe(playerItem: nil)
        
        let playerItem = AVPlayerItem(url: url)
        // 指示播放器项在暂停时是否可以使用网络资源来使播放状态保持最新
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true

        let player = AVPlayer()
        // 指示播放器是否应自动延迟播放以最小化停顿
        player.automaticallyWaitsToMinimizeStalling = false
        player.replaceCurrentItem(with: playerItem)
        
        self.player = player
        self.playerURL = url
        pausedReason = .waitingKeepUp
        isLoaded = false
        
        state = .loading
        
        // 添加播放器状态监听
        observe(player: player)
        observe(playerItem: playerItem)
    }
}
