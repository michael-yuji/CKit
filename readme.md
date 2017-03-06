# CKit
![](https://img.shields.io/badge/OS-Darwin | Linux-green.svg)
[![License](https://img.shields.io/badge/License-BSD%202--Clause-orange.svg)](https://opensource.org/licenses/BSD-2-Clause)

## Description

CKit is framework designed for interact with C API. It provides painless pointer operations, object oriented wrappers of some common C struct such as stat, dirent and passed. 

Because it is build on top of [xlibc](https://github.com/michael-yuji/xlibc), by importing CKit, besides all libc modules in Darwin.C and Glibc, you also have access to some platform dependented modules such as epoll and inotify.


## Pointer

Although swift can call C API directly, swift has not provided an easy way to access pointer of non-Foundation object, and it is even harder to cast a pointer to unrelated types. An Example use is in socket to cast different types of sockaddr. 

socket: bind()
```Swift
import CKit // no need to import Foundation/Darwin/Glibc, CKit itself is enough

var sockfd = socket(AF_INET, SOCK_STREAM, 0); // nothing to explain
var addr: sockaddr_in = ... // initialize the sockaddr_in object

let err = Foundation.bind(sockfd, 
                          // get pointer of addr and cast to `struct sockaddr *`
                          pointer(of: &addr).cast(to: sockaddr.self),
                          socklen_t(sizeof(sockaddr_in.self)))
```

### PointerType
All pointer types (`UnsafePointer<T>`, `UnsafeRawPointer`, `UnsafeBufferPointer` and `Array<T>`) confirms to the CKit.PointerType protocol. It doesn't just allow you to write code that take any pointer types as argument easier but also come with a `PointerType.rawPointer` getter that returns you an `UnsafeRawPointer` object. The `PointerType.numerialValue` property returns the numberical representation of the address as `Int`.

All mutable pointer types (`UnsafeMutablePointer<T>`, `UnsafeMutableRawPointer`, `UnsafeMutableBufferPointer`) comfirms to `CKit.MutablePointerType` protocol. They got all benefits `CKit.PointerType` get in addition to an `PointerType.mutableRawPointer` property that returns an `UnsafeMutableRawPointer` object.

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

The timespec struct is very common in C API to get precise time steps. However it is pretty painful to use in swift since timestep is nor comparable or substractable/addable.

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
