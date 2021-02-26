
[![Platform](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20Linux-4E4E4E.svg?colorA=28a745)](#installation)
[![Swift support](https://img.shields.io/badge/Swift-3.1%20%7C%203.2%20%7C%204.0-lightgrey.svg?colorA=28a745&colorB=4E4E4E)](#swift-versions-support)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/CryptoSwift.svg?style=flat&label=CocoaPods)](https://cocoapods.org/pods/CryptoSwift)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-brightgreen.svg?style=flat&colorB=64A5DE)](https://github.com/Carthage/Carthage)
[![Swift Package Manager compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg?style=flat&colorB=64A5DE)](https://github.com/apple/swift-package-manager)
[![Twitter](https://img.shields.io/badge/twitter-@krzyzanowskim-blue.svg?style=flat&colorB=64A5DE&label=Twitter)](http://twitter.com/krzyzanowskim)

# CryptoSwift

Crypto related functions and helpers for [Swift](https://swift.org) implemented in Swift. ([#PureSwift](https://twitter.com/hashtag/pureswift)) 

# Table of Contents
- [Requirements](#requirements)
- [Features](#features)
- [Contribution](#contribution)
- [Installation](#installation)
- [Swift versions](#swift-versions-support)
- [Usage](#usage)
- [Author](#author)
- [License](#license)
- [Changelog](#changelog)

## Requirements
Good mood

## Features

- Easy to use
- Convenient extensions for String and Data
- Support for incremental updates (stream, ...)
- iOS, macOS, AppleTV, watchOS, Linux support

## Donation
[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=92Z6U3LBHF9J4) to make the CryptoSwift awesome! Thank you.

#### Hash (Digest)
- [MD5](http://tools.ietf.org/html/rfc1321)
- [SHA1](http://tools.ietf.org/html/rfc3174)
- [SHA224](http://tools.ietf.org/html/rfc6234)
- [SHA256](http://tools.ietf.org/html/rfc6234)
- [SHA384](http://tools.ietf.org/html/rfc6234)
- [SHA512](http://tools.ietf.org/html/rfc6234)
- [SHA3](http://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf)

#### Cyclic Redundancy Check (CRC)
- [CRC32](http://en.wikipedia.org/wiki/Cyclic_redundancy_check)
- [CRC16](http://en.wikipedia.org/wiki/Cyclic_redundancy_check)

#### Cipher
- [AES-128, AES-192, AES-256](http://csrc.nist.gov/publications/fips/fips197/fips-197.pdf)
- [ChaCha20](http://cr.yp.to/chacha/chacha-20080128.pdf)
- [Rabbit](https://tools.ietf.org/html/rfc4503)
- [Blowfish](https://www.schneier.com/academic/blowfish/)

#### Message authenticators
- [Poly1305](http://cr.yp.to/mac/poly1305-20050329.pdf)
- [HMAC](https://www.ietf.org/rfc/rfc2104.txt) MD5, SHA1, SHA256
- [CMAC](https://tools.ietf.org/html/rfc4493)

#### Cipher block mode
- Electronic codebook ([ECB](http://en.wikipedia.org/wiki/Block_cipher_mode_of_operation#Electronic_codebook_.28ECB.29))
- Cipher-block chaining ([CBC](http://en.wikipedia.org/wiki/Block_cipher_mode_of_operation#Cipher-block_chaining_.28CBC.29))
- Propagating Cipher Block Chaining ([PCBC](http://en.wikipedia.org/wiki/Block_cipher_mode_of_operation#Propagating_Cipher_Block_Chaining_.28PCBC.29))
- Cipher feedback ([CFB](http://en.wikipedia.org/wiki/Block_cipher_mode_of_operation#Cipher_feedback_.28CFB.29))
- Output Feedback ([OFB](http://en.wikipedia.org/wiki/Block_cipher_mode_of_operation#Output_Feedback_.28OFB.29))
- Counter ([CTR](https://en.wikipedia.org/wiki/Block_cipher_mode_of_operation#Counter_.28CTR.29))

#### Password-Based Key Derivation Function
- [PBKDF1](http://tools.ietf.org/html/rfc2898#section-5.1) (Password-Based Key Derivation Function 1)
- [PBKDF2](http://tools.ietf.org/html/rfc2898#section-5.2) (Password-Based Key Derivation Function 2)
- [HKDF](https://tools.ietf.org/html/rfc5869) (HMAC-based Extract-and-Expand Key Derivation Function)

#### Data padding
- PKCS#5
- [PKCS#7](http://tools.ietf.org/html/rfc5652#section-6.3)
- [Zero padding](https://en.wikipedia.org/wiki/Padding_(cryptography)#Zero_padding)
- No padding

#### Authenticated Encryption with Associated Data (AEAD)
- [AEAD_CHACHA20_POLY1305](https://tools.ietf.org/html/rfc7539#section-2.8)

## Why
[Why?](https://github.com/krzyzanowskim/CryptoSwift/issues/5) [Because I can](https://github.com/krzyzanowskim/CryptoSwift/issues/5#issuecomment-53379391).

## Contribution

For the latest version, please check [develop](https://github.com/krzyzanowskim/CryptoSwift/tree/develop) branch. Changes from this branch will be merged into the [master](https://github.com/krzyzanowskim/CryptoSwift/tree/master) branch at some point.

- If you want to contribute, submit a [pull request](https://github.com/krzyzanowskim/CryptoSwift/pulls) against a development `develop` branch.
- If you found a bug, [open an issue](https://github.com/krzyzanowskim/CryptoSwift/issues).
- If you have a feature request, [open an issue](https://github.com/krzyzanowskim/CryptoSwift/issues).

## Installation

To install CryptoSwift, add it as a submodule to your project (on the top level project directory):

    git submodule add https://github.com/krzyzanowskim/CryptoSwift.git
    
It is recommended to enable [Whole-Module Optimization](https://swift.org/blog/whole-module-optimizations/) to gain better performance. Non-optimized build results in significantly worse performance.

#### Embedded Framework

Embedded frameworks require a minimum deployment target of iOS 8 or OS X Mavericks (10.9). Drag the `CryptoSwift.xcodeproj` file into your Xcode project, and add appropriate framework as a dependency to your target. Now select your App and choose the General tab for the app target. Find *Embedded Binaries* and press "+", then select `CryptoSwift.framework` (iOS, OS X, watchOS or tvOS)

![](https://cloud.githubusercontent.com/assets/758033/10834511/25a26852-7e9a-11e5-8c01-6cc8f1838459.png)

Sometimes "embedded framework" option is not available. In that case, you have to add new build phase for the target

![](https://cloud.githubusercontent.com/assets/758033/18415615/d5edabb0-77f8-11e6-8c94-f41d9fc2b8cb.png)

##### iOS, macOS, watchOS, tvOS

In the project, you'll find [single scheme](http://promisekit.org/news/2016/08/Multiplatform-Single-Scheme-Xcode-Projects/) for all platforms:
- CryptoSwift

#### Swift versions support

- Swift 1.2: branch [swift12](https://github.com/krzyzanowskim/CryptoSwift/tree/swift12) version <= 0.0.13
- Swift 2.1: branch [swift21](https://github.com/krzyzanowskim/CryptoSwift/tree/swift21) version <= 0.2.3
- Swift 2.2, 2.3: branch [swift2](https://github.com/krzyzanowskim/CryptoSwift/tree/swift2) version <= 0.5.2
- Swift 3.1, branch [swift3](https://github.com/krzyzanowskim/CryptoSwift/tree/swift3) version <= 0.6.9
- Swift 3.2, branch [swift32](https://github.com/krzyzanowskim/CryptoSwift/tree/swift32) version = 0.7.0
- Swift 4.0, branch [swift4](https://github.com/krzyzanowskim/CryptoSwift/tree/swift4) version >= 0.7.1
- Swift 4.1, branch [master](https://github.com/krzyzanowskim/CryptoSwift/tree/master) version >= 0.9.0

#### CocoaPods

You can use [CocoaPods](http://cocoapods.org/?q=cryptoSwift).

```ruby
platform :ios, '8.0'
use_frameworks!

target 'MyApp' do
  pod 'CryptoSwift'
end
```

or for newest version from specified branch of code:

```ruby
pod 'CryptoSwift', :git => "https://github.com/krzyzanowskim/CryptoSwift", :branch => "master"
```

Bear in mind that CocoaPods will build CryptoSwift without [Whole-Module Optimization](https://swift.org/blog/whole-module-optimizations/) that my impact performance. You can change it manually after installation, or use [cocoapods-wholemodule](https://github.com/jedlewison/cocoapods-wholemodule) plugin.

#### Carthage 
You can use [Carthage](https://github.com/Carthage/Carthage). 
Specify in Cartfile:

```ruby
github "krzyzanowskim/CryptoSwift"
```

Run `carthage` to build the framework and drag the built CryptoSwift.framework into your Xcode project. Follow [build instructions](https://github.com/Carthage/Carthage#getting-started). [Common issues](https://github.com/krzyzanowskim/CryptoSwift/issues/492#issuecomment-330822874).

#### Swift Package Manager

You can use [Swift Package Manager](https://swift.org/package-manager/) and specify dependency in `Package.swift` by adding this:
