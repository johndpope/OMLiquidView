//
//  ViewController.swift
//  OMLiquidView
//
//  Created by HuangKun on 01/05/2017.
//  Copyright (c) 2017 HuangKun. All rights reserved.
//

import UIKit
import OMLiquidView

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let refRect1 = CGRect(x: 0, y: self.view.bounds.height / 2, width: self.view.bounds.width, height: self.view.bounds.height / 2)
        
        let node1 = WaveNode(configuration: .default(modify: { (_ config: inout WaveNode.Configuration) in
            config.initialDirction = .up
            config.horizontalAnimationDuration = 2
            config.peakAndNadir = .notEqual(peak: 20, nadir: 15)
            config.nodeSegment = 300
        }))
        
        let liquidView1 = OMLiquidView(frame: refRect1, templateWaveNode: node1, appearance: .default(modify: { (_ config: inout OMLiquidView.Appearance) in
            config.backLayer = .gradientBGColor(
                colors: [UIColor.red.cgColor, UIColor.blue.cgColor],
                locations: [0.0, 1.0], startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 1, y: 1), type: kCAGradientLayerAxial)
            config.shadow = .shadow(opacity: 0.5, radius: 10, offset: CGSize(width: 0, height:-5), color: UIColor.black.cgColor)
        }))

        let refRect2 = CGRect(x: 0, y: refRect1.origin.y - 20, width: refRect1.width, height: refRect1.height + 20)
        let node2 = WaveNode(configuration: .default { (_ config: inout WaveNode.Configuration) in
                config.initialDirction = .down
                config.peakAndNadir = .notEqual(peak: 30, nadir: 10)
            })
        let liquidView2 = OMLiquidView(frame: refRect2, templateWaveNode: node2)
        self.view.addSubview(liquidView2)
        self.view.addSubview(liquidView1)


    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

