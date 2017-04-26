import XCTest
@testable import CKit

extension CKitTests {
    func test_read_nonblk() {
        var (sockin, sockout) = try! Socket.makePair(domain: .unix, type: .stream,
                                                protocol: 0)
        
        
        let longStr = "This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;This is a long str;;"
        
        let cstr = longStr.cString(using: .ascii)!
        
        try! sockin.write(bytes: cstr, length: longStr.characters.count)
        

        XCTAssertEqual(sockout.blocking, true)
        sockout.blocking = false
        XCTAssertEqual(sockout.blocking, false)
        
        let buf = calloc(cstr.count + 20, 1) // make a little room
        var c: Int?
        var idx = 0

        repeat {
            do {
                c = try sockout.readBytes(to: buf!.advanced(by: idx), length: 20)
                idx += 20
            } catch let error as SystemError {
                
                if error.errno == EAGAIN || error.errno == EWOULDBLOCK {
                    print(" reached the end \(error)")
                } else {
                    print(error)
                }
                
                break

            } catch {
                // not going to happen
                break
            }
            
        } while c != nil
        
        XCTAssertEqual(longStr, String(cString: buf!.assumingMemoryBound(to: CChar.self)))
        
    }
    
    
    func test_user() {
        print(geteuid())
        print(getuid())
    }
}
