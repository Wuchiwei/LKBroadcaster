//
//  LKAnyNotification.swift
//  
//
//  Created by WU CHIH WEI on 2022/5/25.
//

import Foundation

public struct LKAnyNotification<T>: LKNotification {
    
    public typealias Content = T
    
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
}
