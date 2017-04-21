import XCTest
import Dispatch
@testable import CKit

class CKitTests: XCTestCase {
	// MARK: SocketAddress Test Helpers
	// Test initializer of SocketAddress
	fileprivate func helperTestInitIP(ip: String, v4: Bool, port: UInt16, file: StaticString = #file, line: UInt = #line) {
        
        var ipaddr = SocketAddress(ip: ip, domain: v4 ? .inet : .inet6, port: port)!
        
        if v4 {
            
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
    
            XCTAssertEqual(memcmp(&caddr, ipaddr.addrptr(), MemoryLayout<sockaddr_in>.size), 0)
            XCTAssertEqual(memcmp(&caddr, &cast, MemoryLayout<sockaddr_in>.size), 0)
        } else {
            
            // compare to "real" c sockaddr
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
        }

		// ip of socket
		XCTAssertEqual(ipaddr.ip, Optional("\(ip)"), "IP of Socket", file: file, line: line)

		// port of socket
		XCTAssertEqual(ipaddr.port, Optional(port), "Port of Socket", file: file, line: line)

		// socket description
		XCTAssertEqual("\(ipaddr)", "inet\(v4 ? "" : "6") \(ip):\(port)", "Description of Socket", file: file, line: line)
	}

	// MARK: SocketAddress Test Cases
	func testIPv4Init() {
		helperTestInitIP(ip: "127.0.0.1", v4: true, port: 8080)
	}

	func testIPv6Init() {
		helperTestInitIP(ip: "::1", v4: false, port: 8080)
	}

	// MARK: Export all tests for Linux swift test
	static var allTests : [(String, (CKitTests) -> () throws -> Void)] {
    return [
      ("init ipv4 SocketAddress", testIPv4Init),
      ("init ipv6 SocketAddress", testIPv6Init),
    ]
  }
}
