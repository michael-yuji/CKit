
public protocol FileDescriptorRepresentable {
    var fileDescriptor: Int32 { get set }
}

public struct AccessMode: OptionSet {
    public typealias RawValue = mode_t
    public var rawValue: mode_t
    public init(rawValue: mode_t) {
        self.rawValue = rawValue
    }
    
    public init(rawValue: Int32) {
        self.rawValue = mode_t(rawValue)
    }
    
    public init(rawValue: UInt32) {
        self.rawValue = mode_t(rawValue)
    }
    
    public static let user = (r: AccessMode(rawValue: S_IREAD),
                              w: AccessMode(rawValue: S_IWRITE),
                              x: AccessMode(rawValue: S_IEXEC))
    
    public static let group = (r: AccessMode(rawValue: S_IRGRP),
                              w: AccessMode(rawValue: S_IWGRP),
                              x: AccessMode(rawValue: S_IXGRP))
    
    public static let other = (r: AccessMode(rawValue: S_IROTH),
                              w: AccessMode(rawValue: S_IWOTH),
                              x: AccessMode(rawValue: S_IXOTH))
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
    
    public var accessMode: mode_t {
        return mode_t(fcntl(fileDescriptor, F_GETFL, O_ACCMODE))
    }
    
    public mutating func insert(flags: FileControlFlags) {
        self.flags = self.flags.insert(flags).memberAfterInsert
    }
    
    public mutating func remove(flags: FileControlFlags) {
        self.flags = self.flags.remove(flags) ?? self.flags
    }
}

// MARK: Signal
public extension FileDescriptorRepresentable {
    
    public var signalOwner: FileDescriptorOwner {
        let pid = fcntl(fileDescriptor, F_GETOWN)
        return pid < 0 ? .group(abs(pid)) : .process(pid)
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
