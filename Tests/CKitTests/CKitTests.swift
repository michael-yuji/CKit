import XCTest
@testable import CKit

class CKitTests: XCTestCase {
	fileprivate let IPv4Addr = SocketAddress(ip: "127.0.0.1", domain: .inet, port: 8080)!

	// Test initializer of SocketAddress
	func testIPv4Init() {
		XCTAssertEqual(IPv4Addr.ip, Optional("127.0.0.1"))
		XCTAssertEqual(Int(IPv4Addr.port!), 8080)
	}

	static var allTests : [(String, (CKitTests) -> () throws -> Void)] {
    return [
      ("init ipv4 address", testIPv4Init)
    ]
  }
}