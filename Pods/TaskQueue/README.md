
# TaskQueue

[![Platform](https://img.shields.io/cocoapods/p/TaskQueue.svg?style=flat)](http://cocoadocs.org/docsets/TaskQueue)
[![Cocoapods Compatible](https://img.shields.io/cocoapods/v/TaskQueue.svg)](https://img.shields.io/cocoapods/v/TaskQueue.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![GitHub License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/icanzilb/TaskQueue/master/LICENSE.md)


## Table of Contents

* [Intro](#intro)
* [Installation](#installation)
  * [CocoaPods](#cocoapods)
  * [Carthage](#carthage)
* [Simple Examples](#simple-examples)
  * [Synchronous tasks](#synchronous-tasks)
  * [Asynchronous tasks](#asynchronous-tasks)
* [Serial and Concurrent Tasks](#serial-and-concurrent-tasks)
* [GCD Queue Control](#gcd-queue-control)
* [Extensive Example](#extensive-example)
* [Credit](#credit)
* [License](#license)


## Intro

![title](https://raw.githubusercontent.com/icanzilb/TaskQueue/master/etc/readme_schema.png)

TaskQueue is a Swift library which allows you to schedule tasks once and then let the queue execute them in a synchronous manner. The great thing about TaskQueue is that you get to decide on which GCD queue each of your tasks should execute beforehand and leave TaskQueue to do switching of the queues as it goes.

Even if your tasks are asynchronious like fetching location, downloading files, etc. TaskQueue will wait until they are finished before going on with the next task.

Last but not least your tasks have full flow control over the queue, depending on the outcome of the work you are doing in your tasks you can skip the next task, abort the queue, or jump ahead to the queue completion. You can further pause, resume, and stop the queue.


## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects.

If you don't already have the Cocoapods gem installed, run the following command:

```bash
$ gem install cocoapods
```

To integrate TaskQueue into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'TaskQueue'
```

Then, run the following command:

```bash
$ pod install
```

If you find that you're not having the most recent version installed when you run `pod install` then try running:

```bash
$ pod cache clean
$ pod repo update TaskQueue
$ pod install
```

Also you'll need to make sure that you've not got the version of TaskQueue locked to an old version in your `Podfile.lock` file.

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that automates the process of adding frameworks to your Cocoa application.