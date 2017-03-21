# CKit
[![Platform](https://img.shields.io/badge/OS-Darwin%20|%20Linux-green.svg)]()
[![License](https://img.shields.io/badge/License-BSD%202--Clause-orange.svg)](https://opensource.org/licenses/BSD-2-Clause)

## Description

CKit is framework designed for interact with C API. It provides painless pointer operations, object oriented wrappers of some common C struct such as stat, dirent and passwd. In 0.0.5 release, an object oriented support for epoll and kqueue is added. 

Because it is build on top of [xlibc](https://github.com/michael-yuji/xlibc), by importing CKit, besides all libc modules in Darwin.C and Glibc, you also have access to some platform dependented modules such as epoll and inotify.


## Pointer

Although swift can call C API directly, swift has not provided an easy way to access pointer of non-Foundation object, and it is even harder to cast a pointer to unrelated types. An Example use is in socket to cast different types of sockaddr. See the `pointer(of:)` and `mutablePointer(of:)` example in KernelQueue/Epoll section of this readme.

### PointerType
All pointer types (`UnsafePointer<T>`, `UnsafeRawPointer`, `UnsafeBufferPointer` and `Array<T>`) confirms to the CKit.PointerType protocol. It doesn't just allow you to write code that take any pointer types as argument easier but also come with a `PointerType.rawPointer` getter that returns you an `UnsafeRawPointer` object. The `PointerType.numerialValue` property returns the numberical representation of the address as `Int`.

All mutable pointer types (`UnsafeMutablePointer<T>`, `UnsafeMutableRawPointer`, `UnsafeMutableBufferPointer`) comfirms to `CKit.MutablePointerType` protocol. They got all benefits `CKit.PointerType` get in addition to an `PointerType.mutableRawPointer` property that returns an `UnsafeMutableRawPointer` object.

## KernelQueue (FreeBSD and OS X) and Epoll (Linux)

KernelQueue is an object oriented wrapper for kqueue() system call. The following example demostrates use event looping on a server socket that simply print out requests. Similar to KernelQueue/kqueue, the Epoll is an oo wrapper for epoll()

KernelQueue:
```swift
import CKit
// helper
func sizeof<T>(_ x: T) -> Int {
    return MemoryLayout<T>.size
}

// create our kernel queue and socket
var queue = KernelQueue()
let server = socket(AF_INET, SOCK_STREAM, 0)

// reuse address
var yes = 1
setsockopt(server, SOL_SOCKET, SO_REUSEADDR, pointer(of: &yes).rawPointer, socklen_t(sizeof(yes)))
var addr = sockaddr_in()

let addrlen = sizeof(addr)

// user mutablePointer(of:) to get the pointer of addr
bzero(mutablePointer(of: &addr).mutableRawPointer, addrlen)
addr.sin_port = in_port_t(8080).byteSwapped
addr.sin_family = sa_family_t(AF_INET)
addr.sin_len = UInt8(addrlen)

// user pointer(of:) and cast(to:) to convert between pointers
bind(server, pointer(of: &addr).cast(to: sockaddr.self), socklen_t(addrlen))

listen(server, 999)

// one of two ways to add event, the equeue method are more free since you can add whatever
// action you need.
queue.enqueue(event: KernelEventDescriptor.read(ident: server), for: [.add, .enable])
// main loop
while (true) {
    // wait for event
    try? queue.wait(nevs: 1000, handler: { (result) in        
        // our server socket
        if result.ident == UInt(server) {
            let newfd = accept(server, nil, nil)
            // the other way to add event to kqueue
            queue.add(event: .read(ident: newfd), enable: true, oneshot: false)
        } else {
            // In a read kevent result, the data field is the number of bytes
            let bytes_in_buffer = result.data
            if bytes_in_buffer == 0 {
                close(Int32(result.ident)) // close the socket
            } else {
                let buffer = malloc(bytes_in_buffer)
                read(Int32(result.ident), buffer, bytes_in_buffer)
                print(String(cString: buffer!.assumingMemoryBound(to: Int8.self)))
                free(buffer)
            }
        }
    })
}
```
Epoll:
```swift
import CKit
// helper
func sizeof<T>(_ x: T) -> Int {
    return MemoryLayout<T>.size
}

// cretae epoll and socket
var ep = Epoll()
let server = socket(AF_INET, Int32(SOCK_STREAM).rawValue, 0)
// reuse address
var yes = 1
setsockopt(server, SOL_SOCKET, SO_REUSEADDR, pointer(of: &yes).rawPointer, socklen_t(sizeof(yes)))
var addr = sockaddr_in()
let addrlen = MemoryLayout<sockaddr_in>.size

// user mutablePointer(of:) to get the pointer of addr
bzero(mutablePointer(of: &addr).mutableRawPointer, addrlen)

addr.sin_port = in_port_t(8080).byteSwapped
addr.sin_family = sa_family_t(AF_INET)

// user pointer(of:) and cast(to:) to convert between pointers
bind(server, pointer(of: &addr).cast(to: sockaddr.self), socklen_t(addrlen))

listen(server, 999)

// add to epoll
ep.add(fd: server, for: .pollin)
while (true) {
    for ev in ep.wait(maxevs: 999) {
        // server socket
        if ev.data.fd == server {
            let newfd = accept(server, nil, nil)
            ep.add(fd: newfd, for: .pollin)
        } else {
            var bytes_in_buffer = 0
            // get number of bytes in socket
            ioctl(ev.data.fd, UInt(FIONREAD), mutablePointer(of:&bytes_in_buffer).mutableRawPointer)
            if bytes_in_buffer == 0 {
                // in epoll we need to remove manually when the connection ended
                ep.remove(fd: ev.data.fd)
                // close the socket
                close(ev.data.fd)
                return
            }
            read(Int32(result.ident), buffer, bytes_in_buffer)
            print(String(cString: buffer!.assumingMemoryBound(to: Int8.self)))
            free(buffer)
        }
    }
}
```
## System Configuation

The `CKit.System` struct contains information about the system setup. These included:

### Maximums
- hostname length: `System.maximum.hostname`
- tty name length: `System.maximum.ttyname`
- login name length: `System.maximum.loginname`
- file descriptor count: `System.maximum.fildescs`
- child processes: `System.maximum.childProcess`
- Arguments: `System.maximum.args`

### Sizes
- page size: `System.sizes.page`
- Physical pages: `System.sizes.physicalPages`

### CPU info
- number of CPU configuared: `System.cpus.configuared`
- number of online CPUs: `System.cpus.onlines`
- clock tricks per second: `System.cpus.clkTricksPerSec`

## timespec

The timespec struct is very common in C API to get precise time steps. However it is pretty painful to use in swift since timestep is not comparable nor substractable/addable.

In CKit, extensions are introduced to allow timespecs compare with each other, and also allow converting Foundation Date struct to timespec.

We have also added a static func timespec.now() to help you get current time in timespec.

```Swift
let now = timespec.now()
let date: timespec = Date().unix_timespec
print(date >= now) // comparable

let someDate = date - now // subtract / add / multipy
```

## FileInfo (stat)

FileInfo is same as stat in C, which can use to inspect properties of a file.
```Swift
let status = try? FileStatus(path: "/path/to/file")
// let status = try? FileStatus(fd: my_opened_fd) 
let sizeOfFile = status.size
```

## DirectoryEntry (dirent)

the `DirectoryEntry` structure provided a low level way to inspect directories.
There are two main static functions:
```Swift
// all the contents in the directory "/path/to/dir"
let entries: [DirectoryEntries] = DirectoryEntry.files(at "path/to/dir")

// find a particular entry named "myEntry" in directory "/path/to/dir"
// despite the first argument named "file", it supports all kinds of entries (FIFO, file, dir, etc...)
let entry = DirectoryEntry.find(file: "myEntry", in: "/path/to/dir")
