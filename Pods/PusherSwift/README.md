
# PusherSwift (pusher-websocket-swift) (also works with Objective-C!)

[![Build Status](https://travis-ci.org/pusher/pusher-websocket-swift.svg?branch=master)](https://travis-ci.org/pusher/pusher-websocket-swift)
![Languages](https://img.shields.io/badge/languages-swift%20%7C%20objc-orange.svg)
[![Platform](https://img.shields.io/cocoapods/p/PusherSwift.svg?style=flat)](http://cocoadocs.org/docsets/PusherSwift)
[![Cocoapods Compatible](https://img.shields.io/cocoapods/v/PusherSwift.svg)](https://img.shields.io/cocoapods/v/PusherSwift.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Twitter](https://img.shields.io/badge/twitter-@Pusher-blue.svg?style=flat)](http://twitter.com/Pusher)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/pusher/pusher-websocket-swift/master/LICENSE.md)

Supports iOS, macOS (OS X) and tvOS! (Hopefully watchOS soon!)


## I just want to copy and paste some code to get me started

What else would you want? Head over to one of our example apps:

* For iOS with Swift, see [ViewController.swift](https://github.com/pusher/pusher-websocket-swift/blob/master/iOS%20Example%20Swift/iOS%20Example%20Swift/ViewController.swift)
* For iOS with Objective-C, see [ViewController.m](https://github.com/pusher/pusher-websocket-swift/blob/master/iOS%20Example%20Obj-C/iOS%20Example%20Obj-C/ViewController.m)
* For macOS with Swift, see [AppDelegate.swift](https://github.com/pusher/pusher-websocket-swift/blob/master/macOS%20Example%20Swift/macOS%20Example%20Swift/AppDelegate.swift)


## Table of Contents

* [Installation](#installation)
* [Configuration](#configuration)
* [Connection](#connection)
  * [Connection delegate](#connection-delegate)
  * [Reconnection](#reconnection)
* [Subscribing to channels](#subscribing)
  * [Public channels](#public-channels)
  * [Private channels](#private-channels)
  * [Presence channels](#presence-channels)
* [Binding to events](#binding-to-events)
  * [Globally](#global-events)
  * [Per-channel](#per-channel-events)
  * [Receiving errors](#receiving-errors)
* [Push notifications](#push-notifications)
  * [Pusher delegate](#pusher-delegate)
* [Testing](#testing)
* [Extensions](#extensions)
* [Communication](#communication)
* [Credits](#credits)
* [License](#license)


## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects and is our recommended method of installing PusherSwift and its dependencies.

If you don't already have the Cocoapods gem installed, run the following command:

```bash
$ gem install cocoapods
```

To integrate PusherSwift into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

pod 'PusherSwift', '~> 5.0'
```

Then, run the following command:

```bash
$ pod install
```

If you find that you're not having the most recent version installed when you run `pod install` then try running:

```bash
$ pod cache clean
$ pod repo update PusherSwift
$ pod install
```

Also you'll need to make sure that you've not got the version of PusherSwift locked to an old version in your `Podfile.lock` file.

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that automates the process of adding frameworks to your Cocoa application.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate PusherSwift into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "pusher/pusher-websocket-swift"