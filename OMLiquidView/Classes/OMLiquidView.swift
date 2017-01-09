//
//  OMLiquidView.swift
//  Pods
//
//  Created by HuangKun on 2017/1/5.
//
//

import UIKit

fileprivate let shadowPathAdjust: CGFloat = 4


public class OMLiquidView: UIView {
    
    public enum LayerAppearance {
        case bgColor(color: UIColor)
        case gradientBGColor(colors: [AnyObject]?, locations: [NSNumber]?, startPoint: CGPoint, endPoint: CGPoint, type: String)
        case custom(layer: CALayer)
    }
    
    public enum ShadowAppearance {
        case none
        case shadow(opacity: Float, radius: CGFloat, offset: CGSize, color: CGColor)
    }
    
    public struct Appearance: Options {
        public var backLayer: OMLiquidView.LayerAppearance = .bgColor(color: .red)
        public var shadow: ShadowAppearance = .none
        public typealias OptionStruct = Appearance
        public init() {}
    }
    
    fileprivate var _appearance: OMLiquidView.Appearance
    fileprivate var _timerIsPaused: Bool = false
    
    /// liquid path, update base on the wave nodes.
    fileprivate var _liquidPath: UIBezierPath!
    
    fileprivate var _shadowPath: UIBezierPath?
    
    /// assign CALayer instance to this property for custom usage.(layer bacground color or gradient...)
    fileprivate var _liquidBackLayer: CALayer = CALayer()
    
    /// use as a mask for back layer⬆️
    fileprivate var _liquidMaskLayer: CAShapeLayer = CAShapeLayer()
    
    /// just like the mask layer but used for shadow drawing.
    fileprivate var _liquidShadowLayer: CAShapeLayer?
    
    /// template node, this node is used as template for the rest.
    fileprivate var _templateWaveNode: WaveNode
    
    /// node generator, add new nodes, remove old ones and update nodes' properties.
    fileprivate var _waveNodeGenerator: WaveNodeGenerator!
    
    /// display link, update nodes' properties and liquid path.
    fileprivate var _animationTimer: CADisplayLink!
    
    /// horizontal distance between two adjoining nodes
    fileprivate var _waveSegament: CGFloat
    
    // properties to coordinate the layers
    fileprivate lazy var _refWidth: CGFloat = {
        return self.frame.width + self._waveSegament * 2
    }()
    fileprivate lazy var _refHeight: CGFloat = {
        return self.frame.height - self._templateWaveNode.peak - self._templateWaveNode.nadir
    }()
    fileprivate lazy var _refX: CGFloat = {
        return -self._waveSegament
    }()
    fileprivate lazy var _refY: CGFloat = {
        return self._templateWaveNode.peak + self._templateWaveNode.nadir
    }()
    
    
    /// start point for liquid path.(top right)
    fileprivate lazy var _initialPoint: CGPoint = {
        return CGPoint(x: self._refX + self._refWidth, y: self._refY)
    }()
    
    /// bottom right
    fileprivate lazy var _brPoint: CGPoint = {
        return CGPoint(x: self._refX + self._refWidth, y: self._refY + self._refHeight)
    }()
    
    /// bottom left
    fileprivate lazy var _blPoint: CGPoint = {
        return CGPoint(x: self._refX, y: self._refY + self._refHeight)
    }()
    
    /// top left
    fileprivate lazy var _tlPoint: CGPoint = {
        return CGPoint(x: self._refX, y: self._refY)
    }()
    
    public init(frame: CGRect, templateWaveNode: WaveNode, appearance: Appearance = Appearance()) {
        _templateWaveNode = templateWaveNode
        _waveSegament = templateWaveNode.nodeSegment
        self._appearance = appearance
        super.init(frame: frame)
        setupLiquidLayer()
        self.backgroundColor = UIColor.clear
        
        NotificationCenter.default.addObserver(self, selector: #selector(OMLiquidView.willResignActive(notification:)), name: .UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(OMLiquidView.willEnterForeground(notification:)), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    func willResignActive(notification: Notification) {
        _timerIsPaused = true
    }
    
    func willEnterForeground(notification: Notification) {
        _timerIsPaused = false
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLiquidPath() {
        _liquidPath = UIBezierPath(rect: CGRect(x: _refX, y: _refY, width: _refWidth, height: _refHeight))
        if case .shadow = _appearance.shadow {
            _shadowPath = UIBezierPath(rect: CGRect(x: _refX, y: _refX, width: _refWidth, height: 2))
        }
    }
    
    private func setupWaveGenerator() {
        _waveNodeGenerator = WaveNodeGenerator(waveNode: _templateWaveNode, threshold: _refWidth * 1.2)
    }
    
    private func setupLiquidLayer() {
        setupLiquidPath()
        setupWaveGenerator()
        
        _liquidBackLayer.frame = self.bounds
        switch _appearance.backLayer {
        case .bgColor(let color):
            _liquidBackLayer.backgroundColor = color.cgColor
        case .gradientBGColor(let colors, let locations, let startPoint, let endPoint, let type):
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = colors
            gradientLayer.locations = locations
            gradientLayer.startPoint = startPoint
            gradientLayer.endPoint = endPoint
            gradientLayer.type = type
            gradientLayer.frame = _liquidBackLayer.bounds
            _liquidBackLayer.addSublayer(gradientLayer)
        case .custom(let layer):
            layer.frame = _liquidBackLayer.bounds
            _liquidBackLayer.addSublayer(layer)
        }
        _liquidMaskLayer.path = _liquidPath.cgPath
        _liquidBackLayer.mask = _liquidMaskLayer
        
        switch _appearance.shadow {
        case .shadow(let opacity, let radius, let offset, let color):
            _liquidShadowLayer = CAShapeLayer()
            guard let layer = _liquidShadowLayer else {
                fatalError("liquid shadow layer initialization failed")
            }
            layer.path = _shadowPath?.cgPath
            layer.shadowOpacity = opacity
            layer.shadowRadius = radius
            layer.shadowOffset = CGSize(width: offset.width, height: offset.height - shadowPathAdjust)
            layer.shadowColor = color
            self.layer.addSublayer(layer)
        default:
            break
        }
        
        self.layer.addSublayer(_liquidBackLayer)
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        _animationTimer = CADisplayLink(target: self, selector: #selector(OMLiquidView.updateLiquidLayer(timer:)))
        _animationTimer.add(to: RunLoop.current, forMode: .commonModes)
        _waveNodeGenerator.begin()
    }
    
    func updateLiquidLayer(timer: CADisplayLink) {
        guard !_timerIsPaused else { return }
        updateLiquidPath()
        _liquidMaskLayer.path = _liquidPath.cgPath
        _liquidShadowLayer?.path = _shadowPath?.cgPath
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
            
            _shadowPath = UIBezierPath()
        
            _shadowPath?.move(to: _tlPoint)

            (0..<allWaveNodes.count).forEach { index in
                let currentIndex = allWaveNodes.count - 1 - index
                let currentNode = allWaveNodes[currentIndex]
                var endPoint: CGPoint = CGPoint.zero
                if currentIndex == 0 {
                    endPoint = CGPoint(x: currentNode.currentTranslation + _refX + nodeSegment / 2, y: _refY)
                }else {
                    endPoint = CGPoint(x: currentNode.currentTranslation + _refX, y: _refY + currentNode.currentAltitude)
                }
                _shadowPath?.om_addCurve(to: endPoint)
                _liquidPath.om_addCurve(to: endPoint)
            }
            _shadowPath?.addLine(to: _initialPoint)
            _shadowPath?.addLine(to: _initialPoint + CGPoint(x: 0, y: templateNode.peak + templateNode.nadir))
            _shadowPath?.addLine(to: _tlPoint + CGPoint(x: 0, y: templateNode.peak + templateNode.nadir))
            _shadowPath?.close()
            _shadowPath?.apply(CGAffineTransform(translationX: 0, y: shadowPathAdjust))

            _liquidPath.addLine(to: _initialPoint)
        }
        
    }
    
}


