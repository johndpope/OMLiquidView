//
//  WaveDataGenerator.swift
//  Pods
//
//  Created by HuangKun on 2017/1/5.
//
//

import Foundation



public struct WaveNode {
    
    public enum PeakAndNadir {
        case equal(value: CGFloat)
        case notEqual(peak: CGFloat, nadir: CGFloat)
    }
    
    public enum PNUpdateStyle {
        case const
        case random(min: Int)
    }
    
    public enum WaveDirection: Int {
        case up = 0
        case down
        
        static func random() -> WaveDirection {
            return WaveDirection(rawValue: Int(arc4random() % 1))!
        }
        
        func inverse() -> WaveDirection {
            if case .up = self { return .down }
            if case .down = self { return .up }
            return .up
        }
    }
    
    public struct Configuration: Options {
        
        public var peakAndNadir: PeakAndNadir = .equal(value: 15)
        public var updateStyle: PNUpdateStyle = .random(min: 70)
        public var nodeSegment: CGFloat = 360
        public var verticalAnimationDuration: TimeInterval = 6
        public var horizontalAnimationDuration: TimeInterval = 3
        public var initialDirction: WaveDirection = WaveDirection.random()
    
        public typealias OptionStruct = Configuration
        public init() {}
    }
    
    let peak: CGFloat
    let nadir: CGFloat
    let nodeSegment: CGFloat
    var direction: WaveDirection
    var currentAltitude: CGFloat = 0 {
        didSet {
            if currentAltitude >= _currentPeak {
                direction = .down
            }
            
            if currentAltitude <= -_currentNadir {
                direction = .up
            }
        }
    }
    var currentTranslation: CGFloat = 0
    var altitudeRatio: CGFloat {
        return currentAltitude / _currentRefDistance
    }
    
    fileprivate let _updateStyle: PNUpdateStyle
    fileprivate let _verticalTimeinterval: TimeInterval
    fileprivate let _horizontalTimeinterval: TimeInterval
    fileprivate var _currentPeak: CGFloat = 0
    fileprivate var _currentNadir: CGFloat = 0
    fileprivate var _currentRefDistance: CGFloat {
        var distance: CGFloat = 0
        
        if currentAltitude > 0 {
            distance = _currentPeak
        }
        
        if currentAltitude < 0 {
            distance = _currentNadir
        }
        
        if currentAltitude == 0 {
            switch direction {
            case .up:
                distance = _currentPeak
            case .down:
                distance = _currentNadir
            }
        }
        
        return distance
    }
    fileprivate var _verticalTPF: CGFloat {
        var distance: CGFloat = _currentRefDistance
        let min1 = -0.2 * distance
        let max1 = 0.2 * distance
        
        let min2 = -0.4 * distance
        let max2 = 0.4 * distance
        
        if currentAltitude > min1 && currentAltitude < max1 {
            return distance / (20 * CGFloat(self._verticalTimeinterval))
        }
        
        if currentAltitude > min2 && currentAltitude < max2 {
            return distance / (40 * CGFloat(self._verticalTimeinterval))
        }
        
        return distance / (60 * CGFloat(self._verticalTimeinterval))
    }
    
    fileprivate lazy var _horizontalTPF: CGFloat = {
        return self.nodeSegment / (60 * CGFloat(self._horizontalTimeinterval))
    }()
    
    public init(configuration: Configuration = Configuration()) {
        switch configuration.peakAndNadir {
        case .equal(let value):
            peak = value
            nadir = value
        case .notEqual(let p, let n):
            peak = p
            nadir = n
        }
        _updateStyle = configuration.updateStyle
        nodeSegment = configuration.nodeSegment
        _verticalTimeinterval = configuration.verticalAnimationDuration
        _horizontalTimeinterval = configuration.horizontalAnimationDuration
        direction = configuration.initialDirction
        
    }
    
    mutating func currentAltitude(with ratio: CGFloat) {
        currentAltitude = ratio * _currentRefDistance
    }
    
    mutating func updatePeakAndNadir() {
        var delta: CGFloat = 1
        switch _updateStyle {
        case .random(let min):
            delta = 1 - CGFloat(arc4random() % (100 - UInt32(min)) / 100)
        case .const:
            break
        }
        _currentNadir = nadir * delta
        _currentPeak = peak * delta
    }
    
    fileprivate mutating func updateAltitude(with direction: WaveDirection) {
        if case .up = direction {
            currentAltitude += _verticalTPF
        }
        
        if case .down = direction {
            currentAltitude -= _verticalTPF
        }
    }
    
    mutating func updateAltitude() {
        updateAltitude(with: direction)
    }
    
    mutating func updateTranslation() {
        currentTranslation += _horizontalTPF
    }
    
    mutating func update() {
        updateAltitude()
        updateTranslation()
    }
}

public class WaveNodeGenerator {

    private(set) var templateWaveNode: WaveNode
    private(set) var existingWaveNodes: [WaveNode] = []
    
    fileprivate var maxNodeCount: Int
    fileprivate var nodeTimeInterval: TimeInterval
    fileprivate var _timer: Timer!
    fileprivate var _timerIsPaused: Bool = false
    
    init(waveNode: WaveNode, maxCount: Int) {
        self.templateWaveNode = waveNode
        self.maxNodeCount = maxCount
        self.nodeTimeInterval = waveNode._horizontalTimeinterval
        NotificationCenter.default.addObserver(self, selector: #selector(WaveNodeGenerator.willResignActive(notification:)), name: .UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(WaveNodeGenerator.willEnterForeground(notification:)), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    @objc func willResignActive(notification: Notification) {
        _timerIsPaused = true
    }
    
    @objc func willEnterForeground(notification: Notification) {
        _timerIsPaused = false
    }
    
    func initialNode() -> WaveNode {
        var node = templateWaveNode
        node.updatePeakAndNadir()
        return node
    }
    
    func nextNode() -> WaveNode {
        let lastNode = existingWaveNodes.last!
        var node = templateWaveNode
        node.updatePeakAndNadir()
        node.direction = lastNode.direction.inverse()
        node.currentAltitude(with: -lastNode.altitudeRatio)
        return node
    }
    
    func begin() {
        existingWaveNodes.append(initialNode())
        _timer = Timer.scheduledTimer(timeInterval: nodeTimeInterval, target: self, selector: #selector(WaveNodeGenerator.next(timer:)), userInfo: nil, repeats: true)
        _timer.fire()
    }
    
    @objc public func next(timer: Timer) {
        guard !_timerIsPaused else { return }
        
        existingWaveNodes.append(nextNode())
        existingWaveNodes = existingWaveNodes.filter { node in
            return node.currentTranslation <= templateWaveNode.nodeSegment * CGFloat(maxNodeCount)
        }
        print(existingWaveNodes.count)
    }
    
    func updateNodesHorizontal() {
        existingWaveNodes = existingWaveNodes.map { node in
            var bar = node
            bar.updateTranslation()
            return bar
        }
    }
    
    func updateNodes() {
        existingWaveNodes = existingWaveNodes.map { node in
            var bar = node
            bar.update()
            return bar
        }
    }
    
}
 
