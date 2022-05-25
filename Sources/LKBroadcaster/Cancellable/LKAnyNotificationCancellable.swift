//
//  LKAnyNotificationCancellable.swift
//  
//
//  Created by WU CHIH WEI on 2022/5/25.
//

import Combine

public class LKAnyNotificationCancellable: Cancellable {
    
    private let cancelBlock: () -> Void
    
    init(_ cancelBlock: @escaping () -> Void) {
        self.cancelBlock = cancelBlock
    }
    
    public func cancel() {
        cancelBlock()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}
