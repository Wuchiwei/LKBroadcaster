//
//  NotificationService.swift
//  Sample
//
//  Created by WU CHIH WEI on 2022/5/24.
//

import Combine
import Foundation

public class LKBroadcaster {
    
    private static let shared = LKBroadcaster()
    
    init() { }
    
    private var observers: [String: Set<AnyHashable>] = [:]
    
    //MARK: - Public Method
    public static func post<T: LKNotification>(
        notification: T,
        content: T.Content
    ) {
        shared.post(
            notification: notification,
            content: content
        )
    }
    
    public static func observe<T: LKNotification>(
        notification: T,
        queue: DispatchQueue = DispatchQueue.main,
        _ callback: @escaping (T.Content) -> Void
    )-> Cancellable {
        
        shared.observe(
            notification: notification,
            queue: queue,
            callback
        )
    }
    
    //MARK: - Private Method
    private func post<T: LKNotification>(
        notification: T,
        content: T.Content
    ) {
        if let set = observers[notification.name] {
            for observer in set {
                if let ob = observer as? LKAnyObserver<T.Content> {
                    ob.notify(with: content)
                }
            }
        }
    }
    
    private func observe<T: LKNotification>(
        notification: T,
        queue: DispatchQueue = DispatchQueue.main,
        _ callback: @escaping (T.Content) -> Void
    ) -> Cancellable {
        
        let ob = LKAnyObserver(callback, queue: queue)
        
        if var set = observers[notification.name] {
            let _ = set.insert(ob)
            observers[notification.name] = set
        } else {
            let set = Set([ob])
            observers[notification.name] = set
        }

        return LKAnyNotificationCancellable{ [weak self] in
            self?.removeObserver(ob, notification: notification)
        }
    }

    private func removeObserver<T: LKNotification>(
        _ ob: LKAnyObserver<T.Content>,
        notification: T
    ) {
        observers[notification.name]?.remove(ob)
    }
}
