# CKit

## Description

CKit is a small helper to make using C APIs in swift easier. Also come with some swifty C struct wrappers (dirent, stat, pwd, timespec, etc). It also provides painless function to get pointer and cast pointer around. 

## Pointer

A lot of pointer is used in C. Although swift can call C API directly, swift doesn't provide a easy-clean way to access pointer of non-Foundation object.

The core of CKit is really only two global functions, some extension to pointer type, one protocol and one class:

```swift
public func pointer<T>(of obj: inout T) -> UnsafePointer<T> //return the pointer of 'obj'
public func mutablePointer(of: inout T) -> UnsafeMutablePointer<T> //return the mutable pointer of 'obj'
public extension Unsafe[Mutable]Pointer {
   public func cast<T>(to: T.Type) -> Unsafe[Mutable]Pointer<T>
}
public protocol OpaqueBridged //To create struct that manage 'OpaqueObject'`,
public final class OpaqueObject //Manage life cycle of any OpaquePointer object
```

## Example
socket: bind()
```Swift
import Foundation
import CKit
var sockfd = socket(AF_INET, SOCK_STREAM, 0); // nothing to explain
var addr: sockaddr_in = ... // initialize the sockaddr_in object

let err = Foundation.bind(sockfd, 
                          // get pointer of addr and cast to `struct sockaddr *`
                          pointer(of: &addr).cast(to: sockaddr.self),
                          socklen_t(sizeof(sockaddr_in.self)))
```

opaqueObject: wrapping 'struct tls_config' in libtls (LibreSSL) to swift struct
```Swift
import Foundation
import libressl
import CKit

public struct TLSConfig: OpaqueBridged {
  
    public var opaqueObj: OpaqueObject 
    
    public init() {
        /* tls_config_new returns 'struct tls_config *' and 
         * 'tls_config_free()' is the func to free 'struct tls_config *` in
         * C. 
         */
        opaqueObj = OpaqueObject(tls_config_new(), free: tls_config_free)
    }
    
    public var certificateFile: String? {
        didSet {
            if let file = certificateFile {
            // since OpaqueBridged is confirms to RawRepresentable, and the getter of rawValue returns the OpaquePointer
                tls_config_set_ca_file(rawValue, file)
            }
        }
    }
}
```
