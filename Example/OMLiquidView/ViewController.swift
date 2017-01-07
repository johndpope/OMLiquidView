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
        let node1 = WaveNode(peak: 10, nadir: 10, nodeSegment: 360, direction: .up)
        let liquidView1 = OMLiquidView(frame: refRect1, templateWaveNode: node1)
        liquidView1.liquidColor = UIColor.red

        let refRect2 = CGRect(x: 0, y: refRect1.origin.y - 15, width: refRect1.width, height: refRect1.height + 15)
        var node2 = WaveNode(peak: 13, nadir: 13, nodeSegment: 360, direction: .down)
        node2.horizontalTimeinterval = 4
        let liquidView2 = OMLiquidView(frame: refRect2, templateWaveNode: node2)
        liquidView2.liquidColor = UIColor.blue
        self.view.addSubview(liquidView2)
        self.view.addSubview(liquidView1)


    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

