
public enum SyscallReturn<T> {
    case success(T)
    case error(SystemError)
}

@inline(__always)
func throwsys<I: Integer>(_ sys: String, _ blk: (Void) -> I) throws -> I {
    let ret = blk()
    if ret == -1 {
        throw SystemError.lastest(sys)
    }
    return ret
}

@inline(__always)
func syscall<I: Integer>(_ sys: String, blk: (Void) -> I) -> SyscallReturn<I> {
    let ret = blk()
    switch ret {
    case -1:
        return .error(SystemError.lastest(sys))
    default:
        return .success(ret)
    }
}
