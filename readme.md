# CKit

## Description

A lot of pointer is used in C. Although swift can call C API directly, swift doesn't provide a easy-clean way to access pointer of non-Foundation object.
Which CKit provides you.
CKit is a small helper to make using C APIs in swift easier. Also come with some POSIX C struct wrappers (dirent, stat, pwd)

The core of CKit is really only two global functions: 
`public func pointer<T>(of obj: inout T) -> UnsafePointer<T>` and `public func mutablePointer(of: inout T) -> UnsafeMutablePointer<T>`;
These funcs returns the pointer of `obj`. 
Other parts of the Library are just for fun.

## Example
socket: bind()
```Swift
import Foundation
import CKit
var sockfd = socket(AF_INET, SOCK_STREAM, 0); // nothing to explain
var addr: sockaddr_in = ... // initialize the sockaddr_in object

let err = Foundation.bind(sockfd, 
                          // get pointer of addr and cast to `struct sockaddr *`
                          UnsafePointer<sockaddr>(pointer(of: &addr)),
                          socklen_t(sizeof(sockaddr_in.self)))
```
