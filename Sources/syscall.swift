
public enum SyscallReturn<T> {
    case success(T)
    case error(SystemError)
}
