//
//  WaveDataGenerator.swift
//  Pods
//
//  Created by HuangKun on 2017/1/5.
//
//

import Foundation

public enum WaveDirection: Int {
    case up = 0
    case down
    
    func inverse() -> WaveDirection {
        if case .up = self { return .down }
        if case .down = self { return .up }
        return .up
    }
}

public struct WaveNode {
    let peak: CGFloat
    let nadir: CGFloat
    var nodeSegment: CGFloat = 0
    var currentAltitude: CGFloat = 0 {
        didSet {
            if currentAltitude >= _currentPeak {
                direction = .down
            }
            
            if currentAltitude <= -nadir {
                direction = .up
            }
        }
    }
    var altitudeRatio: CGFloat {
        return currentAltitude / _currentPeak
    }
    var verticalTimeinterval: TimeInterval = 6
    var direction: WaveDirection = WaveDirection(rawValue: Int(arc4random() % 1))!
    
    var currentTranslation: CGFloat = 0
    public var horizontalTimeinterval: TimeInterval = 2
    
    fileprivate var _currentPeak: CGFloat = 0
    fileprivate var _currentNadir: CGFloat = 0
    fileprivate var _verticalTPF: CGFloat {
        let min1 = -0.2 * _currentPeak
        let max1 = 0.2 * _currentPeak
        
        let min2 = -0.4 * _currentPeak
        let max2 = 0.4 * _currentPeak
        
        if currentAltitude > min1 && currentAltitude < max1 {
            return _currentPeak / (20 * CGFloat(self.verticalTimeinterval))
        }
        
        if currentAltitude > min2 && currentAltitude < max2 {
            return _currentPeak / (40 * CGFloat(self.verticalTimeinterval))
        }
        
        return _currentPeak / (60 * CGFloat(self.verticalTimeinterval))
    }
    
    fileprivate lazy var _horizontalTPF: CGFloat = {
       return self.nodeSegment / (60 * CGFloat(self.horizontalTimeinterval))
    }()

    public init(peak: CGFloat, nadir: CGFloat, nodeSegment: CGFloat, direction: WaveDirection) {
        self.peak = peak
        self.nadir = nadir
        self.nodeSegment = nodeSegment
        self.direction = direction
    }
    
    mutating func currentAltitude(with ratio: CGFloat) {
        currentAltitude = ratio * _currentPeak
    }
    
    mutating func updatePeakAndNadir() {
        let delta: CGFloat = 1
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
    var maxNodeCount: Int
    var currentNodeIndex: Int = 0
    var nodeTimeInterval: TimeInterval
    private(set) var templateWaveNode: WaveNode
    private(set) var existingWaveNodes: [WaveNode] = []
    
    fileprivate var _timer: Timer!
    
    init(waveNode: WaveNode, maxCount: Int) {
        self.templateWaveNode = waveNode
        self.maxNodeCount = maxCount
        self.nodeTimeInterval = waveNode.horizontalTimeinterval
    }
    
    func initialNode() -> WaveNode {
        var node = templateWaveNode
        node.updatePeakAndNadir()
        node.currentAltitude = 0
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
        existingWaveNodes.append(nextNode())
        if existingWaveNodes.count != maxNodeCount {
            existingWaveNodes = existingWaveNodes.filter { node in
                return node.currentTranslation <= templateWaveNode.nodeSegment * CGFloat(maxNodeCount)
            }
            print(existingWaveNodes.count)
        }else {
            currentNodeIndex += 1
        }
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
 
