//
//  LKNotification.swift
//  
//
//  Created by WU CHIH WEI on 2022/5/25.
//

import Foundation

public protocol LKNotification {
    
    associatedtype Content
    
    var name: String { get }
}
