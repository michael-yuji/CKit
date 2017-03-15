
public struct Socket : FileDescriptorRepresentable {
    public var fileDescriptor: Int32
    
    public init(domain: SocketDomains, type: SocketTypes, protocol: Int32) {
        fileDescriptor = socket(domain.rawValue,
                                type.rawValue, `protocol`)
    }
    
    public init(raw: Int32) {
        assert(raw > 0)
        self.fileDescriptor = raw
    }
}

public struct RecvFlags: OptionSet {
    public typealias RawValue = Int32
    public var rawValue: Int32
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    /// process out of band data
    public static let outOfBand = RecvFlags(rawValue: MSG_OOB)
    
    /// peek at incoming message
    public static let peek = RecvFlags(rawValue: MSG_PEEK)
    
    /// wait for full request or error
    public static let waitall = RecvFlags(rawValue: MSG_WAITALL)
    
    /// do not block
    public static let dontWait = RecvFlags(rawValue: MSG_DONTWAIT)
    
    #if os(FreeBSD)
    /// Do not block after receiving the first message (only for `recvmmsg()`)
    public static let waitForOne = RecvFlags(rawValue: MSG_WAITFORONE)
    #endif
}

public struct SendFlags: OptionSet {
    public typealias RawValue = Int32
    public var rawValue: Int32
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    /// process out-of-band data
    public static let outOfBond = SendFlags(rawValue: MSG_OOB)
    
    /// Bypass routing, use direct interface
    public static let dontRoute = SendFlags(rawValue: MSG_DONTROUTE)
    
    /// data completes record
    public static let eor = SendFlags(rawValue: MSG_EOR)
    
    /// data completes transcation
    public static let eof = SendFlags(rawValue: MSG_EOF)
    
//    #if os(Linux) || os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
    /// do not block
    public static let dontWait = SendFlags(rawValue: MSG_DONTWAIT)
//    #endif
    
    #if os(Linux) || os(FreeBSD)
    
    /// do not generate sigpipe
    public static let noSignal = SendFlags(rawValue: MSG_NOSIGNAL)
    #endif
}

extension Socket {
    public func send(bytes: PointerType, length: Int, flags: SendFlags) throws -> Int {
        return try throwsys("send") {
            xlibc.send(fileDescriptor, bytes.rawPointer, length, flags.rawValue)
        }
    }
    
    public func recv(to buffer: MutablePointerType, length: Int, flags: RecvFlags) throws -> Int {
        return try throwsys("send") {
            xlibc.recv(fileDescriptor, buffer.mutableRawPointer, length, flags.rawValue)
        }
    }
    
//    public func send(to address: sockaddr_storage, bytes: PointerType, length: Int, flags: SendFlags) throws -> Int {
//        
//    }
}

extension Socket {
    
    func setsock<ArgType>(opt: SocketOptions, value: ArgType) {
        var _val = value
        setsockopt(fileDescriptor, SOL_SOCKET, opt.rawValue, pointer(of: &_val).rawPointer, socklen_t(MemoryLayout<ArgType>.size))
    }
    
    func getsock<ArgType>(opt: SocketOptions) -> ArgType {
        var ret: ArgType!
        var size = socklen_t(MemoryLayout<ArgType>.size)
        getsockopt(fileDescriptor, SOL_SOCKET, opt.rawValue, mutablePointer(of: &ret).mutableRawPointer, &size)
        return ret
    }
    
    /// enables local address reuse
    public var reuseaddr: Bool {
        get {
            return getsock(opt: .reuseaddr)
        } set {
            setsock(opt: .reuseaddr, value: newValue)
        }
    }
    
    /// enables duplicate address and port binding
    public var reuseport: Bool {
        get {
            return getsock(opt: .reuseport)
        } set {
            setsock(opt: .reuseport, value: newValue)
        }
    }
    
    /// set buffer size for output
    public var sendBufferSize: Int {
        get {
            return getsock(opt: .sendBuffer)
        } set {
            setsock(opt: .sendBuffer, value: newValue)
        }
    }
    
    /// set buffer size for input
    public var recvBufferSize: Int {
        get {
            return getsock(opt: .recvBuffer)
        } set {
            setsock(opt: .recvBuffer, value: newValue)
        }
    }
    
    /// Enables recording of debugging information
    public var debug: Bool {
        get {
            return getsock(opt: .debug)
        } set {
            setsock(opt: .debug, value: newValue)
        }
    }
    
    /// set timeout for output
    public var sendTimeout: timeval {
        get {
            return getsock(opt: .sendTimeout)
        } set {
            setsock(opt: .sendTimeout, value: newValue)
        }
    }
    
    /// set timeout for input
    public var recvTimeout: timeval {
        get {
            return getsock(opt: .recvTimeout)
        } set {
            setsock(opt: .recvTimeout, value: newValue)
        }
    }
    
    /// enables keep connections alive
    public var keepalive: Bool {
        get {
            return getsock(opt: .keepalive)
        } set {
            setsock(opt: .keepalive, value: newValue)
        }
    }
    
    /// enables permission to transmit broadcast messages
    public var broadcast: Bool {
        get {
            return getsock(opt: .broadcast)
        } set {
            setsock(opt: .broadcast, value: newValue)
        }
    }
    
    #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS) || os(FreeBSD)
    /// do not generate SIGPIPE, instead return EPIPE
    public var noSigpipe: Bool {
        get {
            return getsock(opt: .nosigpipe)
        } set {
            setsock(opt: .nosigpipe, value: newValue)
        }
    }
    #endif
    
}

public struct SocketOptions: RawRepresentable {
    
    public typealias RawValue = Int32
    public var rawValue: Int32
    public init(rawValue: Int32) {
        self.rawValue = rawValue
        
    }
    
    #if os(Linux)
    public static let acceptFilter = SocketOptions(rawValue: SO_ATTACH_BPF)
    public static let bind2device = SocketOptions(rawValue: SO_BINDTODEVICE)
    public static let `protocol` = SocketOptions(rawValue: SO_PROTOTYPE)
    #endif
    
    #if os(FreeBSD)
    public static let acceptFilter = SocketOptions(rawValue: SO_ACCEPTFILTER)
    public static let `protocol` = SocketOptions(rawValue: SO_PROTOCOL)
    public static let routingTable = SocketOptions(rawValue: SO_SETFIB)
    #endif
    
    #if os(FreeBSD) || os(OSX) || os(watchOS) || os(tvOS) || os(iOS)
    public static let nosigpipe = SocketOptions(rawValue: SO_NOSIGPIPE)
    #endif

    public static let sendBuffer = SocketOptions(rawValue: SO_SNDBUF)
    public static let recvBuffer = SocketOptions(rawValue: SO_RCVBUF)
    public static let sendLowAt = SocketOptions(rawValue: SO_SNDLOWAT)
    public static let recvLowAt = SocketOptions(rawValue: SO_RCVLOWAT)
    public static let sendTimeout = SocketOptions(rawValue: SO_SNDTIMEO)
    public static let recvTimeout = SocketOptions(rawValue: SO_RCVTIMEO)
    public static let timestamp = SocketOptions(rawValue: SO_TIMESTAMP)
    public static let socktype = SocketOptions(rawValue: SO_TYPE)
    public static let geterror = SocketOptions(rawValue: SO_ERROR)
    public static let listenStatus = SocketOptions(rawValue: SO_ACCEPTCONN)
    public static let broadcast = SocketOptions(rawValue: SO_BROADCAST)
    public static let debug = SocketOptions(rawValue: SO_DEBUG)
    public static let dontroute = SocketOptions(rawValue: SO_DONTROUTE)
    public static let reuseaddr = SocketOptions(rawValue: SO_REUSEADDR)
    public static let reuseport = SocketOptions(rawValue: SO_REUSEPORT)
    public static let keepalive = SocketOptions(rawValue: SO_KEEPALIVE)
    public static let linger = SocketOptions(rawValue: SO_LINGER)
    public static let oobInline = SocketOptions(rawValue: SO_OOBINLINE)
}
