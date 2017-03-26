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
		XCTAssertEqual("\(IPAddr)", "inet\(v4 ? "" : "6") \(ip):\(port)", "Description of Socket", file: file, line: line)
	}
    
    func testTrigger1() {
        let trigger = Trigger()
        var i = 0
        var j = 0
        
        DispatchQueue.global().async {
            while true {
                trigger.wait()
                i += 1
//                print("wait \(i)")
            }
        }
        
        // to ensure thread creation
        sleep(1)
        
        //
        for _ in 0..<6 {
            trigger.trigger()
            j += 1
//            print("trigger \(j)")
            
            // to ensure 1 trigger 1 wait
            sleep(1)
        }
        
        // joint thread
        sleep(1)
        XCTAssertEqual(i, j, "")
    }
    
    func testTrigger2() {
        let trigger = Trigger()
        
        var time_first_trigger: timespec!
        var time_second_trigger: timespec!
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            trigger.trigger()
            trigger.trigger()
            sleep(1)
            trigger.wait() // prevent this thread catch the trigger of the main thread
            time_second_trigger = timespec.now()
            print("second trigger")
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.2) {
            trigger.trigger()
        }
        
        trigger.wait()
        time_first_trigger = timespec.now()
        print("first trigger")
        sleep(2)
        XCTAssertNotEqual(time_first_trigger, time_second_trigger, "time first triggered: \(time_first_trigger), time second triggered: \(time_second_trigger)")
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
      ("ensure trigger and wait pair work as expect", testTrigger1),
      ("ensure multiple trigger can only trigger one wait", testTrigger2)
    ]
  }
}
