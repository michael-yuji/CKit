import XCTest
import Dispatch
import Foundation
@testable import CKit

class CKitTests: XCTestCase {

    func removeDir(path: String) {
        let dir = try! Directory(path: path)
        for ent in dir.contents {
            if ent.name == "." || ent.name == ".." {
                continue
            }
            let cpathname = path + "/" + ent.name
//            print("removing \(cpathname)")
            switch ent.type.rawValue {
            case FileTypes.directory.rawValue:
                removeDir(path: cpathname)
                rmdir(cpathname)
            default:
                unlink(cpathname)
            }
        }
    }
    
    func test_cm_dir() {
        removeDir(path: "/Users/yuuji/Library/Caches/com.apple.bird/session/g")
    }
//    public func test_netif() {
//        NetworkInterface.interfaces.forEach {
//            print($0)
//        }
//        print("===================")
//        NetworkInterface.interfaces.filter{
//            $0.address!.family == .inet || $0.address!.family == .inet6
//            }.filter{
//                !$0.isLoopback && $0.isVliadBoardcast
//            }.forEach {
//                print("????")
//                print($0)
//                print($0._dest)
//            }
//    }
    
	static var allTests : [(String, (CKitTests) -> () throws -> Void)] {
    return [
        ("dns", test_dns),
        ("dns", test_dns0),
        ("dns", test_dns1),
        ("dns", test_dns2),
        ("ip4", testIpv4),
        ("ip6", testIpv6),
        ("unixsock", testUnixDomain),
        ("nonblk", test_read_nonblk)
    ]
  }
}
