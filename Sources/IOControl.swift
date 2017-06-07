
#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
/// Just trust me
public let FIONREAD = 1074030207
#endif

public extension FileDescriptor
{
    /// How many bytes available in the kernel buffer
    public var bytesAvailable: Int
    {
        var bytes = 0
        _ = ioctl(self.fileDescriptor, UInt(FIONREAD), mutablePointer(of: &bytes).mutableRawPointer)
        return bytes
    }
}
