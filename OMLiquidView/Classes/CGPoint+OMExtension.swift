//
//  CGPoint+OMExtension.swift
//  Pods
//
//  Created by HuangKun on 2017/1/9.
//
//

import Foundation

prefix func -(point: CGPoint) -> CGPoint {
    return CGPoint(x: -point.x, y: -point.y)
}

func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return lhs + (-rhs)
}
