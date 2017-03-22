
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
    var data: __kqueue_data
    
    class __kqueue_data {
        public var pending = [KernelEvent]()
        var lock = pthread_mutex_t()
        public init() {
            pthread_mutex_init(&self.lock, nil)
        }
        
        deinit {
            _ = xlibc.pthread_mutex_destroy(&self.lock)
        }
    }
    
    public init() {
        self.fileDescriptor = xlibc.kqueue()
        self.data = __kqueue_data()
    }
}

extension KernelQueue {
    
    public func enqueue(event descriptor: KernelEventDescriptor, for actions: KernelEventAction) {
        data.pending.append(descriptor.makeEvent(actions))
    }
    
    public func add(event descriptor: KernelEventDescriptor, enable: Bool, oneshot: Bool) {
        var alist: KernelEventAction = .add
        if enable {
            alist = alist.union(.enable)
        }
        
        if oneshot {
            alist = alist.union(.oneshot)
        }
        data.pending.append(descriptor.makeEvent([.add]))
    }
    
    public func remove(event descriptor: KernelEventDescriptor) {
        data.pending.append(descriptor.makeEvent([.delete]))
    }

    public func wait(nevs: Int, timeout: timespec? = nil, handler: (KernelEventResult) -> ()) throws {
        var evs = [KernelEvent](repeating: KernelEvent(), count: nevs)
        
        let nev = try throwsys("kevent") { () -> Int32 in
            var timeptr: UnsafePointer<timespec>!
            if var timeout = timeout {
                timeptr = pointer(of: &timeout)
            }
            return kevent(fileDescriptor, data.pending, Int32(data.pending.count), &evs, Int32(nevs), timeptr)
        }
        
        _ = xlibc.pthread_mutex_lock(mutablePointer(of: &data.lock))
        data.pending.removeAll()
        _ = xlibc.pthread_mutex_unlock(mutablePointer(of: &data.lock))
        
        for i in 0..<Int(nev) {
            handler(unsafeBitCast(evs[i], to: KernelEventResult.self))
        }
    }
}
    
#endif
