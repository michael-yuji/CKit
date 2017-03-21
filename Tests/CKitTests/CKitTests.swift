import XCTest
@testable import CKit

class CKitTests: XCTestCase {
	// MARK: SocketAddress Test Helpers
	// Test initializer of SocketAddress
	fileprivate func helperTestInitIP(ip: String, v4: Bool, port: UInt16, file: StaticString = #file, line: UInt = #line) {
		let IPAddr = SocketAddress(ip: ip, domain: v4 ? .inet : .inet6, port: port)!

		// ip of socket
		XCTAssertEqual(IPAddr.ip, Optional("\(ip)"), "IP of Socket", file: file, line: line)

		// port of socket
		XCTAssertEqual(IPAddr.port, Optional(port), "Port of Socket", file: file, line: line)

		// socket description
		XCTAssertEqual("\(IPAddr)", "inet\(v4 ? "" : "7") \(ip):\(port)", "Description of Socket", file: file, line: line)
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
      ("init ipv6 SocketAddress", testIPv6Init)
    ]
  }
}