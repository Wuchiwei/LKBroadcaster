# LKBroadcaster

# Notification Center

1. 原生的 Apple Notification Center 作法

- Use Selector
    1. iOS 9 之後就不需要再額外 remove observer，系統會在下一次 Post 這個 notification 的時候，移除已經為 nil 的 observer
    2. 缺點：
        1. Notification 的內容型別沒辦法是特定型別，只能是 Dictionary
        2. 需要特別寫一個 method 作為 selector，註冊的動作跟接收通知的行為沒有寫在一起，trace code 難度會稍微增加
    
    ```swift
    extension Notification {
        static let movie = Notification.Name("movie")
    }
    
    NotificationCenter.default.addObserver(
        self, selector: #selector(movie(_:)),
        name: Notification.movie,
        object: nil
    )
    
    @objc func movie(_ notification: Notification) {
        print("Here we receive notification in selector: ", notification)
    }
    ```
    
- Use block
    1. addObserver 的 method 會回傳一個 ****NSObjectProtocol**** 的物件回來，retain 這個物件會維持 observer 的有效性，如果物件被 release，則 observer 也會自動失效
    2. 優點：
        1. 註冊與回應通知的內容寫在一起了
        2. observe 回傳的 notification object release 就會同時移除 observer
        3. 可以指定執行 call back 的 queue
    3. 缺點：
        1. NSObjectProtocol 可讀性不夠高
        2. 通知的內容依然沒有具體的型別
    
    ```swift
    extension Notification {
        static let movie = Notification.Name("movie")
    }
    
    let notification = NotificationCenter.default.addObserver(
        forName: Notification.movie,
        object: nil,
        queue: .main,
        using: { notification in
            print("Here we receive notification in closure: ",, notification)
        }
    )
    ```
    

---

### Enhancement

1. 要保持的優點：
    1. 註冊與回應通知的內容寫在一起了 (Closure base observer)
    2. observe 回傳的 notification object release 就會同時移除 observer
    3. 可以指定執行 call back 的 queue
2. 要解決的缺點
    1. NSObjectProtocol 可讀性不夠高
        
        → 替換成 Combine 中的 Cancellable
        
    2. 通知的內容沒有具體的型別
        
        → 改寫成宣告 Notification 的時候，會把型別一起宣告
        

1. 建立 `LKNotification` protocol 來描述一個通知所需要的資料

```swift
public protocol LKNotification {
    
    associatedtype Content
    
    var name: String { get }
}
```

1. 建立 `LKAnyNotification` struct 用來建立符合 `LKNotification` 的 concrete type
    
    ```swift
    public struct LKAnyNotification<T>: LKNotification {
        
        public typealias Content = T
        
        public let name: String
        
        public init(name: String) {
            self.name = name
        }
    }
    
    let addLongMovieToFavorate = LKAnyNotification<Movie>(name: "addLongMovieToFavorate")
    ```
    

1. 建立 `LKAnyObserver`，當收到新的 observe 需求的時候，透過 LKObserver 把需求封裝起來（callback 與 queue），並存入 observers property 裡面。
    
    因為 LKAnyObserver 不作為與外部溝通的介面，這裡就不再以 protocol，而是以 concrete type 呈現，並設定為 `internal private` access level
    

```swift
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
```

1. 建立 `LKAnyNotificationCancellable` ，回傳給每一個來 observe 的物件，透過 cancellable object 的 life cycle 來適時的觸發 remove observer 的動作
    
    > 將 `LKAnyNotificationCancellable instance` 存放在 AnyCancellable 的 **set** 或是 **array**，當這個 collection 被 release 的時候，會 invoked AnyCancellable 的 `cancel()` method，這個功能是由 Combine framework 所實作跟保證的
    > 
    
    ```swift
    import Combine
    
    public class LKAnyNotificationCancellable: Cancellable {
        
        private let cancelBlock: () -> Void
        
        init(_ cancelBlock: @escaping () -> Void) {
            self.cancelBlock = cancelBlock
        }
        
    		// Store in AnyCancellable set or array will call cancel method 
        // when collection release, this functionality is guarantee be Combine framework
        public func cancel() {
            cancelBlock()
        }
        
        deinit {
            print("\(type(of: self)) deinit")
        }
    }
    ```
    

1. 建立 `LKBroadcaster`  ，透過帶入 `LKNotification` 發送通知跟接受訂閱
    
    ```swift
    import Combine
    import Foundation
    
    public class LKBroadcaster {
        
        private static let shared = LKBroadcaster()
        
        private init() { }
        
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
    ```
    

### Sample Code

可以透過以下程式碼做簡單的體驗

```swift
import UIKit
import Combine
import LKBroadcaster

struct Movie {
    let name: String
}

struct LKNotificationFactory {
    static let addLongMovieToFavorate = LKAnyNotification<Movie>(name: "addLongMovieToFavorate")
}

class ViewController: UIViewController {

    var cancelled: Set<AnyCancellable> = Set()

    var b: Movie = Movie(name: "1")

    override func viewDidLoad() {
        super.viewDidLoad()

        LKBroadcaster.observe(
            notification: LKNotificationFactory.addLongMovieToFavorate,
            queue: DispatchQueue.global(),
            { [weak self] a in
                self!.b = a
                print(self!.b, Thread.current)
            }
        ).store(in: &cancelled)
    }

    @IBAction func tap(_ sender: UIButton) {
        LKBroadcaster.post(notification: LKNotificationFactory.addLongMovieToFavorate, content: Movie(name: "test"))
    }
}
```

