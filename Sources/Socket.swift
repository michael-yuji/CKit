

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
//  Copyright © 2017 Yuji. All rights reserved.
//


public struct Socket: FileDescriptor
{
    public var fileDescriptor: Int32

    @available(*, renamed: "init")
    public init(domain: SocketDomains, type: SocketTypes, protocol ptcl: Int32)
    {
        fileDescriptor = socket(Int32(domain.rawValue), type.rawValue, ptcl)
    }

    public init(family: SocketDomains, type: SocketTypes, protocol ptcl: Int32)
    {
        fileDescriptor = socket(Int32(family.rawValue), type.rawValue, ptcl)
    }

    public init(raw: Int32)
    {
        assert(raw > 0)
        self.fileDescriptor = raw
    }

    public static func makePair(domain: SocketDomains,
                                type: SocketTypes,
                                `protocol`: Int32) throws -> (Socket, Socket)
    {
        var pair: (Int32, Int32) = (0, 0)
        _ = try sguard("socketpair") {
            socketpair(Int32(domain.rawValue),
                       type.rawValue,
                       `protocol`,
                       mutablePointer(of: &pair).cast(to: Int32.self))
        }

        return (Socket(raw: pair.0), Socket(raw: pair.1))
    }

    public var blocking: Bool
    {
        get {
            return !flags.contains(.nonblock)
        } set {
            if newValue {
                flags.remove(.nonblock)
            } else {
                flags.insert(.nonblock)
            }
        }
    }
}

extension Socket
{
    public func bind(_ addr: SocketAddress) throws
    {
        _ = try sguard("bind") {
            addr.withSockAddrPointer {
                xlibc.bind(fileDescriptor, $0, addr.socklen)
            }
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

        let fd = try sguard("accept") {
            xlibc.accept(self.fileDescriptor,
                         mutablePointer(of: &addr).cast(to: sockaddr.self),
                         &socklen)
        }

        return (Socket(raw: fd), SocketAddress(storage: addr))
    }

    public func connect(to addr: SocketAddress) throws
    {
        _ = try sguard("connect") {
            addr.withSockAddrPointer {
                xlibc.connect(fileDescriptor, $0, addr.socklen)
            }
        }
    }

    public func listen(_ backlog: Int32 = Int32(Int32.max)) throws
    {
        _ = try sguard("listen") {
            xlibc.listen(fileDescriptor, backlog)
        }
    }

    @discardableResult
    public func send(bytes: AnyPointer,
                     length: Int, flags: SendFlags) throws -> Int
    {
        return try sguard("send") {
            xlibc.send(fileDescriptor, bytes.rawPointer, length, flags.rawValue)
        }
    }

    @discardableResult
    public func recv(to buffer: AnyMutablePointer,
                     length: Int, flags: RecvFlags) throws -> Int
    {
        return try sguard("recv") {
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
        return try sguard("sendto") {
            dest.withSockAddrPointer {
                sendto(fileDescriptor, bytes.rawPointer, length,
                       flags.rawValue, $0, dest.socklen)
            }
        }
    }

    @discardableResult
    public func received(to buffer: AnyMutablePointer,
                         length: Int,
                         flags: RecvFlags)
        throws -> (sender: SocketAddress, size: Int)
    {
        var storage = _sockaddr_storage()
        let i = try sguard("recvfrom") {
            recvfrom(fileDescriptor,
                     buffer.mutableRawPointer, length, flags.rawValue,
                     mutablePointer(of: &storage).cast(to: sockaddr.self), nil)
        }
        return (sender: SocketAddress(storage: storage), size: i)
    }
}

public struct SendFlags: OptionSet
{
    public typealias RawValue = Int32
    public var rawValue: Int32
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public static let outOfBond = SendFlags(rawValue: Int32(MSG_OOB))
    public static let dontRoute = SendFlags(rawValue: Int32(MSG_DONTROUTE))
    public static let eor = SendFlags(rawValue: Int32(MSG_EOR))
    public static let dontWait = SendFlags(rawValue: Int32(MSG_DONTWAIT))
    #if !os(Linux)
    /// data completes transcation
    public static let eof = SendFlags(rawValue: MSG_EOF)
    #endif

    #if os(Linux) || os(FreeBSD)
    /// do not generate sigpipe
    public static let noSignal = SendFlags(rawValue: MSG_NOSIGNAL)
    #endif
}
public struct RecvFlags: OptionSet
{
    public typealias RawValue = Int32
    public var rawValue: Int32
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public static let outOfBond = RecvFlags(rawValue: Int32(MSG_OOB))
    public static let peek = RecvFlags(rawValue: Int32(MSG_PEEK))
    public static let waitall = RecvFlags(rawValue: Int32(MSG_WAITALL))
    public static let dontWait = RecvFlags(rawValue: Int32(MSG_DONTWAIT))
    #if os(FreeBSD)
    /// Do not block after receiving the first message (only for `recvmmsg()`)
    public static let waitForOne = RecvFlags(rawValue: MSG_WAITFORONE)
    #endif
}

extension Socket
{
    func setsock<ArgType>(opt: SocketOptions, value: ArgType)
    {
        var _val = value
        setsockopt(fileDescriptor,
                   opt.layer,
                   opt.rawValue,
                   pointer(of: &_val).rawPointer,
                   socklen_t(MemoryLayout<ArgType>.size))
    }

    func getsock<ArgType>(opt: SocketOptions) -> ArgType
    {
        var ret: ArgType!
        var size = socklen_t(MemoryLayout<ArgType>.size)
        getsockopt(fileDescriptor,
                   opt.layer,
                   opt.rawValue,
                   mutablePointer(of: &ret).mutableRawPointer,
                   &size)
        return ret
    }

    

    public var sendBufferSize: Int
    {
        get {
            return getsock(opt: .sendBufferSize)
        } 
    }

    public var recvBufferSize: Int
    {
        get {
            return getsock(opt: .recvBufferSize)
        } 
    }

    public var sendLowAt: Int
    {
        get {
            return getsock(opt: .sendLowAt)
        } 
    }

    public var recvLowAt: Int
    {
        get {
            return getsock(opt: .recvLowAt)
        } 
    }

    public var recvTimeout: timeval
    {
        get {
            return getsock(opt: .recvTimeout)
        } 
    }

    public var sendTimeout: timeval
    {
        get {
            return getsock(opt: .sendTimeout)
        } 
    }

    public var timestampEnabled: Bool
    {
        get {
            return getsock(opt: .timestampEnabled)
        } 
    }

    public var socktype: Int32
    {
        get {
            return getsock(opt: .socktype)
        } 
    }

    public var geterror: Int32
    {
        get {
            return getsock(opt: .geterror)
        } nonmutating set {
            setsock(opt: .geterror, value: newValue)
        }
    }

    public var listenStatus: Bool
    {
        get {
            return getsock(opt: .listenStatus)
        } nonmutating set {
            setsock(opt: .listenStatus, value: newValue)
        }
    }

    public var broadcast: Bool
    {
        get {
            return getsock(opt: .broadcast)
        } 
    }

    public var debug: Bool
    {
        get {
            return getsock(opt: .debug)
        } 
    }

    public var dontRoute: Bool
    {
        get {
            return getsock(opt: .dontRoute)
        } 
    }

    public var reuseaddr: Bool
    {
        get {
            return getsock(opt: .reuseaddr)
        } 
    }

    public var reuseport: Bool
    {
        get {
            return getsock(opt: .reuseport)
        } 
    }

    public var keepalive: Bool
    {
        get {
            return getsock(opt: .keepalive)
        } 
    }

    public var linger: Int
    {
        get {
            return getsock(opt: .linger)
        } 
    }

    public var oobInline: Bool
    {
        get {
            return getsock(opt: .oobInline)
        } 
    }

    #if os(FreeBSD) || os(PS4)
    public var acceptedFilter: accept_filter
    {
        get {
            return getsock(opt: .acceptedFilter)
        } 
    }

    public var `protocol`: Int32
    {
        get {
            return getsock(opt: .`protocol`)
        } nonmutating set {
            setsock(opt: .`protocol`, value: newValue)
        }
    }
    #endif

    #if os(Linux)
    public var attachFilter: sock_fprog
    {
        get {
            return getsock(opt: .attachFilter)
        } 
    }

    public var `protocol`: Int32
    {
        get {
            return getsock(opt: .`protocol`)
        } nonmutating set {
            setsock(opt: .`protocol`, value: newValue)
        }
    }
    #endif

    #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS) || os(FreeBSD) || os(PS4)
    public var noSigpipe: Bool
    {
        get {
            return getsock(opt: .noSigpipe)
        } nonmutating set {
            setsock(opt: .noSigpipe, value: newValue)
        }
    }
    #endif


    #if os(Linux)
    public static let bindedDevice = SocketOptions(SOL_SOCKET, SO_BINDTODEVICE)
    public var bindedDevice: String
    {
        get {
            return String(cString: getsock(opt: .bindedDevice))
        } set {
            newValue.withCString {
               setsockopt(fileDescriptor,
                          SOL_SOCKET,
                          SO_BINDTODEVICE,
                          $0,
                          $0.characters.count)
            }
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
    public static let attachFilter = SocketOptions(SOL_SOCKET, SO_ATTACH_BPF)
    public static let `protocol` = SocketOptions(SOL_SOCKET, SO_PROTOCOL)
    #endif
    #if os(FreeBSD) || os(PS4)
    public static let acceptedFilter = SocketOptions(SOL_SOCKET, SO_ACCEPTFILTER)
    public static let `protocol` = SocketOptions(SOL_SOCKET, SO_PROTOCOL)
    #endif
    #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS) || os(FreeBSD) || os(PS4)
    public static let noSigpipe = SocketOptions(SOL_SOCKET, SO_NOSIGPIPE)
    #endif
    public static let sendBufferSize = SocketOptions(SOL_SOCKET, SO_SNDBUF)
    public static let recvBufferSize = SocketOptions(SOL_SOCKET, SO_RCVBUF)
    public static let sendLowAt = SocketOptions(SOL_SOCKET, SO_SNDLOWAT)
    public static let recvLowAt = SocketOptions(SOL_SOCKET, SO_RCVLOWAT)
    public static let recvTimeout = SocketOptions(SOL_SOCKET, SO_RCVTIMEO)
    public static let sendTimeout = SocketOptions(SOL_SOCKET, SO_SNDTIMEO)
    public static let timestampEnabled = SocketOptions(SOL_SOCKET, SO_TIMESTAMP)
    public static let socktype = SocketOptions(SOL_SOCKET, SO_TYPE)
    public static let geterror = SocketOptions(SOL_SOCKET, SO_ERROR)
    public static let listenStatus = SocketOptions(SOL_SOCKET, SO_ACCEPTCONN)
    public static let broadcast = SocketOptions(SOL_SOCKET, SO_BROADCAST)
    public static let debug = SocketOptions(SOL_SOCKET, SO_DEBUG)
    public static let dontRoute = SocketOptions(SOL_SOCKET, SO_DONTROUTE)
    public static let reuseaddr = SocketOptions(SOL_SOCKET, SO_REUSEADDR)
    public static let reuseport = SocketOptions(SOL_SOCKET, SO_REUSEPORT)
    public static let keepalive = SocketOptions(SOL_SOCKET, SO_KEEPALIVE)
    public static let linger = SocketOptions(SOL_SOCKET, SO_LINGER)
    public static let oobInline = SocketOptions(SOL_SOCKET, SO_OOBINLINE)

}
