
public struct NetworkInterface: CustomStringConvertible {

    public fileprivate(set)var name: String
    public fileprivate(set)var address: SocketAddress?
    public fileprivate(set)var netmask: SocketAddress?
    var _dest: SocketAddress?
    var flags: UInt32

    public var destaddr: SocketAddress? {
        return _dest
    }
    
    public var bcastaddr: SocketAddress? {
        return _dest
    }

    public init(raw: UnsafePointer<ifaddrs>) {
        name = String(cString: raw.pointee.ifa_name)
        address = SocketAddress(addr: raw.pointee.ifa_addr)
        _dest = SocketAddress(addr: raw.pointee.ifa_dstaddr)
        netmask = SocketAddress(addr: raw.pointee.ifa_netmask)
        flags = raw.pointee.ifa_flags
        
    }

    public var description: String {
        return "\(name) \(address?.description ?? "")"
    }

    @inline(__always)
    private func contains(_ f: Int32) -> Bool
    {
        return (flags & UInt32(f)) == UInt32(f)
    }

    @inline(__always)
    private func contains(_ f: Int) -> Bool
    {
        return (flags & UInt32(f)) == UInt32(f)
    }

    public var up: Bool {
        return contains(IFF_UP)
    }

    public var isVliadBoardcast: Bool {
        return contains(IFF_BROADCAST)
    }

    public var debug: Bool {
        return contains(IFF_DEBUG)
    }

    public var isLoopback: Bool {
        return contains(IFF_LOOPBACK)
    }

    public var noArp: Bool {
        return contains(IFF_NOARP)
    }

    public var promiscousMode: Bool {
        return contains(IFF_PROMISC)
    }

    public var AvoidTrailers: Bool {
        return contains(IFF_NOTRAILERS)
    }

    public var recvAllMulticast: Bool {
        return contains(IFF_ALLMULTI)
    }

    public var supportMulticast: Bool {
        return contains(IFF_MULTICAST)
    }

    public var running: Bool {
        return contains(IFF_RUNNING)
    }

    #if !os(Linux)
    public var simplex: Bool {
        return contains(IFF_SIMPLEX)
    }
    #endif

    public static var interfaces: [NetworkInterface]
    {
        var head: UnsafeMutablePointer<ifaddrs>?
        var cur: UnsafeMutablePointer<ifaddrs>?

        var intefaces = [NetworkInterface]()

        getifaddrs(&head)

        cur = head;

        while (cur != nil) {
            intefaces.append(NetworkInterface(raw: cur!))
            cur = cur!.pointee.ifa_next
        }

        freeifaddrs(head)
        return intefaces
    }

    public static func interfaces(support domains: Set<SocketDomains>) -> [NetworkInterface]
    {
        var head: UnsafeMutablePointer<ifaddrs>?
        var cur: UnsafeMutablePointer<ifaddrs>?
        var intefaces = [NetworkInterface]()

        getifaddrs(&head)

        cur = head;

        while (cur != nil) {
            if let domain = SocketDomains(rawValue: cur!.pointee.ifa_addr.pointee.sa_family) {
                if domains.contains(domain) {
                    intefaces.append(NetworkInterface(raw: cur!));
                }
            }
            cur = cur!.pointee.ifa_next
        }

        freeifaddrs(head)
        return intefaces
    }

    public static func interface(named: String, support domain: SocketDomains) -> NetworkInterface?
    {
        var head: UnsafeMutablePointer<ifaddrs>?
        var cur: UnsafeMutablePointer<ifaddrs>?

        var inteface: NetworkInterface?

        getifaddrs(&head)

        cur = head;

        while (cur != nil)
        {
            if let _domain = SocketDomains(rawValue: cur!.pointee.ifa_addr.pointee.sa_family) {
                if (_domain == domain) {
                    inteface = NetworkInterface(raw: cur!)
                }
            }
            cur = cur!.pointee.ifa_next
        }

        freeifaddrs(head)
        return inteface
    }

    public static func interfaces(named: String) -> [NetworkInterface]
    {
        var head: UnsafeMutablePointer<ifaddrs>?
        var cur: UnsafeMutablePointer<ifaddrs>?
        var intefaces = [NetworkInterface]()

        getifaddrs(&head)

        cur = head;

        while (cur != nil) {
            let name = String(cString: cur!.pointee.ifa_name)
            if name == named {
                intefaces.append(NetworkInterface(raw: cur!));
            }
            cur = cur!.pointee.ifa_next
        }

        freeifaddrs(head)
        return intefaces
    }
}

//public extension NetworkInterface {
//    public struct Flags: OptionSet {
//        public typealias RawValue = UInt32
//        public var rawValue: UInt32
//        public init(rawValue: UInt32) {
//            self.rawValue = rawValue
//        }
//        
//        public static let up = Flags(rawValue: UInt32(IFF_UP))
//        public static let boardcast = Flags(rawValue: UInt32(IFF_BROADCAST))
//        public static let debug = Flags(rawValue: UInt32(IFF_DEBUG))
//        public static let loopback = Flags(rawValue: UInt32(IFF_LOOPBACK))
//        public static let p2p = Flags(rawValue: UInt32(IFF_POINTOPOINT))
//        public static let notrailers = Flags(rawValue: UInt32(IFF_NOTRAILERS))
//        public static let running = Flags(rawValue: UInt32(IFF_RUNNING))
//        public static let noarp = Flags(rawValue: UInt32(IFF_NOARP))
//        public static let promisc = Flags(rawValue: UInt32(IFF_PROMISC))
//        public static let allmulti = Flags(rawValue: UInt32(IFF_ALLMULTI))
//        public static let oactive = Flags(rawValue: UInt32(IFF_OACTIVE))
//        public static let simplex = Flags(rawValue: UInt32(IFF_SIMPLEX))
//        public static let link0 = Flags(rawValue: UInt32(IFF_LINK0))
//        public static let link1 = Flags(rawValue: UInt32(IFF_LINK1))
//        public static let link2 = Flags(rawValue: UInt32(IFF_LINK2))
//        public static let altphys = Flags(rawValue: UInt32(IFF_ALTPHYS))
//        public static let multicast = Flags(rawValue: UInt32(IFF_MULTICAST))
//    }
//}
