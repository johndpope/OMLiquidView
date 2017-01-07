//
//  OMLiquidView.swift
//  Pods
//
//  Created by HuangKun on 2017/1/5.
//
//

import UIKit

public class OMLiquidView: UIView {
    
    fileprivate var _liquidPath: UIBezierPath!
    fileprivate var _liquidLayer: CAShapeLayer = CAShapeLayer()
    fileprivate var _templateWaveNode: WaveNode
    fileprivate var _waveNodeGenerator: WaveNodeGenerator!
    
    fileprivate var _animationTimer: CADisplayLink!
    
    fileprivate var _waveSegament: CGFloat
    
    lazy var _refWidth: CGFloat = {
        return self.frame.width + 2 * self._waveSegament
    }()
    lazy var _refHeight: CGFloat = {
        return self.frame.height - self._templateWaveNode.peak - self._templateWaveNode.nadir
    }()
    lazy var _refX: CGFloat = {
        return -self._waveSegament
    }()
    lazy var _refY: CGFloat = {
        return self._templateWaveNode.peak + self._templateWaveNode.nadir
    }()
    
    lazy var _initialPoint: CGPoint = {
        return CGPoint(x: self._refX + self._refWidth, y: self._refY)
    }()
    
    lazy var _brPoint: CGPoint = {
        return CGPoint(x: self._refX + self._refWidth, y: self._refY + self._refHeight)
    }()
    
    lazy var _blPoint: CGPoint = {
        return CGPoint(x: self._refX, y: self._refY + self._refHeight)
    }()
    
    lazy var _tlPoint: CGPoint = {
        return CGPoint(x: self._refX, y: self._refY)
    }()
    
    public var liquidColor: UIColor? = UIColor.clear
    
    public init(frame: CGRect, templateWaveNode: WaveNode) {
        _templateWaveNode = templateWaveNode
        _waveSegament = templateWaveNode.nodeSegment
        super.init(frame: frame)
        setupLiquidLayer()
        self.backgroundColor = UIColor.clear
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLiquidPath() {
        
        _liquidPath = UIBezierPath(rect: CGRect(x: _refX, y: _refY, width: _refWidth, height: _refHeight))
    }
    
    private func setupWaveGenerator() {
        let maxCount = Int(ceil(self.bounds.width / _templateWaveNode.nodeSegment)) + 1
        _waveNodeGenerator = WaveNodeGenerator(waveNode: _templateWaveNode, maxCount: maxCount)
    }
    
    private func setupLiquidLayer() {
        setupLiquidPath()
        setupWaveGenerator()
        _liquidLayer.path = _liquidPath.cgPath
        _liquidLayer.fillColor = self.liquidColor?.cgColor
        self.layer.addSublayer(_liquidLayer)
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        _animationTimer = CADisplayLink(target: self, selector: #selector(OMLiquidView.updateLiquidLayer(timer:)))
        _animationTimer.add(to: RunLoop.current, forMode: .commonModes)
        _waveNodeGenerator.begin()
    }
    
    func updateLiquidLayer(timer: CADisplayLink) {
        updateLiquidPath()
        _liquidLayer.path = _liquidPath.cgPath
        _liquidLayer.fillColor = self.liquidColor?.cgColor
    }
    
    private func updateLiquidPath() {
        let allWaveNodes = _waveNodeGenerator.existingWaveNodes
        let templateNode = _waveNodeGenerator.templateWaveNode
        let nodeSegment = templateNode.nodeSegment
        
        switch allWaveNodes.count {
        case 0:
            return
        default:
            _waveNodeGenerator.updateNodes()
            _liquidPath = UIBezierPath()
            _liquidPath.move(to: _initialPoint)
            _liquidPath.addLine(to: _brPoint)
            _liquidPath.addLine(to: _blPoint)
            _liquidPath.addLine(to: _tlPoint)
            (0..<allWaveNodes.count).map { index in
                let currentIndex = allWaveNodes.count - 1 - index
                let currentNode = allWaveNodes[currentIndex]
                let endPoint = CGPoint(x: currentNode.currentTranslation + _refX, y: _refY + currentNode.currentAltitude)
                _liquidPath.om_addCurve(to: endPoint)
            }
            _liquidPath.addLine(to: _initialPoint)
        }
        
    }
    
}

extension UIBezierPath {
    func om_addCurve(to end: CGPoint) {
        let currentPoint = self.currentPoint
        let cp1 = CGPoint(x: (end.x + currentPoint.x) / 2, y: currentPoint.y)
        let cp2 = CGPoint(x: cp1.x, y: end.y)
        self.addCurve(to: end, controlPoint1: cp1, controlPoint2: cp2)
    }
}
