
//  Copyright (c) 2016, Yuji
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those
//  of the authors and should not be interpreted as representing official policies,
//  either expressed or implied, of the FreeBSD Project.
//
//  Created by Yuji on 3/10/17.
//  Copyright © 2017 Yuji. All rights reserved.
//

#if !os(Linux)

public struct KernelQueue : FileDescriptorRepresentable {
    public var fileDescriptor: Int32
    public init() {
        self.fileDescriptor = xlibc.kqueue()
    }
}
    
public struct KQueueToDoList {
    
    var events = [KernelEvent]()
    
    public mutating func enqueue(event descriptor: KernelEventDescriptor, for actions: KernelEventAction) {
        self.events.append(descriptor.makeEvent(actions))
    }
    
    public mutating func add(event descriptor: KernelEventDescriptor, enable: Bool, oneshot: Bool) {
        var alist: KernelEventAction = .add
        if enable {
            alist = alist.union(.enable)
        }
        
        if oneshot {
            alist = alist.union(.oneshot)
        }
        
        self.events.append(descriptor.makeEvent([.add]))
    }
    
    public mutating func remove(event descriptor: KernelEventDescriptor) {
        self.events.append(descriptor.makeEvent([.delete]))
    }
    
}

extension KernelQueue {
    
    public mutating func enqueue(event descriptor: KernelEventDescriptor, for actions: KernelEventAction) {
        var event = descriptor.makeEvent(actions)
        __kevent(event: &event)
        
    }
    
    public mutating func add(event descriptor: KernelEventDescriptor, enable: Bool, oneshot: Bool) {
        var alist: KernelEventAction = .add
        if enable {
            alist = alist.union(.enable)
        }
        
        if oneshot {
            alist = alist.union(.oneshot)
        }
        var event = descriptor.makeEvent([.add])
        __kevent(event: &event)
    }
    
    public mutating func remove(event descriptor: KernelEventDescriptor) {
        var event = descriptor.makeEvent([.delete])
        __kevent(event: &event)
    }
    
    public func commit(todo: KQueueToDoList) throws {
        var events = todo.events
        _ = try throwsys("keven") {
            __kevent(&events)
        }
    }
    
    public func wait(todo: KQueueToDoList?, expecting eventsCount: Int, timeout: timespec?, handler: (KernelEventResult) -> ()) throws {
        var changeList = todo?.events
        
        var eventsBuffer = [KernelEvent](repeating: KernelEvent(), count: eventsCount)
        
        var timeout_pointer: UnsafePointer<timespec>!
        
        if var timeout = timeout {
            timeout_pointer = pointer(of: &timeout)
        }
        
        let returnedEventsCount = try throwsys("kevent", { () -> Int32 in
            changeList == nil
                ? __kevent(&eventsBuffer, timeout: timeout_pointer)
                : __kevent(&changeList!, &eventsBuffer, timeout: timeout_pointer)
        })
        
        for i in 0..<Int(returnedEventsCount) {
            handler(unsafeBitCast(eventsBuffer[i], to: KernelEventResult.self))
        }
    }
    
    @discardableResult
    @inline(__always)
    private func __kevent(event: inout KernelEvent) -> Int32 {
        return xlibc.kevent(fileDescriptor, &event, 1, nil, 0, nil)
    }
    
    @discardableResult
    @inline(__always)
    private func __kevent(_ changelist: inout [KernelEvent]) -> Int32 {
        return xlibc.kevent(fileDescriptor, changelist, Int32(changelist.count), nil, 0, nil)
    }
    
    @discardableResult
    @inline(__always)
    private func __kevent(_ changelist: inout [KernelEvent], _ eventlist: inout [KernelEvent], timeout: UnsafePointer<timespec>!) -> Int32 {
        return xlibc.kevent(fileDescriptor, changelist, Int32(changelist.count), &eventlist, Int32(eventlist.count), timeout)
    }
    
    @inline(__always)
    private func __kevent(_ eventlist: inout [KernelEvent], timeout: UnsafePointer<timespec>!) -> Int32 {
        return xlibc.kevent(fileDescriptor, nil, 0, &eventlist, Int32(eventlist.count), timeout)
    }
}

#endif
