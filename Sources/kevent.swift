

typealias _kev = xlibc.kevent

public extension xlibc.kevent {
    
    public static func readEvent(_ ident: Int32, action: Action, udata: UnsafeMutableRawPointer? = nil) -> kevent {
        return _kev(ident: UInt(ident),
                    filter: kevent.Filter.read.rawValue,
                    flags: action.rawValue,
                    fflags: 0, data: 0,
                    udata: udata)
    }
    
    public static func writeEvent(_ ident: Int32, action: Action, udata: UnsafeMutableRawPointer? = nil) -> kevent {
        return _kev(ident: UInt(ident),
                    filter: kevent.Filter.write.rawValue,
                    flags: action.rawValue,
                    fflags: 0, data: 0,
                    udata: udata)
    }
    
    public static func fileEvent(_ ident: Int32, action: Action, filter: kevent.FilterFlags.Vnode, udata: UnsafeMutableRawPointer? = nil) -> kevent {
        return _kev(ident: UInt(ident),
                    filter: kevent.Filter.write.rawValue,
                    flags: action.rawValue,
                    fflags: filter.rawValue,
                    data: 0, udata: udata)
    }
    
    public static func processEvent(_ pid: pid_t, action: Action, filter: kevent.FilterFlags.Proccess, udata: UnsafeMutableRawPointer? = nil) -> kevent {
        return _kev(ident: UInt(pid),
                    filter: kevent.Filter.proc.rawValue,
                    flags: action.rawValue,
                    fflags: filter.rawValue, data: 0,
                    udata: udata)
    }
    
    public static func signalEvent(_ signal: Int32, action: Action, udata: UnsafeMutableRawPointer? = nil) -> kevent {
        return _kev(ident: UInt(signal),
                    filter: kevent.Filter.signal.rawValue,
                    flags: action.rawValue,
                    fflags: 0, data: 0,
                    udata: udata)
    }
    
    public static func timerEvent(id: UInt, action: Action, timeout: Int, unit: FilterFlags.Timer, udata: UnsafeMutableRawPointer? = nil) -> kevent {
        return _kev(ident: id,
                    filter: Filter.timer.rawValue,
                    flags: action.rawValue,
                    fflags: unit.rawValue,
                    data: timeout, udata: udata)
    }
    
    public struct Action: OptionSet {
        public typealias RawValue = UInt16
        public var rawValue: UInt16
        
        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }
        
        public init(rawValue: Int32) {
            self.rawValue = UInt16(rawValue)
        }
        
        public static let add = Action(rawValue: EV_ADD)
        public static let delete = Action(rawValue: EV_DELETE)
        public static let enable = Action(rawValue: EV_ENABLE)
        public static let disable = Action(rawValue: EV_DISABLE)
        public static let dispatch = Action (rawValue: EV_DISPATCH)
        public static let receipt = Action(rawValue: EV_RECEIPT)
        public static let oneshot = Action(rawValue: EV_ONESHOT)
        public static let clear = Action(rawValue: EV_CLEAR)
        public static let outOfBand = Action(rawValue: EV_OOBAND)
        public static let error = Action(rawValue: EV_ERROR)
        public static let eof = Action(rawValue: EV_EOF)
    }
    
    public struct FilterFlags
    {
        public struct Vnode: RawRepresentable {
            public typealias RawValue = UInt32
            public var rawValue: UInt32
            public init(rawValue: Int32) {
                self.rawValue = UInt32(rawValue)
            }
            
            public init(rawValue: UInt32) {
                self.rawValue = rawValue
            }
            
            public static let attributesChanged = Vnode(rawValue: NOTE_ATTRIB)
            public static let delete = Vnode(rawValue: NOTE_DELETE)
            public static let extend = Vnode(rawValue: NOTE_EXTEND)
            public static let link = Vnode(rawValue: NOTE_LINK)
            public static let rename = Vnode(rawValue: NOTE_RENAME)
            public static let revote = Vnode(rawValue: NOTE_REVOKE)
            public static let write = Vnode(rawValue: NOTE_WRITE)
        }
        
        public struct Proccess: RawRepresentable {
            public typealias RawValue = UInt32
            public var rawValue: UInt32
            
            public init(rawValue: UInt32) {
                self.rawValue = rawValue
            }
            
            public init(rawValue: Int32) {
                self.rawValue = UInt32(rawValue)
            }
            
            public static let exit = Proccess(rawValue: NOTE_EXIT)
            public static let fork = Proccess(rawValue: NOTE_FORK)
            public static let exec = Proccess(rawValue: NOTE_EXEC)
            public static let track = Proccess(rawValue: NOTE_TRACK)
        }
        
        public struct Timer: RawRepresentable {
            public typealias RawValue = UInt32
            public var rawValue: UInt32
            public init(rawValue: UInt32) {
                self.rawValue = rawValue
            }
            
            public init(rawValue: Int32) {
                self.rawValue = UInt32(rawValue)
            }
            
            public static let seconds = Timer(rawValue: NOTE_SECONDS)
            public static let macroseconds = Timer(rawValue: NOTE_USECONDS)
            public static let nanoseconds = Timer(rawValue: NOTE_NSECONDS)
        }
        
        public struct User: RawRepresentable {
            public typealias RawValue = UInt32
            public var rawValue: UInt32
            
            public init(rawValue: Int32) {
                self.rawValue = UInt32(rawValue)
            }
            
            public init(rawValue: UInt32) {
                self.rawValue = rawValue
            }
            
            public static let ignore = User(rawValue: NOTE_FFNOP)
            public static let bitand = User(rawValue: NOTE_FFAND)
            public static let bitor = User(rawValue: NOTE_FFOR)
            public static let copy = User(rawValue: NOTE_FFNOP)
            public static let cntrlmask = User(rawValue: NOTE_FFCTRLMASK)
            public static let flagsmask = User(rawValue: NOTE_FFLAGSMASK)
            public static let trigger = User(rawValue: NOTE_TRIGGER)
        }
    }
    
    public struct Filter: OptionSet {
        
        public typealias RawValue = Int16
        public var rawValue: Int16
        public init(rawValue: Int16) {
            self.rawValue = rawValue
        }
        
        public init(rawValue: Int32) {
            self.rawValue = Int16(rawValue)
        }
        
        /// Takes a file descriptor as the identifier, and returns whenever there
        /// is data available to read. The behavior of the filter is slightly
        /// different depending on descriptor type.
        ///
        /// *Sockets*
        ///
        /// Socket which have previously been passed to `listen()` return when there
        /// is an incoming connection pending. `data` contains the size of the listen
        /// backlog.
        /// Other socket descriptors return when there is data to be read, subject to
        /// the SO_RCVLOWAT value of the socket buffer. This maybe overridden with a
        /// per-filter low water mark at the time the filter is added by setting the
        /// `NOTE_LOWAT` flag in `fflags`, and specifying the new low water mark in
        /// `data`. On return `data` contains the number of bytes of protocol data
        /// available to read.
        /// If the read direction of the socket has shutdown, then the filter also sets
        /// `EV_EOF` in `flags`, and returns the socket error (if any) in fflags. It is
        /// possible for EOF to be returned (indicating the connection is gone) while
        /// there is still data pending in the socket buffer.
        ///
        /// *Vnodes*
        ///
        /// Returns when the file pointer is not at the end of file. `data` contains the
        /// offset from current position to end of file, and may be negative.
        /// This behavior is different from `poll`, where read events are triggered for
        /// regular files unconditionally. This event can be triggered unconditionally by
        /// setting the `NOTE_FILE_POLL` (FreeBSD) flag in `fflags`.
        ///
        /// *Fifos, Pipes*
        ///
        /// Returns when the there is data to read; `data` contains the numener of bytes
        /// available.
        /// When the last writer disconnects, the filter will set EV_EOF in `flags`. This
        /// may be cleared by passing in `EV_CLEAR`, at which point the filter will resume
        /// waiting for data to become available before returning.
        ///
        /// *Device nodes (OS X)*
        ///
        /// Returns when there is data to read from the device; `data` contains the number
        /// of bytes available. If the device does not support returning number of bytes, it
        /// will not allow the filter to be attached. However, if the `NOTE_LOWAT` flag is
        /// specified and the `data` field contains 1 on input, those devices will attach
        /// count of bytes to read on output.
        ///
        /// *BPF devices (FreeBSD)*
        ///
        /// Returns when the BPF buffer is full, the `BPF` timeout has expired, or when the BPF
        /// has `immediate mode` enabled and these is any data to read; `data` contains the
        /// number of bytes available.
        public static let read = Filter(rawValue: EVFILT_READ)
        
        /// Takes a file descriptor as the identifier, and returns whenever it is
        /// possible to write to the descriptor. For sockets, pipes and fifos, `data`
        /// will contain the amount of space remaining in the write buffer. The filter
        /// will set `EV_EOF` when the reader disconnects, and for the fifo case, this
        /// may be cleared by use of `EV_CLEAR`. Note that this filter is not supported
        /// for vnodes.
        ///
        /// For sockets, the low water mark and socket error handling is identical to the
        /// `EVFILT_READ` case
        public static let write = Filter(rawValue: EVFILT_WRITE)
        
        /// The sigevent portion of the AIO request is filled in, with `sigev_notify_kqueue`
        /// containing the kevent flags which should be `EV_ONESHOT`, `EV_CLEAR`, or
        /// `EV_DISPATCH`, `sigev_value` containing the udata value, and `sigev_notify` set
        /// to `SIGEV_KEVENT`. When the `aio_*()` system call is made, the event will be
        /// registered with the specified kqueue, and the ident argument set to the
        /// `struct aiocb` returned by the `aio_*()` system call. The filter returns under
        /// the same conditions as `aio_error()`.
        ///
        /// Absolute useless in Darwin, aka Apple Platform since it's not implemented.
        public static let aio = Filter(rawValue: EVFILT_AIO)
        
        /// In Darwin, Returns when the file pointer is not at the end of file. `data` contains
        /// the offset from current position to end of file, and maybe negative.
        ///
        /// In BSD, Takes a file descriptor as the identifier and the events to watch for in
        /// `fflags`, and returns when one or more of the requested events occurs on the
        /// descriptor. The events to monitor are:
        ///
        /// *NOTE_ATTRIB*
        ///
        /// The file referenced by the descriptor had its attributes changed.
        ///
        /// *NOTE_CLOSE*
        ///
        /// A file descriptor referencing the monitored file, was closed. The closed file
        /// descriptor did not have write access.
        ///
        /// *NOTE_CLOSE_WRITE*
        ///
        /// A file descriptor referencing the monitored file, was closed. The closed file
        /// descriptor has write access.
        ///
        /// This note, as well as `NOTE_CLOSE`, are not activated when files are closed forcibly
        /// by `unmount` or `revoke`. Instead, `NOTE_REVOKE` is sent for such events.
        ///
        /// *NOTE_DELETE*
        ///
        /// The `unlink()` system call was called on the file referenced by the descriptor.
        ///
        /// *NOTE_EXTEND*
        ///
        /// For regular file, the file referenced by the descriptor was extended.
        ///
        /// For directory, reports that a directory entry was added or removed, as the result
        /// of rename operation. The `NOTE_EXTEND` event is not reported when a name is changed
        /// inside the directory.
        ///
        /// *NOTE_LINK*
        ///
        /// The link count on the file changed. In particular, the `NOTE_LINK` event is reported
        /// if a subdirectory was created pr de;eted inside the directory referenced by the
        /// descriptor.
        ///
        /// *NOTE_OPEN*
        ///
        /// The file referenced by the descriptor was opened.
        ///
        /// *NOTE_READ*
        ///
        /// A read occurred on the file referenced by the descriptor.
        ///
        /// *NOTE_RENAME*
        ///
        /// The file referenced by the descriptor was renamed
        ///
        /// *NOTE_REVOKE*
        ///
        /// Access to the file was revoked via `revoke(2)` or the underlying file system was
        /// unmounted.
        ///
        /// *NOTE_WRITE*
        ///
        /// A write occurred on the file referenced by the descriptor.
        ///
        /// On return, `fflags` contains the events which triggered the filter.
        public static let vnode = Filter(rawValue: EVFILT_VNODE)
        
        
        /// Takes the process ID to monitor as the identifier and the events to watch
        /// for in `fflags`, and returns when the process performs one or more of the
        /// requested events. If a process can normally see another process, it can
        /// attach an event to it. The events to monitor are:
        ///
        /// *NOTE_EXIT*
        ///
        /// The process has exited. The exit status will be stored in `data`.
        ///
        /// *NOTE_FORK*
        ///
        /// The process created a child process via `fork()` or similar call.
        ///
        /// *NOTE_EXEC*
        ///
        /// The process executed a new process via `execve` or similar call.
        ///
        /// *NOTE_SIGNAL*
        ///
        /// The process was sent a signal. Status can be checked via waitpid or similar call.
        public static let proc = Filter(rawValue: EVFILT_PROC)
        
        
        /// Takes the signal number to monitor as the identifier and returns when the
        /// given signal is delivered to the process. This coexists with the `signal()`
        /// and `sigaction()` facilities, and has a lower precedence. Only signals
        /// sent to the process, not to a particular thread, will trigger and the
        /// filter. The filter will record all attempts to deliver a signal to a
        /// process, even if the signal has been marked as `SIG_IGN`. Event notification
        /// happends before normal signal delivery processing. `data` returns the number
        /// of times the signal has been generated since the last call to `kevent()`.
        /// This filter automatically sets the `EV_CLEAR` flag internally.
        public static let signal = Filter(rawValue: EVFILT_SIGNAL)
        
        
        /// Establishes an arbitrary timer identified by `ident`. When adding a timer,
        /// `data` specifies the timeout period. The timer will be periodic unless `EV_ONESHOT`
        /// is specified. On return, `data` contains the number of times the timeout has
        /// expired since the last call to `kevent()`. This filter automatically sets
        /// the `EV_CLEAR` flag internally. There is a system wide limit on the number
        /// of timers which is controlled by the `kern.kq_calloutmax` sysctl (FreeBSD).
        ///
        /// *NOTE_SECONDS*
        ///
        /// `data` is in seconds.
        ///
        /// *NOTE_MSECONDS*
        ///
        /// `data` is in milliseconds.
        ///
        /// *NOTE_USECONDS*
        ///
        /// `data` is in microseconds.
        ///
        /// *NOTE_NSECONDS*
        ///
        /// `data` is in nanoseconds.
        ///
        /// *NOTE_ABSOLUTE (Darwin)*
        ///
        /// `data` is an absolute timeout
        ///
        /// *NOTE_CRITICAL (Darwin)*
        ///
        /// system makes a best effort to fire this timer as scheduled.
        ///
        /// *NOTE_BACKGROUND (Darwin)*
        ///
        /// system has extra leeway to coalesce this timer.
        ///
        /// *NOTE_LEEWAY (Darwin)*
        ///
        /// exit[1] holds user-supplied slop in deadline for timer coalescing.
        ///
        /// If `fflags` is not set, the default is milliseconds. On return, fflags
        /// contains the events which triggered the filter.
        public static let timer = Filter(rawValue: EVFILT_TIMER)
        
        
        /// Establishes a user event identified by `ident` which is not associated with
        /// any kernel mechanism but is triggered by user level code. The lower 24 bits
        /// of the fflags may be used for user defined flags and manipulated using the
        /// following:
        ///
        /// *NOTE_FFNOP*
        ///
        /// Ignore the input fflags.
        ///
        /// *NOTE_FFAND*
        ///
        /// Bitwise AND fflags.
        ///
        /// *NOTE_FFCOPY*
        ///
        /// Copy `fflags`.
        ///
        /// *NOTE_FFCTRLMASK*
        ///
        /// Control mask for fflags
        ///
        /// *NOTE_FFLAGSMASK*
        ///
        /// User defined flag mask for fflags.
        ///
        /// A user event is triggered for output with the following:
        ///
        /// *NOTE_TRIFFER*
        ///
        /// Cause the event to be triffered/
        public static let user = Filter(rawValue: EVFILT_USER)
        
        #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
        /// Takes the name of a mach port, or port set, in `ident` and waits until a
        /// message is enqueued on the port or port set. When a message is detected,
        /// but not directly received by the kevent call, the name of the specific port
        /// where the message is enqueued is returned in `data`. If `fflags` contains
        /// `MACH_RCV_MSG`, the `ext[0]` and `ext[1]` flags are assumed to contain
        /// a pointer to the buffer where the message is to be received and the size
        /// of the receive buffer, respectively. If `MACH_RCV_MSG` is specified,
        /// yet the buffer size in `ext[1]` is zero, The space for the buffer may be
        /// carved out of the data_out area provided to `kevent_qos() if there is enough
        /// space remaining there.
        public static let machPort = Filter(rawValue: EVFILT_MACHPORT)
        
        /// The following has not documented in either Darwin nor FreeBSD
        //        public static let fileSystem = Filter(rawValue: EVFILT_FS)
        //        public static let virtualMemory = Filter(rawValue: EVFILT_VM)
        #endif
        
        
        
        /// Takes a descriptor as the identifier, and returns whenever one of the
        /// specified exceptional conditions has occurred on the descriptor. Conditions
        /// are specified in `fflags`. Currently, this filter can be used to monitor the
        /// arrival of out-of-band data on a socket descriptor using the filter flag
        /// `NOTE_OOB`
        ///
        /// If the read direction of the socket has shutdown, then the filter also set
        /// `EV_EOF` in `flags`, and returns the socket error (if any) in `fflags`.
        public static let exception = Filter(rawValue: EVFILT_EXCEPT)
        
    }
}
