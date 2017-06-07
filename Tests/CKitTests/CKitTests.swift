import XCTest
import Dispatch
import Foundation
@testable import CKit

class CKitTests: XCTestCase
{
	static var allTests : [(String, (CKitTests) -> () throws -> Void)] {
    return [
        ("dns", test_dns),
        ("dns", test_dns0),
        ("dns", test_dns1),
        ("dns", test_dns2),
        ("ip4", testIpv4),
        ("ip6", testIpv6),
        ("initWithSockStorage", test_init_with_storage),
        ("unix_domain_sock", testUnixDomain),
        ("subnet", test_subnet),
        ("unixsock", testUnixDomain),
        ("nonblk", test_read_nonblk)
    ]
  }
}
