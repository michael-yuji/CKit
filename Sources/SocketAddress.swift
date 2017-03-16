
#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
    public let UNIX_PATH_MAX = 104
#elseif os(FreeBSD) || os(Linux)
    public let UNIX_PATH_MAX = 108
#endif

public struct SocketAddress {
    var storage: sockaddr_storage
    public init(storage: sockaddr_storage) {
        self.storage = storage
    }
}

extension SocketAddress : CustomStringConvertible {
    public var description: String {
        let family = "\(self.type)"
        var detail = ""
        switch self.type {
        case .inet, .inet6:
            detail = "\(ip()!):\(port!)"
        default:
            return family
        }
        return family + " " + detail
    }
}

extension sockaddr_in {
    init(port: in_port_t, addr: in_addr = in_addr(s_addr: 0)) {
        #if os(Linux)
            self = sockaddr_in(sin_family: sa_family_t(AF_INET),
                               sin_port: port.bigEndian,
                               sin_addr: in_addr(s_addr: 0),
                               sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        #else
            self = sockaddr_in(sin_len: UInt8(MemoryLayout<sockaddr_in>.size),
                               sin_family: sa_family_t(AF_INET),
                               sin_port: port.bigEndian,
                               sin_addr: in_addr(s_addr:0),
                               sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        #endif
    }
}

extension sockaddr_in6 {
    init(port: in_port_t, addr: in6_addr = in6addr_any) {
        #if os(Linux)
            self = sockaddr_in6(sin6_family: sa_family_t(AF_INET6),
                                sin6_port: port.bigEndian,
                                sin6_flowinfo: 0,
                                sin6_addr: addr,
                                sin6_scope_id: 0)
        #else
            self = sockaddr_in6(sin6_len: UInt8(MemoryLayout<sockaddr_in6>.size),
                                sin6_family: sa_family_t(AF_INET6),
                                sin6_port: port.bigEndian,
                                sin6_flowinfo: 0,
                                sin6_addr: addr,
                                sin6_scope_id: 0)
        #endif
    }
}

extension SocketAddress {
    public init(addr: UnsafePointer<sockaddr>) {
        self.storage = sockaddr_storage()
        memcpy(mutablePointer(of: &self.storage).mutableRawPointer, addr.rawPointer, Int(addr.pointee.sa_len))
    }
    
    public init?(domain: SocketDomains, port: in_port_t) {
        switch domain {
        case .inet:
            self.storage = sockaddr_storage()
            var addr = sockaddr_in(port: port)
            memcpy(mutablePointer(of: &self.storage).mutableRawPointer,
                   pointer(of: &addr).rawPointer,
                   MemoryLayout<sockaddr_in>.size)
            
        case .inet6:
            self.storage = sockaddr_storage()
            var addr = sockaddr_in6(port: port)
            memcpy(mutablePointer(of: &self.storage).mutableRawPointer,
                   pointer(of: &addr).rawPointer,
                   MemoryLayout<sockaddr_in>.size)
        default:
            return nil
        }
    }
    
    public init?(ip: String, domain: SocketDomains, port: in_port_t = 0) {
        switch domain {
        case .inet:
            self.storage = sockaddr_storage()
            var addr = sockaddr_in(port: port)
            inet_pton(AF_INET, ip.cString(using: .ascii),
                      mutablePointer(of: &(addr.sin_addr)).mutableRawPointer)
            memcpy(mutablePointer(of: &self.storage).mutableRawPointer,
                   pointer(of: &addr).rawPointer,
                   Int(addr.sin_len))
            
        case .inet6:
            self.storage = sockaddr_storage()
            var addr = sockaddr_in6(port: port)
            inet_pton(AF_INET6, ip.cString(using: .ascii),
                      mutablePointer(of: &(addr.sin6_addr)).mutableRawPointer)
            memcpy(mutablePointer(of: &self.storage).mutableRawPointer,
                   pointer(of: &addr).rawPointer,
                   Int(addr.sin6_len))
            
        default:
            return nil
        }
    }
    
    public init?(unixPath: String) {
        self.storage = sockaddr_storage()
        self.storage.ss_family = sa_family_t(AF_UNIX)
        #if !os(Linux)
        self.storage.ss_len = UInt8(MemoryLayout<sockaddr_un>.size)
        #endif
        strncpy(mutablePointer(of: &(self.storage.__ss_pad1)).cast(to: Int8.self),
                unixPath.cString(using: .utf8)!,
                UNIX_PATH_MAX)
    }
    
    #if !os(Linux)
    public init?(linkAddress: String) {
        self.storage = sockaddr_storage()
        self.storage.ss_family = sa_family_t(AF_LINK)
        self.storage.ss_len = UInt8(MemoryLayout<sockaddr_un>.size)
        link_addr(linkAddress.cString(using: .ascii), mutablePointer(of: &self.storage).cast(to: sockaddr_dl.self))
    }
    #endif
}

extension SocketAddress {
    public var len: socklen_t {
        return socklen_t(storage.ss_len)
    }
    
    public var type: SocketDomains {
        return SocketDomains(rawValue: storage.ss_family)!
    }
    
    public func addr() -> sockaddr {
        return unsafeBitCast(storage, to: sockaddr.self)
    }
    
    public var socklen: socklen_t {
        return socklen_t(self.storage.ss_len)
    }
    
    public mutating func addrptr() -> UnsafePointer<sockaddr> {
        return pointer(of: &storage).cast(to: sockaddr.self)
    }
    
    public var port: in_port_t? {
        switch self.type {
        case .inet:
            return unsafeBitCast(storage, to: sockaddr_in.self).sin_port.byteSwapped
        case .inet6:
            return unsafeBitCast(storage, to: sockaddr_in6.self).sin6_port.byteSwapped
        default:
            return nil
        }
    }
    
    public func ip() -> String? {
        var buffer = [Int8](repeating: 0, count: System.maximum.pathname)
        var addr = self.storage
        switch self.type {
        case .inet:
            inet_ntop(AF_INET, pointer(of: &addr).rawPointer, &buffer, self.len)
        case .inet6:
            inet_ntop(AF_INET6, pointer(of: &addr).rawPointer, &buffer, self.len)
        default:
            return nil
        }
        return String(cString: buffer)
    }
}
