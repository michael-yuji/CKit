//
//  Date.swift
//  CKit
//
//  Created by yuuji on 10/23/16.
//
//

#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
import Darwin
#else
import Glibc
#endif

import struct Foundation.Date

extension Date {
    public var unix_timespec: timespec {
        let now = self.timeIntervalSince1970
        return timespec(tv_sec: Int(floor(now)),
                        tv_nsec: Int((now - Double(Int(now))) * 1_000_000_000))
    }
}

extension timespec : Hashable, Equatable, Comparable {
    static var distantFuture: timespec {
        return timespec(tv_sec: Int.max, tv_nsec: Int.max)
    }

    public var hashValue: Int {
        return self.tv_nsec + self.tv_sec * 1_000_000_000
    }
}

public func ==(lhs: timespec, rhs: timespec) -> Bool {
    return lhs.tv_nsec == rhs.tv_nsec && rhs.tv_sec == rhs.tv_sec
}

public func >(lhs: timespec, rhs: timespec) -> Bool {
    if lhs.tv_sec > rhs.tv_sec {
        return true
    }
    
    if lhs.tv_sec == rhs.tv_sec {
        if lhs.tv_nsec > rhs.tv_nsec {
            return true
        }
    }
    
    return false
}

public func >=(lhs: timespec, rhs: timespec) -> Bool {
    if lhs.tv_sec > rhs.tv_sec {
        return true
    }
    
    if lhs.tv_sec == rhs.tv_sec {
        if lhs.tv_nsec >= rhs.tv_nsec {
            return true
        }
    }
    
    return false
}

public func <(lhs: timespec, rhs: timespec) -> Bool {
    if lhs.tv_sec < rhs.tv_sec {
        return true
    }
    
    if lhs.tv_sec == rhs.tv_sec {
        if lhs.tv_nsec < rhs.tv_nsec {
            return true
        }
    }
    
    return false
}

public func <=(lhs: timespec, rhs: timespec) -> Bool {
    if lhs.tv_sec < rhs.tv_sec {
        return true
    }
    
    if lhs.tv_sec == rhs.tv_sec {
        if lhs.tv_nsec <= rhs.tv_nsec {
            return true
        }
    }
    
    return false
}

public func +=(lhs: inout timespec, rhs: timespec) {
    lhs.tv_sec += rhs.tv_sec
    lhs.tv_nsec += rhs.tv_nsec
}

public func -=(lhs: inout timespec, rhs: timespec) {
    lhs.tv_sec -= rhs.tv_sec
    lhs.tv_nsec -= rhs.tv_nsec
}

public func *=(lhs: inout timespec, rhs: inout timespec) {
    lhs.tv_sec *= rhs.tv_sec
    lhs.tv_nsec *= rhs.tv_nsec
}

public func /=(lhs: inout timespec, rhs: inout timespec) {
    lhs.tv_sec /= rhs.tv_sec
    lhs.tv_nsec /= rhs.tv_nsec
}

public func %=(lhs: inout timespec, rhs: inout timespec) {
    lhs.tv_sec %= rhs.tv_sec
    lhs.tv_nsec %= rhs.tv_nsec
}

public func +(lhs: timespec, rhs: timespec) -> timespec {
    return timespec(tv_sec: lhs.tv_sec + rhs.tv_sec, tv_nsec: lhs.tv_nsec + rhs.tv_nsec)
}

public func -(lhs: timespec, rhs: timespec) -> timespec {
    return timespec(tv_sec: lhs.tv_sec - rhs.tv_sec, tv_nsec: lhs.tv_nsec - rhs.tv_nsec)
}

public func *(lhs: timespec, rhs: timespec) -> timespec {
    return timespec(tv_sec: lhs.tv_sec * rhs.tv_sec, tv_nsec: lhs.tv_nsec * rhs.tv_nsec)
}

public func /(lhs: timespec, rhs: timespec) -> timespec {
    return timespec(tv_sec: lhs.tv_sec / rhs.tv_sec, tv_nsec: lhs.tv_nsec / rhs.tv_nsec)
}

public func %(lhs: timespec, rhs: timespec) -> timespec {
    return timespec(tv_sec: lhs.tv_sec % rhs.tv_sec, tv_nsec: lhs.tv_nsec % rhs.tv_nsec)
}

