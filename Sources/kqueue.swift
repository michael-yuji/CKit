
public struct KQueue: FileDescriptorRepresentable {
    public var fileDescriptor: Int32

    public init() {
        fileDescriptor = xlibc.kqueue()
    }
    
    /// add events to the the queue, but not monitor yet
    public func push(events: [kevent]) throws {
        _ = try throwsys("kevent") {
            kevent(fileDescriptor, events, Int32(events.count), nil, 0, nil)
        }
    }
    
    /// Monitor events with timeout
    ///
    /// - Parameters:
    ///   - maxevs: maximum events to monitor
    ///   - timeout: the timeout, nil if no timeout
    /// - Returns: events triggered
    /// - Throws: if kevent returns error
    public func monitor(maxevs: Int, timeout: timespec?) throws -> [kevent] {
        var evs = [_kev](repeating: _kev(), count: maxevs)
        
        let nev = try throwsys("kevent") { () -> Int32 in
            guard var t = timeout else {
                return kevent(fileDescriptor, nil, 0, &evs, Int32(maxevs), nil)
            }
            return kevent(fileDescriptor, nil, 0, &evs, Int32(maxevs), &t)
        }
        
        return Array<_kev>(evs.dropLast(maxevs - Int(nev)))
    }
    
    public func poll(moreEv ievs: [kevent], maxevs: Int, timeout: timespec?) throws -> [kevent] {
        
        let mx = max(maxevs, ievs.count)
        var evs = [_kev](repeating: _kev(), count: mx)
        
        let nev = try throwsys("kevent") { () -> Int32 in
            guard var t = timeout else {
                return kevent(fileDescriptor, ievs, Int32(ievs.count), &evs, Int32(maxevs), nil)
            }
            return kevent(fileDescriptor, nil, 0, &evs, Int32(maxevs), &t)
        }
        
        return Array<_kev>(evs.dropLast(maxevs - Int(nev)))
    }
}

