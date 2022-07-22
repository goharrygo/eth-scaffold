# Reachability.swift

Reachability.swift is a replacement for Apple's Reachability sample, re-written in Swift with closures.

It is compatible with **iOS** (8.0 - 11.0), **OSX** (10.9 - 10.13) and **tvOS** (9.0 - 11.0)

Inspired by https://github.com/tonymillion/Reachability

## Supporting **Reachability.swift**
Keeping **Reachability.swift** up-to-date is a time consuming task. Making updates, reviewing pull requests, responding to issues and answering emails all take time. If you'd like to help keep me motivated, please download my free app, [Photo Flipper] from the App Store. (To really motivate me, pay $1.99 for the IAP 😀)

And don't forget to **★** the repo. This increases its visibility and encourages others to contribute.

Thanks
Ash

# IMPORTANT

## Version 4.0 breaking changes

### CocoaPods:

If you're adding **Reachability.swift** using CocoaPods, note that the framework name has changed from `ReachabilitySwift` to `Reachability` (for consistency with Carthage)

### Previously:

```swift
enum NetworkStatus {
    case notReachable, reachableViaWiFi, reachableViaWWAN
}
var currentReachabilityStatus: NetworkStatus
```

### Now:

```swift
enum Connection {
    case none, wifi, cellular
}
var connection: Connection
```

### Other changes:

- `isReachableViaWWAN` has been renamed to `isReachableViaCellular`

- `reachableOnWWAN` has been renamed to `allowsCellularConnection`

- `reachability.currentReac