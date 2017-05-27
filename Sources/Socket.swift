
public struct Socket : FileDescriptorRepresentable
{
    public var fileDescriptor: Int32
    
    @available(*, renamed: "init")
    public init(domain: SocketDomains, type: SocketTypes, protocol: Int32)
    {
        fileDescriptor = socket(Int32(domain.rawValue),
                                type.rawValue, `protocol`)
    }
    
    public init(family: SocketDomains, type: SocketTypes, protocol: Int32)
    {
        fileDescriptor = socket(Int32(family.rawValue),
                                type.rawValue, `protocol`)
    }
    
    public init(raw: Int32)
    {
        assert(raw > 0)
        self.fileDescriptor = raw
    }
    
    public static func makePair(domain: SocketDomains,
                                type: SocketTypes, `protocol`: Int32)
        throws -> (Socket, Socket)
    {
        var pair = [Int32](repeating: 0, count: 2)
        
        _ = try guarding("socketpair") {
            xlibc.socketpair(Int32(domain.rawValue), type.rawValue,
                             `protocol`, &pair)
        }
        
        return (Socket(raw: pair[0]), Socket(raw: pair[1]))
    }
    
    public var blocking: Bool
    {
        get {
            return !self.flags.contains(.nonblock)
        } set {
            if newValue {
                self.flags.remove(.nonblock)
            } else {
                self.flags.insert(.nonblock)
            }
        }
    }
}

public struct RecvFlags: OptionSet
{
    public typealias RawValue = Int32
    public var rawValue: Int32
    public init(rawValue: Int32)
    {
        self.rawValue = rawValue
    }
    
    public init(rawValue: Int)
    {
        self.rawValue = Int32(rawValue)
    }
    
    /// process out of band data
    public static let outOfBand = RecvFlags(rawValue: MSG_OOB)
    
    /// peek at incoming message
    public static let peek = RecvFlags(rawValue: MSG_PEEK)

    /// wait for full request or error
    public static let waitall = RecvFlags(rawValue: MSG_WAITALL)
    
    /// do not block
    public static let dontWait = RecvFlags(rawValue: MSG_DONTWAIT)
    
    public static let none = RecvFlags(rawValue: 0)
    
    #if os(FreeBSD)
    /// Do not block after receiving the first message (only for `recvmmsg()`)
    public static let waitForOne = RecvFlags(rawValue: MSG_WAITFORONE)
    #endif
}

public struct SendFlags: OptionSet
{
    public typealias RawValue = Int32
    public var rawValue: Int32
    public init(rawValue: Int32)
    {
        self.rawValue = rawValue
    }
    
    public init(rawValue: Int)
    {
        self.rawValue = Int32(rawValue)
    }
    
    /// process out-of-band data
    public static let outOfBond = SendFlags(rawValue: MSG_OOB)
    
    /// Bypass routing, use direct interface
    public static let dontRoute = SendFlags(rawValue: MSG_DONTROUTE)
    
    /// data completes record
    public static let eor = SendFlags(rawValue: MSG_EOR)
    
    #if !os(Linux)
    /// data completes transcation
    public static let eof = SendFlags(rawValue: MSG_EOF)
    #endif
    
    /// do not block
    public static let dontWait = SendFlags(rawValue: MSG_DONTWAIT)
    
    public static let none = SendFlags(rawValue: 0)
    
    #if os(Linux) || os(FreeBSD)
    
    /// do not generate sigpipe
    public static let noSignal = SendFlags(rawValue: MSG_NOSIGNAL)
    #endif
}

extension Socket {
    
    public func bind(_ addr: SocketAddress) throws
    {
        var addr = addr
        _ = try guarding("bind") {
            xlibc.bind(fileDescriptor, addr.addrptr(), addr.socklen)
        }
    }
    
    public func bind(_ addr: SocketAddress, port: in_port_t)
    {
        switch addr.type {
        case .inet:
            guard var inet = addr.inet() else {
                return
            }
            getpagesize()
            inet.sin_port = port.byteSwapped
            _ = xlibc.bind(fileDescriptor,
                           pointer(of: &inet).cast(to: sockaddr.self),
                           addr.socklen)
        case .inet6:
            guard var inet6 = addr.inet6() else {
                return
            }
            inet6.sin6_port = port.byteSwapped
            _ = xlibc.bind(fileDescriptor,
                           pointer(of: &inet6).cast(to: sockaddr.self),
                           addr.socklen)
        default:
            break
        }
    }
    
    public func accept() throws -> (Socket, SocketAddress)
    {
        var addr = _sockaddr_storage()
        var socklen: socklen_t = 0
        
        let fd = try guarding("accept") {
            xlibc.accept(self.fileDescriptor,
                         mutablePointer(of: &addr).cast(to: sockaddr.self),
                         &socklen)
        }
        
        return (Socket(raw: fd), SocketAddress(storage: addr))
    }
    
    public func connect(to addr: SocketAddress) throws
    {
        var addr = addr
        _ = try guarding("connect") {
            xlibc.connect(fileDescriptor, addr.addrptr(), addr.socklen)
        }
    }
    
    public func listen(_ backlog: Int32 = Int32(Int32.max)) throws
    {
        _ = try guarding("listen") {
            xlibc.listen(fileDescriptor, backlog)
        }
    }
    
    @discardableResult
    public func send(bytes: AnyPointer,
                     length: Int, flags: SendFlags) throws -> Int
    {
        return try guarding("send") {
            xlibc.send(fileDescriptor, bytes.rawPointer, length, flags.rawValue)
        }
    }
    
    @discardableResult
    public func recv(to buffer: AnyMutablePointer,
                     length: Int, flags: RecvFlags) throws -> Int {
        return try guarding("recv") {
            xlibc.recv(fileDescriptor,
                       buffer.mutableRawPointer,
                       length, flags.rawValue)
        }
    }
    
    @discardableResult
    public func send(to dest: SocketAddress,
                     bytes: AnyPointer,
                     length: Int, flags: SendFlags) throws -> Int
    {
        var dest = dest
        return try guarding("sendto") {
            sendto(fileDescriptor, bytes.rawPointer, length,
                   flags.rawValue, dest.addrptr(), dest.socklen)
        }
    }
    
    @discardableResult
    public func received(to buffer: AnyMutablePointer,
                         length: Int,
                         flags: RecvFlags)
        throws -> (sender: SocketAddress, size: Int)
    {
        var storage = _sockaddr_storage()
        let i = try guarding("recvfrom") {
            recvfrom(fileDescriptor,
                     buffer.mutableRawPointer, length, flags.rawValue,
                     mutablePointer(of: &storage).cast(to: sockaddr.self), nil)
        }
        
        return (sender: SocketAddress(storage: storage), size: i)
    }
}

extension Socket
{
    func setsock<ArgType>(opt: SocketOptions, value: ArgType)
    {
        var _val = value
        setsockopt(fileDescriptor, opt.layer, opt.rawValue,
                   pointer(of: &_val).rawPointer,
                   socklen_t(MemoryLayout<ArgType>.size))
    }
    
    func getsock<ArgType>(opt: SocketOptions) -> ArgType
    {
        var ret: ArgType!
        var size = socklen_t(MemoryLayout<ArgType>.size)
        getsockopt(fileDescriptor, opt.layer, opt.rawValue,
                   mutablePointer(of: &ret).mutableRawPointer, &size)
        return ret
    }
    
    /// enables local address reuse
    public var reuseaddr: Bool
    {
        get {
            return getsock(opt: .reuseaddr)
        } nonmutating set {
            setsock(opt: .reuseaddr, value: newValue)
        }
    }
    
    /// enables duplicate address and port binding
    public var reuseport: Bool
    {
        get {
            return getsock(opt: .reuseport)
        } nonmutating set {
            setsock(opt: .reuseport, value: newValue)
        }
    }
    
    /// set buffer size for output
    public var sendBufferSize: Int
    {
        get {
            return getsock(opt: .sendBuffer)
        } nonmutating set {
            setsock(opt: .sendBuffer, value: newValue)
        }
    }
    
    /// set buffer size for input
    public var recvBufferSize: Int
    {
        get {
            return getsock(opt: .recvBuffer)
        } nonmutating set {
            setsock(opt: .recvBuffer, value: newValue)
        }
    }
    
    /// Enables recording of debugging information
    public var debug: Bool
    {
        get {
            return getsock(opt: .debug)
        } nonmutating set {
            setsock(opt: .debug, value: newValue)
        }
    }
    
    /// set timeout for output
    public var sendTimeout: timeval
    {
        get {
            return getsock(opt: .sendTimeout)
        } nonmutating set {
            setsock(opt: .sendTimeout, value: newValue)
        }
    }
    
    /// set timeout for input
    public var recvTimeout: timeval
    {
        get {
            return getsock(opt: .recvTimeout)
        } nonmutating set {
            setsock(opt: .recvTimeout, value: newValue)
        }
    }
    
    /// enables keep connections alive
    public var keepalive: Bool
    {
        get {
            return getsock(opt: .keepalive)
        } nonmutating set {
            setsock(opt: .keepalive, value: newValue)
        }
    }
    
    /// enables permission to transmit broadcast messages
    public var broadcast: Bool
    {
        get {
            return getsock(opt: .broadcast)
        } nonmutating set {
            setsock(opt: .broadcast, value: newValue)
        }
    }
    
    #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS) || os(FreeBSD)
    /// do not generate SIGPIPE, instead return EPIPE
    public var noSigpipe: Bool
    {
        get {
            return getsock(opt: .nosigpipe)
        } nonmutating set {
            setsock(opt: .nosigpipe, value: newValue)
        }
    }
    #endif
    
}

public struct SocketOptions: RawRepresentable
{
    public typealias RawValue = Int32
    public var rawValue: Int32
    public var layer: Int32
    
    public init(rawValue: Int32)
    {
        self.rawValue = rawValue
        self.layer = SOL_SOCKET
    }
    
    public init(_ layer: Int32, _ rawValue: Int32)
    {
        self.layer = layer
        self.rawValue = rawValue
    }

    public init(_ layer: Int, _ rawValue: Int32)
    {
        self.layer = Int32(layer)
        self.rawValue = rawValue
    }

    public init(_ layer: UInt32, _ rawValue: Int32)
    {
        self.layer = Int32(layer)
        self.rawValue = rawValue
    }
    
    #if os(Linux)
    public static let acceptFilter = SocketOptions(rawValue: SO_ATTACH_BPF)
    public static let bind2device = SocketOptions(rawValue: SO_BINDTODEVICE)
    public static let `protocol` = SocketOptions(rawValue: SO_PROTOCOL)
    #endif
    
    #if os(FreeBSD)
    public static let acceptFilter = SocketOptions(rawValue: SO_ACCEPTFILTER)
    public static let `protocol` = SocketOptions(rawValue: SO_PROTOCOL)
    public static let routingTable = SocketOptions(rawValue: SO_SETFIB)
    #endif
    
    #if os(FreeBSD) || os(OSX) || os(watchOS) || os(tvOS) || os(iOS)
    public static let nosigpipe = SocketOptions(SOL_SOCKET, SO_NOSIGPIPE)
    #endif

    public static let sendBuffer = SocketOptions(SOL_SOCKET, SO_SNDBUF)
    
    public static let recvBuffer = SocketOptions(SOL_SOCKET, SO_RCVBUF)
    
    public static let sendLowAt = SocketOptions(SOL_SOCKET, SO_SNDLOWAT)
    
    public static let recvLowAt = SocketOptions(SOL_SOCKET, SO_RCVLOWAT)
    
    public static let sendTimeout = SocketOptions(SOL_SOCKET, SO_SNDTIMEO)
    
    public static let recvTimeout = SocketOptions(SOL_SOCKET, SO_RCVTIMEO)
    
    public static let timestamp = SocketOptions(SOL_SOCKET, SO_TIMESTAMP)
    
    public static let socktype = SocketOptions(SOL_SOCKET, SO_TYPE)
    
    public static let geterror = SocketOptions(SOL_SOCKET, SO_ERROR)
    
    public static let listenStatus = SocketOptions(SOL_SOCKET, SO_ACCEPTCONN)
    
    public static let broadcast = SocketOptions(SOL_SOCKET, SO_BROADCAST)
    
    public static let debug = SocketOptions(SOL_SOCKET, SO_DEBUG)
    
    public static let dontroute = SocketOptions(SOL_SOCKET, SO_DONTROUTE)
    
    public static let reuseaddr = SocketOptions(SOL_SOCKET, SO_REUSEADDR)
    
    public static let reuseport = SocketOptions(SOL_SOCKET, SO_REUSEPORT)
    
    public static let keepalive = SocketOptions(SOL_SOCKET, SO_KEEPALIVE)
    
    public static let linger = SocketOptions(SOL_SOCKET, SO_LINGER)
    
    public static let oobInline = SocketOptions(SOL_SOCKET, SO_OOBINLINE)
}
