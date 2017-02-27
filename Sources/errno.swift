
#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
import Darwin
#else
import Glibc
#endif

extension String {
    public static var lastErrnoString: String {
        return errnoString(errno)
    }

    public static func errnoString(_ n: Int32) -> String {
        guard let cErrStr = strerror(n) else {
            return "Cannot get error string from errno"
        }
        return String(cString: cErrStr)
    }
}
