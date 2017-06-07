
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
//  Created by Yuji on 3/10/16.
//  Copyright © 2016 Yuji. All rights reserved.
//

// The following section is just to make coding with epoll api in Xcode
// easier, will not have any effect when build on Darwin platform
#if os(OSX)
    func epoll_create(_ i: Int) -> Int32
    {
        return 0
    }
    
    public struct EPOLL_EVENTS: RawRepresentable
    {
        public typealias RawValue = UInt32
        public var rawValue: UInt32
        
        public init(rawValue: UInt32)
        {
            self.rawValue = rawValue
        }
    }
    
    public let EPOLLIN = EPOLL_EVENTS(rawValue: 0x001)
    public let EPOLLPRI = EPOLL_EVENTS(rawValue: 0x002)
    public let EPOLLOUT = EPOLL_EVENTS(rawValue: 0x004)
    public let EPOLLRDNORM = EPOLL_EVENTS(rawValue: 0x040)
    public let EPOLLRDBAND = EPOLL_EVENTS(rawValue: 0x080)
    public let EPOLLWRNORM = EPOLL_EVENTS(rawValue: 0x100)
    public let EPOLLWRBAND = EPOLL_EVENTS(rawValue: 0x200)
    public let EPOLLMSG = EPOLL_EVENTS(rawValue: 0x400)
    public let EPOLLERR = EPOLL_EVENTS(rawValue: 0x008)
    public let EPOLLHUP = EPOLL_EVENTS(rawValue: 0x010)
    public let EPOLLRDHUP = EPOLL_EVENTS(rawValue: 0x2000)
    public let EPOLLWAKEUP = EPOLL_EVENTS(rawValue: 0x20_000_000)
    public let EPOLLONESHOT = EPOLL_EVENTS(rawValue: 0x40_000_000)
    public let EPOLLET = EPOLL_EVENTS(rawValue: 0x80_000_000)

    public let EPOLL_CTL_ADD: Int32 = 1
    public let EPOLL_CTL_DEL: Int32 = 2
    public let EPOLL_CTL_MOD: Int32 = 3
    
    public struct epoll_event
    {
        public var events: UInt32
        public var data: epoll_data_t
        
        public init(events: UInt32, data: epoll_data_t)
        {
            self.events = events
            self.data = data
        }
        
        public init()
        {
            events = 0
            data = epoll_data_t(fd: 0)
        }
    }
    
    public struct epoll_data_t
    {
        var raw: Int = 0
        
        public var fd: Int32
        {
            get {
                return Int32(raw)
            } set {
                raw = Int(newValue)
            }
        }
        
        public var u32: UInt32
        {
            get {
                return UInt32(raw)
            } set {
                raw = Int(u32)
            }
        }
        
        public var u64: UInt64
        {
            get {
                return UInt64(raw)
            } set {
                raw = Int(u32)
            }
        }
        
        public init(fd: Int32)
        {
            self.fd = fd
        }
        
        public init(u32: UInt32)
        {
            self.u32 = u32
        }
        
        public init(u64: UInt64)
        {
            self.u64 = u64
        }
        
        public init(ptr: UnsafeMutableRawPointer)
        {
            self.raw = ptr.integerValue
        }
    }
    
    // emulating epoll_wait
    public func epoll_wait(_ epfd: Int32,
                           _ events: UnsafeMutablePointer<epoll_event>,
                           _ maxevents: Int32,
                           _ timeout: Int32) -> Int32
    {
        fatalError()
    }
    
    public func epoll_ctl(_ __epfd: Int32,
                          _ __op: Int32,
                          _ __fd: Int32,
                          _ __event: UnsafePointer<epoll_event>!) -> Int32
    {
        fatalError()
    }
#endif
