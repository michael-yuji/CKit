import XCTest
@testable import CKit

extension CKitTests {
    
    public func testUnixDomain() {
        let path = "/path/to/socket"
        let cpath = path.cString(using: .ascii)!

        var addr = SocketAddress(unixPath: path)!
        
        var caddr = sockaddr_un()

        caddr.sun_family = sa_family_t(AF_UNIX)
        #if !os(Linux)
        caddr.sun_len = __uint8_t(MemoryLayout<sockaddr_un>.size)
        #endif
//        print(addr.storage.unix)
        _ = withUnsafeMutableBytes(of: &(caddr.sun_path)) {
            memcpy($0.baseAddress!, cpath, Int(strlen(cpath)))
        }
        
//        print(caddr)
        print(addr.addrptr().cast(to: sockaddr_un.self).pointee)

        var cast = addr.unix()!

        XCTAssertEqual(memcmp(&caddr, addr.addrptr(),
                              MemoryLayout<sockaddr_un>.size), 0)

        XCTAssertEqual(memcmp(&caddr, &cast, MemoryLayout<sockaddr_un>.size), 0)

        XCTAssertEqual(addr.path, path)
    }

    public func testIpv4() {
        let ip = "127.0.0.1"
        let port: in_port_t = 4430

        var ipaddr = SocketAddress(ip: ip, domain: .inet, port: port)!
        
        // compare to "real" c sockaddr
        var caddr = sockaddr_in()
        caddr.sin_port = port.byteSwapped
        caddr.sin_family = sa_family_t(AF_INET)
        #if !os(Linux)
            caddr.sin_len = __uint8_t(MemoryLayout<sockaddr_in>.size)
        #endif
        _ = ip.withCString {
            inet_pton(AF_INET, $0,
                      mutablePointer(of: &(caddr.sin_addr)).mutableRawPointer)
        }

        var cast = ipaddr.inet()!

        // make sure .addrptr is working
        XCTAssertEqual(memcmp(&caddr, ipaddr.addrptr(),
                              MemoryLayout<sockaddr_in>.size), 0)
        // make sure .inet is working
        XCTAssertEqual(memcmp(&caddr, &cast, MemoryLayout<sockaddr_in>.size), 0)

        XCTAssertEqual(ipaddr.ip, ip)

        // port of socket
        XCTAssertEqual(ipaddr.port, port)
    }

    public func testIpv6() {
        let ip = "::1"
        let port: in_port_t = 4430

        var ipaddr = SocketAddress(ip: ip, domain: .inet6, port: port)!

        var caddr = sockaddr_in6()
        caddr.sin6_port = port.byteSwapped
        caddr.sin6_family = sa_family_t(AF_INET6)
        #if !os(Linux)
            caddr.sin6_len = __uint8_t(MemoryLayout<sockaddr_in6>.size)
        #endif
        _ = ip.withCString {
            inet_pton(AF_INET6, $0,
                      mutablePointer(of: &(caddr.sin6_addr)).mutableRawPointer)
        }

        var cast = ipaddr.inet6()!

        XCTAssertEqual(memcmp(&caddr, ipaddr.addrptr(), MemoryLayout<sockaddr_in6>.size), 0)
        XCTAssertEqual(memcmp(&caddr, &cast, MemoryLayout<sockaddr_in6>.size), 0)

        XCTAssertEqual(ipaddr.ip, ip)

        // port of socket
        XCTAssertEqual(ipaddr.port, port)
    }
}
