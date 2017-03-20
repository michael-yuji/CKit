
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
    public var pending = [KernelEvent]()
    var lock = pthread_mutex_t()
    public init() {
        fileDescriptor = kqueue()
        pthread_mutex_init(&self.lock, nil)
    }
}

extension KernelQueue {
    
    public mutating func enqueue(event descriptor: KernelEventDescriptor, for actions: KernelEventAction) {
        pending.append(descriptor.makeEvent(actions))
    }
    
    public mutating func add(event descriptor: KernelEventDescriptor, enable: Bool, oneshot: Bool) {
        var alist: KernelEventAction = .add
        if enable {
            alist = alist.union(.enable)
        }
        
        if enable {
            alist = alist.union(.oneshot)
        }
        pending.append(descriptor.makeEvent([.add]))
    }
    
    public mutating func remove(event descriptor: KernelEventDescriptor) {
        pending.append(descriptor.makeEvent([.delete]))
    }

    public mutating func wait(nevs: Int, timeout: timespec, handler: (KernelEventResult) -> ()) throws {
        var evs = [KernelEvent](repeating: KernelEvent(), count: nevs)
        
        let nev = try throwsys("kevent") { () -> Int32 in
            var t = timeout
            return kevent(fileDescriptor, pending, Int32(pending.count), &evs, Int32(nevs), &t)
        }
        
        for i in 0..<Int(nev) {
            handler(unsafeBitCast(evs[i], to: KernelEventResult.self))
        }
    }
    
    public mutating func wait(nevs: Int, handler: (KernelEventResult) -> ()) throws {
        var evs = [KernelEvent](repeating: KernelEvent(), count: nevs)
        
        let nev = try throwsys("kevent") { () -> Int32 in
            return kevent(fileDescriptor, pending, Int32(pending.count), &evs, Int32(nevs), nil)
        }
        
        _ = xlibc.pthread_mutex_lock(mutablePointer(of: &lock))
        pending.removeAll()
        _ = xlibc.pthread_mutex_unlock(mutablePointer(of: &lock))
        for i in 0..<Int(nev) {
            handler(unsafeBitCast(evs[i], to: KernelEventResult.self))
        }
    }

}
    
/// a c like kqueue
public struct UnmanagedKernelQueue: FileDescriptorRepresentable {
    public var fileDescriptor: Int32
    
    public init() {
        fileDescriptor = xlibc.kqueue()
    }
    
    /// add events to the the queue, but not monitor yet
    public func add(events: [kevent]) throws {
        _ = try throwsys("kevent") {
            kevent(fileDescriptor, events, Int32(events.count), nil, 0, nil)
        }
    }
    
    /// Monitor events with timeout
    ///
    /// - Parameters:
    ///   - maxevs: maximum events to monitor
    ///   - timeout: the timeout, nil if no timeout
    /// - Returns: events triggered
    /// - Throws: if kevent returns error
    public func wait(maxevs: Int, timeout: timespec?) throws -> [kevent] {
        var evs = [KernelEvent](repeating: KernelEvent(), count: maxevs)
        
        let nev = try throwsys("kevent") { () -> Int32 in
            guard var t = timeout else {
                return kevent(fileDescriptor, nil, 0, &evs, Int32(maxevs), nil)
            }
            return kevent(fileDescriptor, nil, 0, &evs, Int32(maxevs), &t)
        }
        
        return Array<KernelEvent>(evs.dropLast(maxevs - Int(nev)))
    }
    
    public func wait(moreEv ievs: [kevent], maxevs: Int, timeout: timespec?) throws -> [kevent] {
        let mx = max(maxevs, ievs.count)
        var evs = [KernelEvent](repeating: KernelEvent(), count: mx)
        
        let nev = try throwsys("kevent") { () -> Int32 in
            guard var t = timeout else {
                return kevent(fileDescriptor, ievs, Int32(ievs.count), &evs, Int32(maxevs), nil)
            }
            return kevent(fileDescriptor, nil, 0, &evs, Int32(maxevs), &t)
        }
        
        return Array<KernelEvent>(evs.dropLast(maxevs - Int(nev)))
    }
}

#endif
