
public extension iovec
{
    
    /// Initialize the io vector by given pointer and len
    ///
    /// - Parameters:
    ///   - base: The pointer to the buffer
    ///   - len: The size of the buffer
    public init(base: AnyPointer, len: Int)
    {
        self.iov_base = UnsafeMutableRawPointer(mutating: base.rawPointer)
        self.iov_len = len
    }
    
    /// Get the `UnsafeRawBufferPointer` representation
    public var buffer: UnsafeRawBufferPointer
    {
        return UnsafeRawBufferPointer(start: iov_base, count: iov_len)
    }
    
    /// Get the `UnsafeMutableRawBufferPointer` representation
    public var mutableBuffer: UnsafeMutableRawBufferPointer
    {
        return UnsafeMutableRawBufferPointer(start: iov_base, count: iov_len)
    }
}

public extension AnyBufferPointer
{
    public var iovec: xlibc.iovec
    {
        let rawBuffer = self.rawBuffer
        return xlibc.iovec(base: rawBuffer.baseAddress!, len: rawBuffer.count)
    }
}

public extension UnsafeBufferPointer
{
    /// Get the io vector representation of the Buffer
    public var iovec: xlibc.iovec
    {
        guard let baseAddress = self.baseAddress else {
            return xlibc.iovec(iov_base: nil, iov_len: 0)
        }

        let iovbase = UnsafeMutableRawPointer(mutating: baseAddress.rawPointer)
        return xlibc.iovec(iov_base: iovbase,
                           iov_len: self.count * MemoryLayout<Element>.size)
    }
}


public extension UnsafeMutableBufferPointer
{
    public var iovec: xlibc.iovec
    {
        guard let baseAddress = self.baseAddress else {
            return xlibc.iovec(iov_base: nil, iov_len: 0)
        }
        
        return xlibc.iovec(iov_base: baseAddress.mutableRawPointer,
                           iov_len: self.count * MemoryLayout<Element>.size)
    }
}

public extension UnsafeRawBufferPointer
{
    public var iovec: xlibc.iovec
    {
        guard let baseAddress = self.baseAddress else {
            return xlibc.iovec(iov_base: nil, iov_len: 0)
        }
        
        return xlibc.iovec(iov_base: UnsafeMutableRawPointer(mutating: baseAddress.rawPointer),
                           iov_len: self.count)
    }
}


public extension UnsafeMutableRawBufferPointer
{
    public var iovec: xlibc.iovec
    {
        guard let baseAddress = self.baseAddress else {
            return xlibc.iovec(iov_base: nil, iov_len: 0)
        }
        
        return xlibc.iovec(iov_base: baseAddress.mutableRawPointer,
                           iov_len: self.count)
    }
}
