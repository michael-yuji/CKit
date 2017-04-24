import XCTest
import Dispatch
@testable import CKit

class CKitTests: XCTestCase {
//    func test_aligned_text() {
//        XCTAssertEqual("hi        world     ",
//                       String.alignedText(strings: "hi", "world",
//                                          spaces: [10, 10])
//        )
//    }
//
//    func test_dirent() {
//        print(DirectoryEntry.files(at: "/"))
//    }
//
//    func test_interfaces() {
//        let interfaces = NetworkInterface.interfaces
//        let inetIfx = interfaces.filter{$0.address?.type == .inet}
//        
//        for interface in inetIfx {
//            XCTAssertEqual(interface.address?.type, .inet)
//        }
//    }
//
	// MARK: Export all tests for Linux swift test
	static var allTests : [(String, (CKitTests) -> () throws -> Void)] {
    return [
//      ("init ipv4 SocketAddress", testIPv4Init),
//      ("init ipv6 SocketAddress", testIPv6Init),
    ]
  }
}
