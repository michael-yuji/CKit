
public struct SystemError: Error, CustomStringConvertible {
    public var errno: Int32
    public var umsg: String?
    public var description: String {
        return "\(umsg ?? ""): " + String(cString: xlibc.strerror(errno))
    }
    
    public static func last(_ umsg: String?) -> SystemError {
        return SystemError(errno: xlibc.errno, umsg: umsg)
    }
    
    public func catching<T>(errorCodes: [Int32],
                         _ syscall: () throws -> T) rethrows -> T? {
        do {
            return try syscall()
        } catch is SystemError {
            return nil
        } catch {
            throw error
        }
    }
}
