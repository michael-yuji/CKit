
public struct MulticastGroup {
    
    public var address: SocketAddress

    public var interface: Interface
    
    public enum Interface {
        case ipv4(in_addr)
        case ipv6(UInt32)
        
        var _v4: in_addr! {
            switch self {
            case let .ipv4(addr):
                return addr
            default:
                return nil
            }
        }
        
        var _v6: UInt32! {
            switch self {
            case let .ipv6(index):
                return index
            default:
                return nil
            }
        }
    }
    
    public init(ipv6 addr: SocketAddress, interface: UInt32) {
        self.address = addr
        self.interface = .ipv6(interface)
    }
    
    public init(ipv4 addr: SocketAddress, interface: in_addr) {
        self.address = addr
        self.interface = .ipv4(interface)
    }
    
    public var ipv4req: ip_mreq {
        return ip_mreq(imr_multiaddr: address.inet()!.sin_addr,
                       imr_interface: interface._v4)
    }
    
    public var ipv6req: ipv6_mreq {
        return ipv6_mreq(ipv6mr_multiaddr: address.inet6()!.sin6_addr,
                         ipv6mr_interface: interface._v6)
    }
}



public struct Ipv4Ops {
    
    public static let typeOfService = SocketOptions(IPPROTO_IP, IP_TOS)
    
    public static let time2live = SocketOptions(IPPROTO_IP, IP_TTL)
    
    #if os(FreeBSD)
    public static let boardcast = SocketOptions(IPPROTO_IP, IP_ONESBCAST)

    public static let portRange = SocketOptions(IPPROTO_IP, IP_PORTRANGE)
    #endif
    
    public struct Multicast {

        public static let addMembership = SocketOptions(IPPROTO_IP, IP_ADD_MEMBERSHIP)
        
        public static let dropMembership = SocketOptions(IPPROTO_IP, IP_DROP_MEMBERSHIP)
        
        public static let loop = SocketOptions(IPPROTO_IP, IP_MULTICAST_LOOP)
        
        public static let time2live = SocketOptions(IPPROTO_IP, IP_MULTICAST_TTL)
    }
}

public struct Ipv6Ops {
    
    #if os(FreeBSD)
    public static let packetInfo = SocketOptions(IPPROTO_IPV6, IPV6_PKTINFO)
    
    public static let hopLimit = SocketOptions(IPPROTO_IPV6, IPV6_HOPLIMIT)
    
    public static let hopOpts = SocketOptions(IPPROTO_IPV6, IPV6_HOPOPTS)
    
    public static let dstOpts = SocketOptions(IPPROTO_IPV6, IPV6_DSTOPTS)
    
    public static let rthdr = SocketOptions(IPPROTO_IPV6, IPV6_RTHDR)
    
    public static let pktOptions = SocketOptions(IPPROTO_IPV6, IPV6_PKTOPTIONS)
    
    public static let ipcomp = SocketOptions(IPPROTO_IPV6, IPV6_IPCOMP_LEVEL)
    
    public static let minMTU = SocketOptions(IPPROTO_IPV6, IPV6_USE_MIN_MTU)
    
    public static let authLv = SocketOptions(IPPROTO_IPV6, IPV6_AUTH_LEVEL)

    public static let faith = SocketOptions(IPPROTO_IPV6, IPV6_FAITH)

    #else
    public static let packetInfo = SocketOptions(IPPROTO_IPV6, IPV6_2292PKTINFO)
    
    public static let hopLimit = SocketOptions(IPPROTO_IPV6, IPV6_2292HOPLIMIT)
    
    public static let hopOpts = SocketOptions(IPPROTO_IPV6, IPV6_2292HOPOPTS)
    
    public static let dstOpts = SocketOptions(IPPROTO_IPV6, IPV6_2292DSTOPTS)
    
    public static let rthdr = SocketOptions(IPPROTO_IPV6, IPV6_2292RTHDR)
    #endif

    public static let tclass = SocketOptions(IPPROTO_IPV6, IPV6_TCLASS)
    
    public static let recvTclass = SocketOptions(IPPROTO_IPV6, IPV6_RECVTCLASS)
    
    public static let checkSum = SocketOptions(IPPROTO_IPV6, IPV6_CHECKSUM)
    
    public static let v6only = SocketOptions(IPPROTO_IPV6, IPV6_V6ONLY)
    
    
    public struct Unicast {
        public static let hops = SocketOptions(IPPROTO_IPV6, IPV6_UNICAST_HOPS)
    }
    
    public struct Multicast {
        public static let interface = SocketOptions(IPPROTO_IPV6, IPV6_MULTICAST_IF)
        public static let hops = SocketOptions(IPPROTO_IPV6, IPV6_MULTICAST_HOPS)
        public static let loop = SocketOptions(IPPROTO_IPV6, IPV6_MULTICAST_LOOP)
        public static let joinGroup = SocketOptions(IPPROTO_IPV6, IPV6_JOIN_GROUP)
        public static let leaveGroup = SocketOptions(IPPROTO_IPV6, IPV6_LEAVE_GROUP)
        
    }
}


extension Socket {
    public func joinMulticast(group: MulticastGroup) {
        switch group.interface {
        case .ipv4:
            setsock(opt: Ipv4Ops.Multicast.addMembership, value: group.ipv4req)
        case .ipv6:
            setsock(opt: Ipv6Ops.Multicast.joinGroup, value: group.ipv6req)
        }
    }
    
    public func leaveMulticast(group: MulticastGroup) {
        switch group.interface {
        case .ipv4:
            setsock(opt: Ipv4Ops.Multicast.dropMembership, value: group.ipv4req)
        case .ipv6:
            setsock(opt: Ipv6Ops.Multicast.leaveGroup, value: group.ipv6req)
        }
    }
}
