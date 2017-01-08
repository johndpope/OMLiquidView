//
//  OptionsProtocol.swift
//  Pods
//
//  Created by HuangKun on 2017/1/8.
//
//

import Foundation

public protocol Options {
    associatedtype OptionStruct
    init()
}

extension Options where OptionStruct: Options {
    public typealias Modification = (_ config: inout OptionStruct) -> Void
    public static func `default`(modify: Modification? = nil) -> OptionStruct {
        var config = OptionStruct()
        modify?(&config)
        return config
    }
}
