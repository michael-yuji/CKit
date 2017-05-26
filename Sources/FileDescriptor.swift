
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

public typealias CustomRawBytesRepresentable = RawBufferRepresentable

public protocol RawBufferRepresentable {
    var rawBufferRepresentation: UnsafeRawBufferPointer { get }
    func rawBufferReleased(_ buffer: UnsafeRawBufferPointer)
    func rawBufferRetained(_ buffer: UnsafeRawBufferPointer)
}

public struct AccessMode: OptionSet, CustomStringConvertible {
    public typealias RawValue = mode_t
    public var rawValue: mode_t
    public init(rawValue: mode_t) {
        self.rawValue = rawValue
    }
    
    public init(_ i: Int32) {
        self.rawValue = mode_t(i)
    }
    
    public static let read = AccessMode(O_RDONLY)
    public static let write = AccessMode(O_WRONLY)
    
    public var description: String {
        return (self.contains(.read) ? "r" : "-")
                + (self.contains(.write) ? "w" : "-")
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

public extension FileDescriptorRepresentable {

    public var flags: FileControlFlags {
        get {
            return FileControlFlags(rawValue: xlibc.fcntl(fileDescriptor, F_GETFL, 0))
        } set {
            _ = xlibc.fcntl(fileDescriptor, F_SETFL, newValue.rawValue)
        }
    }
    
    public var accessMode: AccessMode {
        return AccessMode(self.flags.rawValue & O_ACCMODE)
    }
    
    public mutating func insert(flags: FileControlFlags) {
        var flags = self.flags
        self.flags = flags.insert(flags).memberAfterInsert
    }
    
    public mutating func remove(flags: FileControlFlags) {
        self.flags = self.flags.remove(flags) ?? self.flags
    }
}

// MARK: Interrupt Driven IO
public extension FileDescriptorRepresentable {
    
    public var signalOwner: FileDescriptorOwner {
        let pid = fcntl(fileDescriptor, F_GETOWN)
        return pid == -1 ? .error(SystemError.last("fcntl:FL_GETOWN"))
            : pid < 0 ? .group(abs(pid)) : .process(pid)
    }
    
    public func setSignalOwner(pid: pid_t) throws {
        _ = try guarding("fcntl:F_SETOWN") {
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
    public func write(bytes: AnyPointer, length: Int) throws -> Int {
        return try guarding("write") {
            xlibc.write(fileDescriptor, bytes.rawPointer, length)
        }
    }
    
    @discardableResult
    public func write(buffer: AnyBufferPointer) throws -> Int {
        return try guarding("write") {
            xlibc.write(fileDescriptor,
                        buffer.rawBuffer.baseAddress!,
                        buffer.rawBuffer.count)
        }
    }
    
    @discardableResult
    public func pread(bytes: AnyPointer, length: Int, at offset: off_t) throws -> Int {
        return try guarding("pwrite") {
            xlibc.pwrite(fileDescriptor, bytes.rawPointer, length, offset)
        }
    }
    
    @discardableResult
    public func pread(buffer: AnyBufferPointer, at offset: off_t) throws -> Int {
        return try guarding("pwrite") {
            xlibc.pwrite(fileDescriptor,
                         buffer.rawBuffer.rawPointer,
                         buffer.rawBuffer.count, offset)
        }
    }
    
    @available(*, deprecated, message: "use read instead")
    @discardableResult
    public func readBytes(to address: AnyMutablePointer, length: Int) throws -> Int {
        return try read(to: address, length: length)
    }
    
    @discardableResult
    public func read(to address: AnyMutablePointer, length: Int) throws -> Int {
        return try guarding("read") {
            xlibc.read(fileDescriptor, address.mutableRawPointer, length)
        }
    }
    
    @discardableResult
    public func read(to buffer: AnyMutableBufferPointer) throws -> Int {
        return try guarding("read") {
            xlibc.read(fileDescriptor,
                       buffer.mutableRawBuffer.baseAddress!,
                       buffer.mutableRawBuffer.count)
        }
    }

    @discardableResult
    public func vectorWrite(_ vectors: [xlibc.iovec]) throws -> Int {
        return try guarding("writev") {
            xlibc.writev(fileDescriptor, vectors, Int32(vectors.count))
        }
    }
    
    @discardableResult
    public func vectorWrite(_ vector: [AnyBufferPointer]) throws -> Int {
        return try guarding("writev") {
            xlibc.writev(fileDescriptor,
                         vector.map{$0.rawBuffer.iovec},
                         Int32(vector.count))
        }
    }
    
    @discardableResult
    public func pwrite(bytes: AnyPointer, length: Int, at offset: off_t) throws -> Int {
        return try guarding("pwrite") {
            xlibc.pwrite(fileDescriptor, bytes.rawPointer, length, offset)
        }
    }
    
    @discardableResult
    public func pwrite(buffer: AnyBufferPointer, at offset: off_t) throws -> Int {
        return try guarding("pwrite") {
            xlibc.pwrite(fileDescriptor,
                         buffer.rawBuffer.rawPointer,
                         buffer.rawBuffer.count, offset)
        }
    }
    
    @discardableResult
    public func write(collection: AnyCollection<RawBufferRepresentable>) throws -> Int {
        let vectors = collection.map{ (buffer) -> iovec in
            let rawBuffer = buffer.rawBufferRepresentation
            buffer.rawBufferRetained(rawBuffer)
            return rawBuffer.iovec
        }

        return try guarding("writev")
        {
            let ret = xlibc.writev(fileDescriptor, vectors, Int32(vectors.count))
            
            zip(collection, vectors).forEach {
                $0.0.rawBufferReleased($0.1.buffer)
            }
    
            return ret
        }
    }
}
