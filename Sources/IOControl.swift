
//public

#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
public let FIONREAD = 1074030207
#endif

public extension FileDescriptorRepresentable {
    public var bytesAvailable: Int {
        var bytes = 0
        _ = ioctl(self.fileDescriptor, UInt(FIONREAD), mutablePointer(of: &bytes).mutableRawPointer)
        return bytes
    }
}

// Routating Table
public extension Socket {
    public func addRoute() {
        
    }
}
