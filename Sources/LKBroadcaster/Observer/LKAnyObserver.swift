//
//  LKAnyObserver.swift
//  
//
//  Created by WU CHIH WEI on 2022/5/25.
//

import Foundation

struct LKAnyObserver<T>: Hashable, Equatable {
    
    public static func == (lhs: LKAnyObserver<T>, rhs: LKAnyObserver<T>) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    let callBack: (T) -> Void
    
    let queue: DispatchQueue

    private let uuid: UUID = UUID()
    
    init(_ callBack: @escaping (T) -> Void, queue: DispatchQueue) {
        self.callBack = callBack
        self.queue = queue
    }
    
    func notify(with content: T) {
        queue.async {
            callBack(content)
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}
