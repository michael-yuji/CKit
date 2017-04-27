
import XCTest
@testable import CKit

extension CKitTests {
    func test_dns() {
        let hosts = try! System.DNS.lookup(host: "www.google.com", service: "http",
                                    options: .fetchOriginalName)
        XCTAssertEqual(hosts.officialHostname, "www.google.com")
        for addr in hosts.addrs {
            XCTAssertEqual(addr.port, 80)
        }
    }
    
    func test_dns0() {
        let hosts = try! System.DNS.lookup(host: "www.google.com", service: "http",
                                    options: .fetchOriginalName, .count(1))
        XCTAssertEqual(hosts.officialHostname, "www.google.com")
        XCTAssertEqual(hosts.addrs.count, 1)
        for addr in hosts.addrs {
            XCTAssertEqual(addr.port, 80)
        }
    }
    
    func test_dns1() {
        let hosts = try! System.DNS.lookup(host: "www.google.com", service: "http",
                                    options: .fetchOriginalName, .family(.inet))
        XCTAssertEqual(hosts.officialHostname, "www.google.com")
        for addr in hosts.addrs {
            XCTAssertEqual(addr.type, .inet)
        }
    }
    
}