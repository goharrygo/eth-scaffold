//
// TaskQueue.swift
//
// Copyright (c) 2014-2016 Marin Todorov, Underplot ltd.
// This code is distributed under the terms and conditions of the MIT license.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// This class is inspired by Sequencer (objc) https://github.com/berzniz/Sequencer
// but aims to implement 1) flow control, 2) swift code, 3) control of GDC queues, 4) concurrency
//

import Foundation

// MARK: TaskQueue class

open class TaskQueue: CustomStringConvertible {

    //
    // types used by the TaskQueue
    //
    public typealias ClosureNoResultNext = () -> Void
    public typealias ClosureWithResultNext = (Any? , @escaping (Any?) -> Void) -> Void

    //
    // tasks and completions storage
    //
    open var tasks = [ClosureWithResultNext]()
    open lazy var completions = [ClosureNoResultNext]()

    //
    // concurrency
    //
    public fileprivate(set) var numberOfActiveTasks = 0
    open var maximumNumberOfActiveTasks = 1 {
        willSet {
            assert(maximumNumberOfActiveTasks > 0, "Setting less than 1 task at a time not allowed")
        }
    }

    fileprivate var currentTask: ClosureWithResultNext? = nil
    fileprivate(set) var lastResult: Any! = nil

    //
    // queue state
    //
    fileprivate(set) var running = false

    open var paused: Bool = false {
        didSet {
            running = !paused
        }
    }

    fileprivate var cancelled = false
    open func cancel() {
        cancelled = true
    }

    fileprivate var hasCompletions = false

    //
    // start or resume the queue
    //
    public init() {}
    
    open func run(_ completion: ClosureNoResultNext? = nil) {
        if completion != nil {
            hasCompletions = true
            completions += [completion!]
        }

        if (paused) {
            paused = false
            _runNextTask()
            return
        }

        if running {
            return
        }

        running = true
        _runNextTask()
    }

    fileprivate func _runNextTask(_ result: Any? = nil) {
        if (cancelled) {
            tasks.removeAll(keepingCapacity: false)
            completions.removeAll(keepingCapacity: false)
        }

        if (numberOfActiveTasks >= maximumNumberOfActiveTasks) {
            return
        }

        lastResult = result

        if paused {
            return
        }

        var task: ClosureWithResultNext? = nil

        //fetch one task synchronized
        objc_sync_enter(self)
        if tasks.count > 0 {
            task = tasks.remove(at: 0)
            numberOfActiveTasks += 1
        }
        objc_sync_exit(self)

        if task == nil {
            if numberOfActiveTasks == 0 {
                _complete()
            }
            return
        }

        currentTask = task

        let executeTask = {
            task!(self.maximumNumberOfActiveTasks > 1 ? nil : result) { nextResult in
                self.numberOfActiveTasks -= 1
                self._runNextTask(nextResult)
            }
        }

        if maximumNumberOfActiveTasks > 1 {
            //parallel queue
            _delay(seconds: 0.001) {
                self._runNextTask(nil)
            }
            _delay(seco