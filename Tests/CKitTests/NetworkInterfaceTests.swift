import XCTest
@testable import CKit

extension CKitTests
{
    func test_loopback()
    {
        let loopbackInteface = NetworkInterface.interfaces.filter {
            $0.isLoopback && $0.running && $0.supportMulticast
        }

        XCTAssertTrue(loopbackInteface.map{
            $0.address!
        }.contains(SocketAddress(ip: "127.0.0.1", domain: .inet)!))
    }
}
