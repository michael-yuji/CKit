import XCTest
@testable import CKit

extension CKitTests {

    public func testUnixDomain() {
        let path = "/path/to/socket"
        let cpath = path.cString(using: .ascii)!

        var addr = SocketAddress(unixPath: path)
        
        var caddr = sockaddr_un()

        caddr.sun_family = sa_family_t(AF_UNIX)
        #if !os(Linux)
        caddr.sun_len = __uint8_t(MemoryLayout<sockaddr_un>.size)
        #endif

        _ = withUnsafeMutableBytes(of: &(caddr.sun_path)) {
            memcpy($0.baseAddress!, cpath, Int(strlen(cpath)))
        }
        
        var cast = addr.unix()

//        XCTAssertEqual(memcmp(&caddr, addr.addrptr(),
//                              MemoryLayout<sockaddr_un>.size), 0)

        XCTAssertEqual(memcmp(&caddr, &cast, MemoryLayout<sockaddr_un>.size), 0)

        XCTAssertEqual(addr.path, path)
    }

    public func test_init_with_storage()
    {
        var storage = sockaddr_storage()
        
        var caddr = sockaddr_un()
        
        caddr.sun_family = sa_family_t(AF_UNIX)
        #if !os(Linux)
        caddr.sun_len = __uint8_t(MemoryLayout<sockaddr_un>.size)
        #endif
        
        let path = "/path/to/socket"
        let cpath = path.cString(using: .ascii)!
        
        _ = withUnsafeMutableBytes(of: &(caddr.sun_path)) {
            memcpy($0.baseAddress!, cpath, Int(strlen(cpath)))
        }
        
        storage = reinterept_cast(from: caddr, to: sockaddr_storage.self)

        let unix = SocketAddress(unixPath: "/path/to/socket")
        let compare = SocketAddress(storage: storage)
        XCTAssertEqual(unix, compare)
    }

    public func testIpv4() {
        
        let ip = "127.0.0.1"
        let port: in_port_t = 4430

        let ipaddr = SocketAddress(ip: ip, domain: .inet, port: port)!
        
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
        
        var addr = ipaddr.addr()
        XCTAssertEqual(memcmp(&caddr, &addr, MemoryLayout<sockaddr>.size), 0)
        
        let ccast = reinterept_cast(from: caddr, to: sockaddr.self)
        
        XCTAssertTrue(ccast.sa_data.0 == addr.sa_data.0)
        XCTAssertTrue(ccast.sa_data.1 == addr.sa_data.1)
        XCTAssertTrue(ccast.sa_data.2 == addr.sa_data.2)
        XCTAssertTrue(ccast.sa_data.3 == addr.sa_data.3)
        XCTAssertTrue(ccast.sa_data.4 == addr.sa_data.4)
        XCTAssertTrue(ccast.sa_data.5 == addr.sa_data.5)
        XCTAssertTrue(ccast.sa_data.6 == addr.sa_data.6)
        XCTAssertTrue(ccast.sa_data.7 == addr.sa_data.7)
        XCTAssertTrue(ccast.sa_data.8 == addr.sa_data.8)
        XCTAssertTrue(ccast.sa_data.9 == addr.sa_data.9)
        XCTAssertTrue(ccast.sa_data.10 == addr.sa_data.10)
        XCTAssertTrue(ccast.sa_data.11 == addr.sa_data.11)
        XCTAssertTrue(ccast.sa_data.12 == addr.sa_data.12)
        XCTAssertTrue(ccast.sa_data.13 == addr.sa_data.13)
        
        XCTAssertTrue(ccast.sa_family == addr.sa_family)
        XCTAssertTrue(ccast.sa_len == addr.sa_len)

        ipaddr.withSockAddrPointer {
            XCTAssertEqual(memcmp(&caddr, $0, MemoryLayout<sockaddr_in>.size), 0)
        }
        
//        XCTAssertEqual(memcmp(&caddr, ipaddr.addrptr(), MemoryLayout<sockaddr_in>.size), 0)
        
        // make sure .inet is working
        XCTAssertEqual(memcmp(&caddr, &cast, MemoryLayout<sockaddr_in>.size), 0)

        // make sure ip string is correct
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

//        XCTAssertEqual(memcmp(&caddr, ipaddr.addrptr(), MemoryLayout<sockaddr_in6>.size), 0)
        XCTAssertEqual(memcmp(&caddr, &cast, MemoryLayout<sockaddr_in6>.size), 0)

        XCTAssertEqual(ipaddr.ip, ip)

        // port of socket
        XCTAssertEqual(ipaddr.port, port)
    }
    
    public func test_subnet()
    {
        let addr0 = SocketAddress(ip: "192.168.2.5", domain: .inet)!
        let addr1 = SocketAddress(ip: "192.168.2.51", domain: .inet)!
        
        XCTAssertTrue(addr0.isSameSubnet(with: addr1, prefix: 24))
        
        let addr3 = SocketAddress(ip: "2001:0DB8:ABCD:0012:5311:0ba0:c00f:9042",
                                  domain: .inet6)!
        let addr4 = SocketAddress(ip: "2001:0DB8:ABCD:0012:0ba0:5311:abce:4104",
                                  domain: .inet6)!
        let mask64 = SocketAddress(ip: "2001:0DB8:ABCD:0012:0000:0000:0000:0000", domain: .inet6)!
        
        print("mask64: " + mask64.description)
        XCTAssertTrue(addr3.isSameSubnet(with: addr4, prefix: 24))
        XCTAssertTrue(addr3.isSameSubnet(with: addr4, prefix: 64))
        XCTAssertTrue(addr3.isSameSubnet(with: addr4, mask: mask64))
    }
}
