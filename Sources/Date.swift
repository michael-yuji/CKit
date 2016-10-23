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
    
    public static func now() -> timespec {
        var time = timespec()
        #if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
            if #available(OSX 10.12, iOS 10, *) {
                clock_gettime(_CLOCK_REALTIME, &time)
            } else {
                var clock = clock_serv_t()
                host_get_clock_service(mach_host_self(), CALENDAR_CLOCK, &clock)
                var mach_ts = mach_timespec()
                clock_get_time(clock, &mach_ts)
                time = timespec(tv_sec: Int(mach_ts.tv_sec), tv_nsec: Int(mach_ts.tv_nsec))
                mach_port_deallocate(mach_task_self_, clock)
            }
        #elseif os(FreeBSD)
            clock_gettime(CLOCK_REALTIME_FAST, &time)
        #elseif os(Linux)
            clock_gettime(CLOCK_REALTIME, &time)
        #endif
        return time
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

