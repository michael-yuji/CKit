# CKit

## Description

CKit is a small helper to make using C APIs in swift easier. Also come with some swifty C struct wrappers (dirent, stat, pwd, timespec, etc). It also provides painless function to get pointer and cast pointer around. 

## Pointer

A lot of pointer is used in C. Although swift can call C API directly, swift doesn't provide a easy-clean way to access pointer of non-Foundation object. An Example use is in socket to cast different types of sockaddr. 

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

## timespec

The timespec struct is very common in C API to get precise time steps. However it is pretty painful to use in swift since timestep is nor comparable or substractable/addable.

In CKit, we introduce extensions to allow timespecs compare with each other, and also allow converting Foundation Date struct to timespec.

We have also added a static func timespec.now() to help you get current time in timespec.

```Swift
let now = timespec.now()
let date: timespec = Date().unix_timespec
print(date >= now) // comparable
```

## FileStatus (stat)
```Swift
let status = try? FileStatus(path: "/path/to/file")
// let status = try? FileStatus(fd: my_opened_fd) 
let sizeOfFile = status.size
```

## pwd...dirent...many more
