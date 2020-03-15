

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


public struct NetworkInterface: CustomStringConvertible
{
  public fileprivate(set) var name: String
  public fileprivate(set) var address: SocketAddress?
  public fileprivate(set) var netmask: SocketAddress?

  var _dest: SocketAddress?
  var flags: UInt32

  public var family: SocketFamilies
  {
    return address!.family
  }

  public var destaddr: SocketAddress?
  {
    return _dest
  }

  public var bcastaddr: SocketAddress?
  {
    return _dest
  }

  public init(raw: UnsafePointer<ifaddrs>)
  {
    name = String(cString: raw.pointee.ifa_name)
    address = SocketAddress(addr: raw.pointee.ifa_addr)

    #if os(Linux)
      let dst = raw.pointee.ifa_ifu.ifu_dstaddr
    #else
      let dst = raw.pointee.ifa_dstaddr
    #endif

    if (dst != nil) {
      _dest = SocketAddress(addr: dst!)
    }
    if (raw.pointee.ifa_netmask != nil) {
      netmask = SocketAddress(addr: raw.pointee.ifa_netmask)
    }
    flags = raw.pointee.ifa_flags

  }

  public var description: String
  {
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

  @available(*, deprecated, message: "use supportBroadcast instead")
  public var isVaildBroadcast: Bool
  {
    return contains(IFF_BROADCAST) && self.address!.family == .inet
  }

  public var supportBroadcast: Bool
  {
    return contains(IFF_BROADCAST) && self.address!.family == .inet
  }


  public var up: Bool
  {
    return contains(IFF_UP)
  }

  public var debug: Bool
  {
    return contains(IFF_DEBUG)
  }

  public var isLoopback: Bool
  {
    return contains(IFF_LOOPBACK)
  }

  public var noArp: Bool
  {
    return contains(IFF_NOARP)
  }

  public var promiscousMode: Bool
  {
    return contains(IFF_PROMISC)
  }

  public var avoidTrailers: Bool
  {
    return contains(IFF_NOTRAILERS)
  }

  public var recvAllMulticast: Bool
  {
    return contains(IFF_ALLMULTI)
  }

  public var supportMulticast: Bool
  {
    return contains(IFF_MULTICAST)
  }

  public var running: Bool
  {
    return contains(IFF_RUNNING)
  }


  #if !os(Linux)
  public var simplex: Bool
  {
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

  public static func interfaces(support domains: Set<SocketDomains>)
    -> [NetworkInterface]
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

  public static func interface(named: String,
                 support domain: SocketDomains)
    -> NetworkInterface?
  {
    var head: UnsafeMutablePointer<ifaddrs>?
    var cur: UnsafeMutablePointer<ifaddrs>?

    var inteface: NetworkInterface?

    getifaddrs(&head)

    cur = head;

    while (cur != nil)
    {
      if let _domain = SocketDomains(rawValue:
        cur!.pointee.ifa_addr.pointee.sa_family) {
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
