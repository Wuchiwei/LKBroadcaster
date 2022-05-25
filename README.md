# LKBroadcaster

### Installation
Supprot `Swift Package Manager` installation.

### Usage
Step 1. Create your custom notification through LKAnyNotification. 

```swift

struct Movie {
    let name: String
}

struct LKNotificationFactory {
    static let addLongMovieToFavorate = LKAnyNotification<Movie>(name: "addLongMovieToFavorate")
}

```
Step 2: Observe to LKBroadcaster and store the return AnyCancellable object in Set or Array. 

```swift

import UIKit
import Combine
import LKBroadcaster

class ViewController: UIViewController {

    var cancelled: Set<AnyCancellable> = Set()

    var movie: Movie?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        LKBroadcaster.observe(
            notification: LKNotificationFactory.addLongMovieToFavorate,
            queue: DispatchQueue.global(),
            { [weak self] movie in
                guard let self = self else { return }
                self.movie = movie
                print(self.movie!, Thread.current)
            }
        ).store(in: &cancelled)
    }
}
```

Step 3: Post Notification through LKBroadscater

```swift
LKBroadcaster.post(
    notification: LKNotificationFactory.addLongMovieToFavorate, 
    content: Movie(name: "Nice Movie")
)
```

### Design Explaination
You can review design thinking in [Design Explaination Document](https://github.com/Wuchiwei/LKBroadcaster/blob/main/Design_Explaination.md).
