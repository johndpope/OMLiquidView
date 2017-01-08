//
//  UIBezierPath+OMExtension.swift
//  Pods
//
//  Created by HuangKun on 2017/1/8.
//
//

import UIKit

extension UIBezierPath {
    func om_addCurve(to end: CGPoint) {
        let currentPoint = self.currentPoint
        let cp1 = CGPoint(x: (end.x + currentPoint.x) / 2, y: currentPoint.y)
        let cp2 = CGPoint(x: cp1.x, y: end.y)
        self.addCurve(to: end, controlPoint1: cp1, controlPoint2: cp2)
    }
}
