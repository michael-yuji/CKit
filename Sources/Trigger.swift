
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
//  Created by yuuji on 3/27/17.
//

@available(*, renamed: "Switch", message: "renamed to Switch")
public typealias Trigger = Switch

public struct Switch {
    
    var kq: Int32
    
    public init() {
        #if os(FreeBSD) || os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
        kq = kqueue()
        var ev = KernelEvent(ident: 0,
                             filter: _evfilt_user,
                             flags: UInt16(EV_ADD | EV_ONESHOT),
                             fflags: NOTE_FFCOPY,
                             data: 0, udata: nil)
        kevent(kq, &ev, 1, nil, 0, nil)
        #elseif os(Linux) || os(Android)
        kq = eventfd(0,0)
        #endif
    }
    
    public init(_ fd: Int32)
    {
        kq = fd
        #if os(FreeBSD) || os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
        var ev = KernelEvent(ident: 0,
                             filter: _evfilt_user,
                             flags: UInt16(EV_ADD | EV_ONESHOT),
                             fflags: NOTE_FFCOPY,
                             data: 0, udata: nil)
        kevent(kq, &ev, 1, nil, 0, nil)
        #elseif os(Linux) || os(Android)
        kq = eventfd(0,0)
        #endif
    }
    
    @available(*, renamed: "toggle", message: "renamed to toggle()")
    public func trigger() {
        toggle()
    }
    
    public func toggle() {
        #if os(FreeBSD) || os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
        var triggerEv = KernelEventDescriptor
            .user(ident: 0, options: .trigger)
            .makeEvent(.enable)
            
        if kevent(kq, &triggerEv, 1, nil, 0, nil) == -1 {
            return
        }
        #elseif os(Linux) || os(Android)
        eventfd_write(kq, 1)
        #endif
    }
    
    public func wait() {
        #if os(FreeBSD) || os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
        var t = KernelEvent()
        var ev = KernelEvent(ident: 0, filter: _evfilt_user,
                             flags: UInt16(EV_ADD | EV_ONESHOT),
                             fflags: NOTE_FFCOPY,
                             data: 0, udata: nil)
        
        kevent(kq, nil, 0, &t, 1, nil)
        kevent(kq, &ev, 1, nil, 0, nil)
        
        #elseif os(Linux) || os(Android)
        var val: eventfd_t = 0
        eventfd_read(kq, &val)
        #endif
    }
    
    public func close() {
        _ = xlibc.close(kq)
    }
}
