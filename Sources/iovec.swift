
public extension iovec {
    public init(base: AnyPointer, len: Int) {
        self.iov_base = UnsafeMutableRawPointer(mutating: base.rawPointer)
        self.iov_len = len
    }
    
    public var buffer: UnsafeRawBufferPointer {
        return UnsafeRawBufferPointer(start: iov_base, count: iov_len)
    }
    
    public var mutableBuffer: UnsafeMutableRawBufferPointer {
        return UnsafeMutableRawBufferPointer(start: iov_base, count: iov_len)
    }
}

public extension UnsafeBufferPointer {
    public var iovec: xlibc.iovec {
        guard let baseAddress = self.baseAddress else {
            return xlibc.iovec(iov_base: nil, iov_len: 0)
        }

        return xlibc.iovec(iov_base: UnsafeMutableRawPointer(mutating: baseAddress.rawPointer),
                           iov_len: self.count * MemoryLayout<Element>.size)
    }
}


public extension UnsafeMutableBufferPointer {
    public var iovec: xlibc.iovec {
        guard let baseAddress = self.baseAddress else {
            return xlibc.iovec(iov_base: nil, iov_len: 0)
        }
        
        return xlibc.iovec(iov_base: baseAddress.mutableRawPointer,
                           iov_len: self.count * MemoryLayout<Element>.size)
    }
}
;
public extension UnsafeRawBufferPointer {
    public var iovec: xlibc.iovec {
        guard let baseAddress = self.baseAddress else {
            return xlibc.iovec(iov_base: nil, iov_len: 0)
        }
        
        return xlibc.iovec(iov_base: UnsafeMutableRawPointer(mutating: baseAddress.rawPointer),
                           iov_len: self.count)
    }
}


public extension UnsafeMutableRawBufferPointer {
    public var iovec: xlibc.iovec {
        guard let baseAddress = self.baseAddress else {
            return xlibc.iovec(iov_base: nil, iov_len: 0)
        }
        
        return xlibc.iovec(iov_base: baseAddress.mutableRawPointer,
                           iov_len: self.count)
    }
}
