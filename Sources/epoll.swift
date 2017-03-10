
// The following section is just to make coding with epoll api in Xcode 
// easier, will not have any effect when build on Darwin platform
#if os(OSX)
    func epoll_create(_ i: Int) -> Int32 {
        return 0
    }
    
    public enum EPOLL_EVENTS: UInt32 {
        case EPOLLIN = 0x001
        case EPOLLPRI = 0x002
        case EPOLLOUT = 0x004
        case EPOLLRDNORM = 0x040
        case EPOLLRDBAND = 0x080
        case EPOLLWRNORM = 0x100
        case EPOLLWRBAND = 0x200
        case EPOLLMSG = 0x400
        case EPOLLERR = 0x008
        case EPOLLHUP = 0x010
        case EPOLLRDHUP = 0x2000
        case EPOLLWAKEUP = 0x20_000_000
        case EPOLLONESHOT = 0x40_000_000
        case EPOLLET = 0x80_000_000
    }
    
    public let EPOLL_CTL_ADD: Int32 = 1
    public let EPOLL_CTL_DEL: Int32 = 2
    public let EPOLL_CTL_MOD: Int32 = 3
    
    public struct epoll_event {
        public var events: UInt32
        public var data: epoll_data_t
        
        public init(events: UInt32, data: epoll_data_t) {
            self.events = events
            self.data = data
        }
        
        public init() {
            events = 0
            data = epoll_data_t(fd: 0)
        }
    }
    
    public struct epoll_data_t {
        var raw: Int = 0
        public var fd: Int32 {
            get {
                return Int32(raw)
            } set {
                raw = Int(newValue)
            }
        }
        
        public var u32: UInt32 {
            get {
                return UInt32(raw)
            } set {
                raw = Int(u32)
            }
        }
        
        public var u64: UInt64 {
            get {
                return UInt64(raw)
            } set {
                raw = Int(u32)
            }
        }
        
        public var ptr: UnsafeMutableRawPointer!
        
        public init(fd: Int32) {
            self.fd = fd
        }
        
        public init(u32: UInt32) {
            self.u32 = u32
        }
        
        public init(u64: UInt64) {
            self.u64 = u64
        }
        
        public init(ptr: UnsafeMutableRawPointer) {
            self.ptr = ptr
        }
    }
    
    public func epoll_wait(_ epfd: Int32, _ events: UnsafeMutablePointer<epoll_event>, _ maxevents: Int32, _ timeout: Int32) -> Int32 {
        return 0
    }
    
    public func epoll_ctl(_ __epfd: Int32, _ __op: Int32, _ __fd: Int32, _ __event: UnsafePointer<epoll_event>!) -> Int32 {
        return 0
    }
//    }
#endif

public struct Epoll: FileDescriptorRepresentable {
    public var fileDescriptor: Int32
    
    public struct EpollEvents : OptionSet {
        public typealias RawValue = UInt32
        public var rawValue: UInt32
        
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        public init(rawValue: EPOLL_EVENTS) {
            self.rawValue = rawValue.rawValue
        }
        
        /// The associated file is available for `read` operations
        public static let pollin = EpollEvents(rawValue: EPOLL_EVENTS.EPOLLIN)
        
        /// The associated file is available for `write` operations
        public static let pollout = EpollEvents(rawValue: EPOLL_EVENTS.EPOLLOUT)
        
        /// Stream socket peer closed connection, or shutdown writing
        /// half of connection. (This flag is especially useful for
        /// writing simple code to detect peer shutdown when using 
        /// Edge Triggered monitoring.
        public static let rdhup = EpollEvents(rawValue: EPOLL_EVENTS.EPOLLRDHUP)
        
        /// There is urgent data available for `read` operations
        public static let pri = EpollEvents(rawValue: EPOLL_EVENTS.EPOLLPRI)
        
        /// Error condition happened on the associated file descriptor.
        /// `epoll_wait` will always wait for this event; it is not 
        /// necessary to set it in `events`
        public static let err = EpollEvents(rawValue: EPOLL_EVENTS.EPOLLERR)
        
        /// Hang up happened on the associated file descriptor.
        /// `epoll_wait` will always wait for this event; it is not
        /// necessary to set it in `events`. Note that when reading
        /// from a channel such as a pipe or a stream socket, this
        /// event merely indicates that the peer closed its end of 
        /// channel. Subsequent reads from the channel will return 
        /// 0 (end of file) only after all outstanding data in the 
        /// channel has been consumed.
        public static let hup = EpollEvents(rawValue: EPOLL_EVENTS.EPOLLHUP)
        
        /// Sets the Edge Triggered behavior for the associated file
        /// descriptor. The default behavior for `epoll` is Level
        /// Triggered. See `epoll` for more detailed information
        /// about Edge and Level Triggered event distribution
        /// architectures.
        public static let edgeTrigger = EpollEvents(rawValue: EPOLL_EVENTS.EPOLLET)
    
        /// Sets the one-shot behavior for the associated file descriptor.
        /// This means that after an event is pulled out with `epoll_wait`
        /// the associated file descriptor is internally disabled and
        /// no other events will be reported by the `epoll` interface. 
        /// The user much call `epoll_ctl()` with `EPOLL_CTL_MOD` to
        /// rearm the file descriptor with a new event mask.
        public static let oneshot = EpollEvents(rawValue: EPOLL_EVENTS.EPOLLONESHOT)
        
        /// If `EPOLLONESHOT` and `EPOLLET` are clear and the process
        /// has `CAP_BLOCK_SUSPEND` capability, ensure that the system
        /// does not enter "suspend" or "hibernate" while this event
        /// is pending or being processed. The event is considered as
        /// being "processed" from the time when it is returned by a 
        /// call to `epoll_wait` descriptor, the closure of that file
        /// descriptor, the removal of the event file descriptor with
        /// `EPOLL_CTL_DEL` or the clearing of `EPOLLWAKEUP` for the 
        /// event file descriptor with `EPOLL_CTL_MOD`. See also BUGS.
        public static let wakeup = EpollEvents(rawValue: EPOLL_EVENTS.EPOLLWAKEUP)
        
        /// Sets an exclusive wakeup mode for the epoll file descriptor
        /// this is being attached to the target file descriptor, `fd`.
        /// When a wakeup event occurs and multiple epoll file descriptors
        /// are attached to the same target file using `EPOLLEXCLUSIVE`,
        /// one or more of the epoll file descriptors will receive an
        /// event with `epoll_wait`. The default in this scenario (when
        /// `EPOLLEXCLUSIVE` ts not set) is for all epoll file descriptors
        /// to receive an event. `EPOLLEXCLUSIVE` is thus useful for
        /// avoiding thundering herd problems in certain scenarios.
        ///
        /// If the same file descriptor is in multiple epoll instances, 
        /// some with the `EPOLLEXCLUSIVE` flag, and others without, then
        /// events will be provided to all epoll instances that did not
        /// specify `EPOLLEXCLUSIVE`, and at least one of the epoll 
        /// instances that did specify `EPOLLEXCLUSIVE`.
        ///
        /// The following values may be specified in conjunction with
        /// `EPOLLEXCLUSIVE: EPOLLIN, EPOLLOUT, EPOLLWAKEUP`, and `EPOLLET`.
        /// EPOLLHUP and EPOLLERR can also be specified, but this is not
        /// required: as usual, these events are always reported if they
        /// occur, regardless of whether they are specified in events.
        /// Attempts to specify other values in `events` yield an error.
        /// `EPOLLEXCLUSIVE` may be used only in an `EPOLL_CTL_ADD`
        /// operation; attempts to employ it with `EPOLL_CTL_MOD` yield an
        /// error. If `EPOLLEXCLUSIVE` has been set usng `epoll_ctl()`,
        /// then a subsequent `EPOLL_CTL_MOD` on the same `epfd`, `fd` pair
        /// yields an error. A call to `epoll_ctl()` that specifies 
        /// `EPOLLEXCLUSIVE` in `events` and specifies the target file 
        /// descriptor `fd` as an epoll instance will likewise fail. The
        /// error in all of these cases is EINVAL
//        public static let exclusive = EpollEvents(rawValue: EPOLL_EVENTS.EPOLLEXCLUSIVE)
    }
    
    public func add(fd: Int32, for events: EpollEvents) {
        var ev = epoll_event(events: events.rawValue, data: epoll_data_t(fd: fd)) // to use pointer
        epoll_ctl(self.fileDescriptor, EPOLL_CTL_ADD, fd, &ev)
    }
    
    public func remove(fd: Int32) {
        epoll_ctl(self.fileDescriptor, EPOLL_CTL_DEL, fd, nil)
    }
    
    public func wait(maxevs: Int, timeout: Int = 0) -> [epoll_event] {
        var evs = [epoll_event](repeating: epoll_event(), count: maxevs)
        let nev = epoll_wait(fileDescriptor, &evs ,Int32(maxevs), Int32(timeout))
        return Array(evs.dropLast(maxevs - Int(nev)))
    }
    
    public init() {
        fileDescriptor = epoll_create(1024)
    }
}
