public struct Trigger {
    
    var kq: Int32
    
    public init() {
        #if os(FreeBSD) || os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
        kq = kqueue()
        let event = KernelEventDescriptor.user(ident: 0, options: .none)
        var ev = event.makeEvent([.add, .enable])
        kevent(kq, &ev, 1, nil, 0, nil)
        #elseif os(Linux) || os(Android)
        kq = eventfd(0,0)
        #endif
    }
    
    public func trigger() {
        #if os(FreeBSD) || os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
        var triggerEv = KernelEventDescriptor.user(ident: 0, options: .trigger).makeEvent(.add)
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
        if kevent(kq, nil, 0, &t, 1, nil) == -1 {
            return
        }
        #elseif os(Linux) || os(Android)
        var pfd = pollfd(fd: kq, events: Int16(POLLIN), revents: 0)
        if poll(&pfd, 1, 0) == -1 {
            return
        }
        var val: eventfd_t = 0
        eventfd_read(kq, &val)
        #endif
    }
    
    public func close() {
        _ = xlibc.close(kq)
    }
}
