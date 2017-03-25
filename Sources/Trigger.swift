public struct Trigger {
    
    var kq: Int32
    
    init() {
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
        kevent(kq, &triggerEv, 1, nil, 0, nil)
        #elseif os(Linux) || os(Android)
        eventfd_write(kq, 1)
        #endif
    }
    
    public func wait() {
        #if os(FreeBSD) || os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
        var t = KernelEvent()
        kevent(kq, nil, 0, &t, 1, nil)
        #elseif os(Linux) || os(Android)
        var pfd = pollfd(fd: kq, events: Int16(POLLIN), revents: 0)
        poll(&pfd, 1, 0)
        #endif
    }
}
