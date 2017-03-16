
public struct NetworkInterface: CustomStringConvertible {
    
    public var name: String
    public var address: SocketAddress?
    
    var flags: UInt32
    
    public init(raw: UnsafePointer<ifaddrs>) {
        name = String(cString: raw.pointee.ifa_name)
        address = SocketAddress(addr: raw.pointee.ifa_addr)
        flags = raw.pointee.ifa_flags
    }
    
    public var description: String {
        return "Interface: \(name), : \(address?.description ?? "")"
    }
    
    @inline(__always)
    private func contains(_ f: Int32) -> Bool {
        return (flags & UInt32(f)) == UInt32(f)
    }
    
    @inline(__always)
    private func contains(_ f: Int) -> Bool {
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
        return contains(IFF_LOOPBACK) || name.hasPrefix("lo")
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
    
    public static var interfaces: [NetworkInterface] {
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
    
    public static func interfaces(support domains: Set<SocketDomains>) -> [NetworkInterface] {
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
    
    public static func interface(named: String, support domain: SocketDomains) -> NetworkInterface? {
        var head: UnsafeMutablePointer<ifaddrs>?
        var cur: UnsafeMutablePointer<ifaddrs>?
        
        var inteface: NetworkInterface?
        
        getifaddrs(&head)
        
        cur = head;
        
        while (cur != nil) {
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
    
    public static func interfaces(named: String) -> [NetworkInterface] {
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
