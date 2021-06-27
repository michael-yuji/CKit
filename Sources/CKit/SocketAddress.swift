
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


#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
  public let UNIX_PATH_MAX = 104
#elseif os(FreeBSD) || os(Linux)
  public let UNIX_PATH_MAX = 108
#endif

// MARK: CustomStringConvertible
extension SocketAddress : CustomStringConvertible
{
  public var description: String {
    let family = "\(self.type)"
    var detail = ""
    switch self.type {
    case .inet, .inet6:
      detail = "\(ip!):\(port!)"
    default:
      return family
    }
    return family + " " + detail
  }
}

public struct SocketAddress
{
  enum __sockaddr {
  case addr(sockaddr)
  case inet(sockaddr_in)
  case inet6(sockaddr_in6)
  case unix(sockaddr_un)
  case link(sockaddr_dl)
  }

  var storage: __sockaddr
}

extension SocketAddress
{
  public init(storage: sockaddr_storage)
  {
    var storage = storage
    switch storage.ss_family {
    case sa_family_t(AF_INET):
      self.storage = withUnsafePointer(to: &storage) {
        .inet($0.cast(to: sockaddr_in.self).pointee)
      }
    case sa_family_t(AF_INET6):
      self.storage = withUnsafePointer(to: &storage) {
        .inet6($0.cast(to: sockaddr_in6.self).pointee)
      }
    case sa_family_t(AF_UNIX):
      self.storage = withUnsafePointer(to: &storage) {
        .unix($0.cast(to: sockaddr_un.self).pointee)
      }
    case sa_family_t(AF_LINK):
      self.storage = withUnsafePointer(to: &storage) {
        .link($0.cast(to: sockaddr_dl.self).pointee)
      }

    default:
      self.storage = withUnsafePointer(to: &storage, {
        .addr($0.cast(to: sockaddr.self).pointee)
      })
    }
  }

  public init(addr: UnsafePointer<sockaddr>, port: in_port_t? = nil)
  {
    switch addr.pointee.sa_family {

    case sa_family_t(AF_UNSPEC):
      self.storage = .addr(addr.cast(to: sockaddr.self).pointee)
    case sa_family_t(AF_INET):
      self.storage = .inet(addr.cast(to: sockaddr_in.self).pointee)
    case sa_family_t(AF_INET6):
      self.storage = .inet6(addr.cast(to: sockaddr_in6.self).pointee)
    case sa_family_t(AF_UNIX):
      self.storage = .unix(addr.cast(to: sockaddr_un.self).pointee)
    case sa_family_t(AF_LINK):
      self.storage = .link(addr.cast(to: sockaddr_dl.self).pointee)

    default:
      self.storage = .addr(addr.pointee)
    }
  }

  public init?(domain: SocketFamilies, port: in_port_t)
  {
    switch domain {
    case .inet:
      self.storage = .inet(sockaddr_in(port: port))
    case .inet6:
      self.storage = .inet6(sockaddr_in6(port: port))
    default:
      return nil
    }
  }

  public init?(ip: String, domain: SocketFamilies, port: in_port_t = 0)
  {
    switch domain {
    case .inet:
      var inet = sockaddr_in(port: port)

      _ = ip.withCString {
        inet_pton(AF_INET, $0,mutableRawPointer(of: &(inet.sin_addr)))
      }

      self.storage = .inet(inet)

    case .inet6:
      var inet6 = sockaddr_in6(port: port)

      _ = ip.withCString {
        inet_pton(AF_INET6, $0, mutableRawPointer(of: &(inet6.sin6_addr)))
      }

      self.storage = .inet6(inet6)

    default:
      return nil
    }
  }

  public init(unixPath: String)
  {
    var unix = sockaddr_un()
    #if !os(Linux)
      unix.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
    #endif
    unix.sun_family = sa_family_t(AF_UNIX)
    unixPath.withCString {
      memcpy(mutablePointer(of: &(unix.sun_path)),
           $0,
           unixPath.count)
    }
    self.storage = .unix(unix)
  }

  #if !os(Linux)
  public init?(linkAddress: String)
  {
    self.storage = .link(sockaddr_dl())
    if case var .link(dl) = self.storage {
      dl.sdl_family = sa_family_t(AF_LINK)
      dl.sdl_len = UInt8(MemoryLayout<sockaddr_un>.size)
      linkAddress.withCString {
        link_addr($0, &dl)
      }
    }
  }
  #endif
}

extension SocketAddress
{
  @available(*, renamed: "family")
  public var type: SocketFamilies
  {
    return family
  }

  public var family: SocketFamilies
  {
    switch self.storage {
    case .inet:
      return .inet
    case .inet6:
      return .inet6
    case .unix:
      return .unix
    case .link:
      return .link
    case let .addr(addr):
      return SocketFamilies(rawValue: addr.sa_family)!
    }
  }

  public func addrptr() -> UnsafePointer<sockaddr>
  {
    return withSockAddrPointer {
      $0
    }
  }

  public func withSockAddrPointer<R>(_ blk: (UnsafePointer<sockaddr>) -> R) -> R
  {
    switch self.storage {
    case var .addr(addr):
      return blk(pointer(of: &addr))
    case var .inet(inet):
      return blk(pointer(of: &inet).cast(to: sockaddr.self))
    case var .inet6(inet6):
      return blk(pointer(of: &inet6).cast(to: sockaddr.self))
    case var .unix(unix):
      return blk(pointer(of: &unix).cast(to: sockaddr.self))
    case var .link(link):
      return blk(pointer(of: &link).cast(to: sockaddr.self))
    }
  }

  public func addr() -> sockaddr
  {
    switch self.storage {
    case let .addr(addr):
      return addr
    case let .inet(inet):
      return reinterept_cast(from: inet, to: sockaddr.self)
    case let .inet6(inet6):
      return reinterept_cast(from: inet6, to: sockaddr.self)
    case let .unix(unix):
      return reinterept_cast(from: unix, to: sockaddr.self)
    case let .link(link):
      return reinterept_cast(from: link, to: sockaddr.self)
    }
  }
  public func inet() -> sockaddr_in?
  {
    guard case let .inet(inet) = self.storage else {
      return nil
    }
    return inet
  }
  public func inet6() -> sockaddr_in6?
  {
    guard case let .inet6(inet6) = self.storage else {
      return nil
    }
    return inet6
  }
  public func unix() -> sockaddr_un?
  {
    guard case let .unix(unix) = self.storage else {
      return nil
    }
    return unix
  }
  public func link() -> sockaddr_dl?
  {
    guard case let .link(link) = self.storage else {
      return nil
    }
    return link
  }

  public var socklen: socklen_t
  {
    switch family {

    case .inet:
      return socklen_t(MemoryLayout<sockaddr_in>.size)
    case .inet6:
      return socklen_t(MemoryLayout<sockaddr_in6>.size)
    case .unix:
      return socklen_t(MemoryLayout<sockaddr_un>.size)
    case .link:
      return socklen_t(MemoryLayout<sockaddr_dl>.size)

    default:
      return socklen_t(MemoryLayout<sockaddr>.size)
    }
  }

  /// Get the port number of the address if available
  public var port: in_port_t?
  {
    switch self.storage {
    case let .inet(inet):
      return inet.sin_port.bigEndian

    case let .inet6(inet6):
      return inet6.sin6_port.bigEndian

    default:
      return nil
    }
  }

  /// Get the ip address if availble
  public var ip: String?
  {
    var buffer = [Int8](repeating: 0, count: Int(INET6_ADDRSTRLEN))

    switch self.storage {
    case var .inet(inet):
      inet_ntop(AF_INET, &inet.sin_addr, &buffer, UInt32(INET_ADDRSTRLEN))

    case var .inet6(inet6):
      inet_ntop(AF_INET6, &inet6.sin6_addr, &buffer, UInt32(INET6_ADDRSTRLEN))

    default:
      return nil
    }
    return String(cString: buffer)
  }

  /// Get the path of the unix domain socket address if posible
  public var path: String?
  {
    guard case var .unix(unix) = self.storage else {
      return nil
    }

    return String(cString: pointer(of: &unix.sun_path).cast(to: Int8.self))
  }
}

extension SocketAddress: Equatable
{
  public static func ==(lhs: SocketAddress, rhs: SocketAddress) -> Bool
  {
    //    switch lhs.storage {
    //    case let .inet(lhs):
    //      guard case let .inet(rhs) = rhs.storage else {
    //        return false
    //      }
    //      return lhs.sin_addr.s_addr == rhs.sin_addr.s_addr
    //      && lhs.sin_family == rhs.sin_family
    //      && lhs.sin_len == rhs.sin_len
    //      && lhs.sin_port == rhs.sin_port
    //      && lhs.sin_zero.0 == lhs.sin_zero.0
    //      && lhs.sin_zero.1 == lhs.sin_zero.1
    //      && lhs.sin_zero.2 == lhs.sin_zero.2
    //      && lhs.sin_zero.3 == lhs.sin_zero.3
    //      && lhs.sin_zero.4 == lhs.sin_zero.4
    //      && lhs.sin_zero.5 == lhs.sin_zero.5
    //      && lhs.sin_zero.6 == lhs.sin_zero.6
    //      && lhs.sin_zero.7 == lhs.sin_zero.7
    //
    //    case let .inet6(lhs):
    //      guard case let .inet6(rhs) = rhs.storage else {
    //        return false
    //      }
    //
    //      return lhs.sin6_addr.__u6_addr.__u6_addr32.0
    //        == rhs.sin6_addr.__u6_addr.__u6_addr32.0
    //        && lhs.sin6_addr.__u6_addr.__u6_addr32.1
    //        == rhs.sin6_addr.__u6_addr.__u6_addr32.1
    //        && lhs.sin6_addr.__u6_addr.__u6_addr32.2
    //        == rhs.sin6_addr.__u6_addr.__u6_addr32.2
    //        && lhs.sin6_addr.__u6_addr.__u6_addr32.3
    //        == rhs.sin6_addr.__u6_addr.__u6_addr32.3
    //      && lhs.sin6_family == rhs.sin6_family
    //      && lhs.sin6_len == rhs.sin6_len
    //      && lhs.sin6_flowinfo == rhs.sin6_flowinfo
    //      && lhs.sin6_port == rhs.sin6_port
    //      && lhs.sin6_scope_id == rhs.sin6_scope_id
    //
    //    case var .unix(lhs):
    //      guard case var .unix(rhs) = rhs.storage else {
    //        return false
    //      }
    //
    //      return lhs.sun_family == rhs.sun_family
    //      && lhs.sun_len == rhs.sun_len
    //      && (strcmp(pointer(of: &lhs.sun_path).cast(to: Int8.self), (pointer(of: &rhs.sun_path).cast(to: Int8.self))) == 0)
    //
    //    default:
    //      return false
    //    }
    var lhs = lhs
    var rhs = rhs
    return memcmp(&lhs.storage, &rhs.storage,
            MemoryLayout<__sockaddr>.size) == 0
  }

  private func _check_masked(lhs: UInt32, rhs: UInt32, bits: UInt32) -> Bool
  {
    guard bits <= 32 else {
      return false
    }
    // use this to erase the host part
    let bitsEraser = (~((1 << (33 - bits)) - 1)).bigEndian
    return (UInt32(bitsEraser) & lhs) == (UInt32(bitsEraser) & rhs)
  }

  @inline(__always)
  private func prefix_mask(_ first_nonzero: UInt32) -> UInt32
  {
    return ~((1 << (33 - first_nonzero)) - 1)
  }

  private func _is_in_subnet_v4(lhs: in_addr_t,
                  rhs: in_addr_t,
                  mask: in_addr_t) -> Bool
  {
    return mask & lhs == mask & rhs
  }

  private func _is_in_subnet_v6(lhs: in6_addr,
                  rhs: in6_addr,
                  mask: in6_addr) -> Bool
  {
    #if os(Linux)
    return mask.__in6_u.__u6_addr32.0 & lhs.__in6_u.__u6_addr32.0
      == mask.__in6_u.__u6_addr32.0 & rhs.__in6_u.__u6_addr32.0
      && mask.__in6_u.__u6_addr32.1 & lhs.__in6_u.__u6_addr32.1
      == mask.__in6_u.__u6_addr32.1 & rhs.__in6_u.__u6_addr32.1
      && mask.__in6_u.__u6_addr32.2 & lhs.__in6_u.__u6_addr32.2
      == mask.__in6_u.__u6_addr32.2 & rhs.__in6_u.__u6_addr32.2
      && mask.__in6_u.__u6_addr32.3 & lhs.__in6_u.__u6_addr32.3
      == mask.__in6_u.__u6_addr32.3 & rhs.__in6_u.__u6_addr32.3
    #endif

    #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS) || os(FreeBSD) || os(PS4)
    return mask.__u6_addr.__u6_addr32.0 & lhs.__u6_addr.__u6_addr32.0
      == mask.__u6_addr.__u6_addr32.0 & rhs.__u6_addr.__u6_addr32.0
      && mask.__u6_addr.__u6_addr32.1 & lhs.__u6_addr.__u6_addr32.1
      == mask.__u6_addr.__u6_addr32.1 & rhs.__u6_addr.__u6_addr32.1
      && mask.__u6_addr.__u6_addr32.2 & lhs.__u6_addr.__u6_addr32.2
      == mask.__u6_addr.__u6_addr32.2 & rhs.__u6_addr.__u6_addr32.2
      && mask.__u6_addr.__u6_addr32.3 & lhs.__u6_addr.__u6_addr32.3
      == mask.__u6_addr.__u6_addr32.3 & rhs.__u6_addr.__u6_addr32.3
    #endif

  }

  private func _v6_make_mask(_ mask: UInt32) -> in6_addr
  {
    #if os(Linux)
    typealias __u6 = in6_addr.__Unnamed_union___in6_u

    typealias u32 = UInt32
    let max = u32.max
    let make_u32: (u32) -> u32 = { ~((1 << u32(($0) - mask)) - 1) }
    let _0: u32 = mask >= 32 ? max : make_u32(32)
    let _1: u32 = mask <= 32 ? 0 : mask >= 64 ? max : make_u32(64 + 1)
    let _2: u32 = mask <= 64 ? 0 : mask >= 96 ? max : make_u32(96 + 1)
    let _3: u32 = mask <= 96 ? 0 : mask >= 128 ? max : make_u32(128 + 1)

    return in6_addr(__in6_u: __u6(__u6_addr32:
      (_0.bigEndian, _1.bigEndian, _2.bigEndian, _3.bigEndian)
    ))
    #endif
    #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS) || os(FreeBSD) || os(PS4)
    typealias __u6 = in6_addr.__Unnamed_union___u6_addr

    typealias u32 = UInt32
    let max = u32.max
    let make_u32: (u32) -> u32 = { ~((1 << u32(($0) - mask)) - 1) }
    let _0: u32 = mask >= 32 ? max : make_u32(32)
    let _1: u32 = mask <= 32 ? 0 : mask >= 64 ? max : make_u32(64 + 1)
    let _2: u32 = mask <= 64 ? 0 : mask >= 96 ? max : make_u32(96 + 1)
    let _3: u32 = mask <= 96 ? 0 : mask >= 128 ? max : make_u32(128 + 1)

    return in6_addr(__u6_addr: __u6(__u6_addr32:
      (_0.bigEndian, _1.bigEndian, _2.bigEndian, _3.bigEndian)
    ))
    #endif
  }

  /// Available for ip address only, check if two addresses are in the same
  /// subnet.
  ///
  /// - Parameters:
  ///   - other: the other address
  ///   - prefix: the number of masked bits, for example if an address written as
  /// 191.255.255.255/16, the value for this field is 16, if in ipv6, this is
  /// the number of prefix
  /// - Returns: if the two address are in the same subnet
  public func isSameSubnet(with other: SocketAddress, prefix: UInt32) -> Bool
  {
    //    print(#function + #line.description)
    guard family == other.family else {
      return false
    }

    switch family {
    case .inet:
      guard
        let lhs = inet(),
        let rhs = other.inet() else {
          return false
      }

      return _check_masked(lhs: lhs.sin_addr.s_addr,
                 rhs: rhs.sin_addr.s_addr,
                 bits: prefix)

    case .inet6:
      guard
        let lhs = inet6(),
        let rhs = other.inet6() else {
          return false
      }

      return _is_in_subnet_v6(lhs: lhs.sin6_addr,
                  rhs: rhs.sin6_addr,
                  mask: _v6_make_mask(prefix))

    default:
      return false
    }
  }

  /// Available for ip address only, check if two addresses are in the same
  /// subnet.
  ///
  /// - Parameters:
  ///   - other: the other address
  ///   - mask: The masked address, in socketaddress from
  /// - Returns: if the two address are in the same subnet
  public func isSameSubnet(with other: SocketAddress, mask: SocketAddress) -> Bool
  {
    guard
      other.family == self.family,
      family == mask.family else {
        return false
    }

    switch family {
    case .inet:
      return _is_in_subnet_v4(lhs: inet()!.sin_addr.s_addr,
                  rhs: other.inet()!.sin_addr.s_addr,
                  mask: mask.inet()!.sin_addr.s_addr)
    case .inet6:
      return _is_in_subnet_v6(lhs: inet6()!.sin6_addr,
                  rhs: other.inet6()!.sin6_addr,
                  mask: mask.inet6()!.sin6_addr)
    default:
      return false
    }
  }
}
