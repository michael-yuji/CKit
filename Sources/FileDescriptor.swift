
//  Copyright (c) 2016, Yuji
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those
//  of the authors and should not be interpreted as representing official policies,
//  either expressed or implied, of the FreeBSD Project.
//
//  Created by Yuji on 3/10/17.
//  Copyright © 2016 Yuji. All rights reserved.
//

public protocol FileDescriptorRepresentable {
    var fileDescriptor: Int32 { get set }
}

public struct AccessMode: OptionSet, CustomStringConvertible {
    public typealias RawValue = UInt16
    public var rawValue: UInt16
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
    
    public init(_ i: Int32) {
        self.rawValue = UInt16(i)
    }
    
    public static let read = AccessMode(O_RDONLY)
    public static let write = AccessMode(O_WRONLY)
    
    public var description: String {
        return "\(self.contains(.read) ? "r" : "-")" + "\(self.contains(.write) ? "w" : "-")"
    }
}

public struct FileControlFlags: OptionSet {
    public typealias RawValue = Int32
    public var rawValue: Int32
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    public static let nonblock = FileControlFlags(rawValue: O_NONBLOCK)
    public static let append = FileControlFlags(rawValue: O_APPEND)
    public static let async = FileControlFlags(rawValue: O_ASYNC)
}

public enum FileDescriptorOwner {
    case group(pid_t)
    case process(pid_t)
    case error(SystemError)
}

@inline(__always)
func throwsys<I: Integer>(_ sys: String, _ blk: (Void) -> I) throws -> I {
    let ret = blk()
    if ret == -1 {
        throw SystemError.lastest(sys)
    }
    return ret
}

public extension FileDescriptorRepresentable {
    public var flags: FileControlFlags {
        get {
            return FileControlFlags(rawValue: xlibc.fcntl(fileDescriptor, F_GETFL, 0))
        } set {
            flags = FileControlFlags(rawValue: xlibc.fcntl(fileDescriptor, F_GETFL, newValue.rawValue))
        }
    }
    
    public var accessMode: AccessMode {
        return AccessMode(self.flags.rawValue & O_ACCMODE)
    }
    
    public mutating func insert(flags: FileControlFlags) {
        self.flags = self.flags.insert(flags).memberAfterInsert
    }
    
    public mutating func remove(flags: FileControlFlags) {
        self.flags = self.flags.remove(flags) ?? self.flags
    }
}

// MARK: Interrupt Driven IO
public extension FileDescriptorRepresentable {
    
    public var signalOwner: FileDescriptorOwner {
        let pid = fcntl(fileDescriptor, F_GETOWN)
        return pid == -1 ? .error(SystemError.lastest("fcntl:FL_GETOWN"))
            : pid < 0 ? .group(abs(pid)) : .process(pid)
    }
    
    public func setSignalOwner(pid: pid_t) throws {
        _ = try throwsys("fcntl:F_SETOWN") {
            fcntl(fileDescriptor, F_SETOWN, pid)
        }
    }
}

public extension FileDescriptorRepresentable {
    @discardableResult
    public func close() -> Int32 {
        return xlibc.close(fileDescriptor)
    }
    
    @discardableResult
    public func write(bytes: PointerType, length: Int) throws -> Int {
        return try throwsys("write") {
            xlibc.write(fileDescriptor, bytes.rawPointer, length)
        }
    }
    
    @discardableResult
    public func readBytes(to buffer: MutablePointerType, length: Int) throws -> Int {
        return try throwsys("read") {
            xlibc.read(fileDescriptor, buffer.mutableRawPointer, length)
        }
    }

    @discardableResult
    public func vectorWrite(_ vectors: [xlibc.iovec]) throws -> Int {
        return try throwsys("writev") {
            xlibc.writev(fileDescriptor, vectors, Int32(vectors.count))
        }
    }
    
    @discardableResult
    public func pwrite(bytes: PointerType, length: Int, at offset: off_t) throws -> Int {
        return try throwsys("pwrite") {
            xlibc.pwrite(fileDescriptor, bytes.rawPointer, length, offset)
        }
    }
}
