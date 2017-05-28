
#if os(Linux)
    let EAI_ADDRFAMILY = EAI_FAMILY
    let EAI_NODATA: Int32 = -5
    let EAI_BADHINTS = EAI_BADFLAGS
    let EAI_PROTOCOL: Int32 = 0 // does not exist counter part in Linux
    
#endif
public struct SocketAddressInfo
{
    /// The canon name of the host
    public var officialHostname: String?
    
    /// The addresses available
    public var addrs: [SocketAddress]
    
    /// Option to pass to the query
    ///
    /// - family: Specify the address family (etc inet, inet6)
    /// - type: Specify the type of the socket (etc stream dgram)
    /// - `protocol`: Additional socket protocol
    /// - fetchOriginalName: return the canon name of the hostname
    /// - fetchAll: Fetch all addresses
    /// - addrConf: Fetch intefaces this machine configurated (for example, no ipv6 will return if you have only ipv4 interfaces
    /// - flags: ai_flags in addrinfo
    /// - count: set how many maximum records
    public enum LookupOptions
    {
        case family(SocketDomains)
        case type(SocketTypes)
        case `protocol`(Int32)
        case fetchOriginalName
        case fetchAll
        case addrConf
        case flags(Int32)
        case count(Int)
    }
    
    public enum Error : Swift.Error
    {
        case addrfamily
        case temporary
        case failed
        case unsupported_family
        case memory_alloc_failed
        case not_found
        case unknown
        case unsupported_service
        case unsupported_socktype
        case system
        case badhint
        case `protocol`
        case other(Int32)
        
        init(_ i: Int32)
        {
            switch i {
            case EAI_ADDRFAMILY:
                self = .addrfamily
            case EAI_AGAIN:
                self = .temporary
            case EAI_FAIL:
                self = .failed
            case EAI_FAMILY:
                self = .unsupported_family
            case EAI_MEMORY:
                self = .memory_alloc_failed
            case EAI_NODATA:
                self = .not_found
            case EAI_NONAME:
                self = .unknown
            case EAI_SERVICE:
                self = .unsupported_service
            case EAI_SOCKTYPE:
                self = .unsupported_socktype
            case EAI_SYSTEM:
                self = .system
            case EAI_BADHINTS:
                self = .badhint
            case EAI_PROTOCOL:
                self = .protocol
            default:
                self = .other(i)
            }
        }
    }

    init(name: String? = nil, results: [SocketAddress])
    {
        self.officialHostname = name
        self.addrs = results
    }
}

public extension SocketAddressInfo
{
    /// Look up return return addresses of a host, port are set to default port of service
    ///
    /// - Parameters:
    ///   - host: The host to lookup
    ///   - service: What service, this will determine the port number
    ///   - options: Query options
    /// - Returns: a `SocketAddressInfo` that contains all SocketAddress, and canon name of the host if .fetchOriginalName is set in Options
    /// - Throws: Fail if `getaddrinfo` fails
    public static func lookup(host: String,
                              service: String,
                              options: LookupOptions...)
        throws -> SocketAddressInfo
    {
            return try lookup(host: host, service: service, options: options)
    }
    
    /// Look up return return addresses of a host
    ///
    /// - Parameters:
    ///   - host: The host to lookup
    ///   - port: the port number
    ///   - options: Query options
    /// - Returns: a `SocketAddressInfo` that contains all SocketAddress, and canon name of the host if .fetchOriginalName is set in Options
    /// - Throws: Fail if `getaddrinfo` fails
    public static func lookup(host: String,
                              port: in_port_t,
                              options: LookupOptions...)
        throws -> SocketAddressInfo
    {
            var opt = options
            opt.append(.flags(AI_NUMERICSERV))
            return try lookup(host: host, service: "\(port)",
                        options: opt)
    }

    public static func lookup(ip: String, service: String,
                              options: LookupOptions...)
        throws -> SocketAddressInfo
    {
            var opt = options
            opt.append(.flags(AI_NUMERICHOST))
            return try lookup(host: ip, service: service,
                options: options)
    }
    
    /// Get all address ready to `bind` to
    ///
    /// - Parameters:
    ///   - port: Which port
    ///   - options: Query options
    public static func bindable(port: in_port_t, options: LookupOptions...)
        throws -> SocketAddressInfo
    {
            var opt = options
            opt.append(contentsOf: [.flags(AI_PASSIVE), .flags(AI_NUMERICHOST)])
            return try lookup(host: "", service: "\(port)",
                              options: options)
    }
    
    /// Get all address ready to `bind` to
    ///
    /// - Parameters:
    ///   - service: Which service port
    ///   - options: Query options
    public static func bindable(service: String, options: LookupOptions...)
        throws -> SocketAddressInfo
    {
            var opt = options
            opt.append(.flags(AI_PASSIVE))
            return try lookup(host: "", service: service,
                options: options)
    }
    
    @inline(__always)
    static func lookup(host: String, service: String,
                       options: [LookupOptions]) throws -> SocketAddressInfo
    {
        var info: UnsafeMutablePointer<addrinfo>?
        var cinfo: UnsafeMutablePointer<addrinfo>?
        var addrs = [SocketAddress]()
        var hint = addrinfo()
        var realhost: String?
        
        var count = Int.max
        
        for option in options {
            switch option {
            case .addrConf:
                hint.ai_flags |= AI_ADDRCONFIG
            case .fetchAll:
                hint.ai_flags |= AI_ALL
            case .fetchOriginalName:
                hint.ai_flags |= AI_CANONNAME
            case let .protocol(p):
                hint.ai_protocol = p
            case let .type(t):
                hint.ai_socktype = t.rawValue
            case let .family(d):
                hint.ai_family = Int32(d.rawValue)
            case let .count(c):
                count = c
            case let .flags(c):
                hint.ai_flags |= c
            }
        }

        try host.withCString { hostp in
            try service.withCString {
                let err = getaddrinfo(hostp, $0, &hint, &info)
                switch err {
                case 0:
                    break
                case EAI_SYSTEM:
                    throw SystemError.last("getaddrinfo")
                default:
                    throw Error(err)
                }
            }
        }
        
        if info!.pointee.ai_canonname != nil {
            realhost = String(cString: info!.pointee.ai_canonname)
        }

        cinfo = info
        
        while cinfo != nil {
            cinfo = cinfo!.pointee.ai_next
            
            if cinfo == nil {
                continue
            }
            
            if let addr = cinfo!.pointee.ai_addr {
                addrs.append(SocketAddress(addr: addr))
                count -= 1
            }
            
            if count == 0 {
                break
            }
        }
        
        return SocketAddressInfo(name: realhost, results: addrs)
    }
    
}
