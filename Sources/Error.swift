
public struct SystemError: Error, CustomStringConvertible {
    public var errno: Int32
    public var umsg: String?

    public var description: String
    {
        var buf = [CChar](repeating: 0, count: 128)
        _ = xlibc.strerror_r(errno, &buf, 128)
        return "\(umsg ?? ""): " + String(cString: buf)
    }
    
    public static func last(_ umsg: String?) -> SystemError
    {
        return SystemError(errno: xlibc.errno, umsg: umsg)
    }
    
    public static func lastErrorString() -> String
    {
        var buf = [CChar](repeating: 0, count: 128)
        _ = xlibc.strerror_r(xlibc.errno, &buf, 128)
        return String(cString: buf)
    }
}

@inline(__always)
func guarding<I: Integer>(_ sys: String, _ blk: (Void) -> I) throws -> I
{
    let ret = blk()
    if ret == -1 {
        throw SystemError.last(sys)
    }
    return ret
}
