
public struct SystemError: Error, CustomStringConvertible {
    public var errno: Int32
    public var umsg: String?
    public var description: String {
        return "\(umsg ?? ""): \(xlibc.strerror(errno))"
    }
    
    public static func lastest(_ umsg: String?) -> SystemError {
        return SystemError(errno: xlibc.errno, umsg: umsg)
    }
}
