
//  Copyright (c) 2016, Yuji
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those
//  of the authors and should not be interpreted as representing official policies,
//  either expressed or implied, of the FreeBSD Project.
//
//  Created by Yuji on 10/23/16.
//  Copyright © 2016 Yuji. All rights reserved.
//

extension timespec : Hashable, Equatable, Comparable
{
    public static var distantFuture: timespec {
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
    return timespec(tv_sec: lhs.tv_sec + rhs.tv_sec,
                    tv_nsec: lhs.tv_nsec + rhs.tv_nsec)
}

public func -(lhs: timespec, rhs: timespec) -> timespec {
    return timespec(tv_sec: lhs.tv_sec - rhs.tv_sec,
                    tv_nsec: lhs.tv_nsec - rhs.tv_nsec)
}

public func *(lhs: timespec, rhs: timespec) -> timespec {
    return timespec(tv_sec: lhs.tv_sec * rhs.tv_sec,
                    tv_nsec: lhs.tv_nsec * rhs.tv_nsec)
}

public func /(lhs: timespec, rhs: timespec) -> timespec {
    return timespec(tv_sec: lhs.tv_sec / rhs.tv_sec,
                    tv_nsec: lhs.tv_nsec / rhs.tv_nsec)
}

public func %(lhs: timespec, rhs: timespec) -> timespec {
    return timespec(tv_sec: lhs.tv_sec % rhs.tv_sec,
                    tv_nsec: lhs.tv_nsec % rhs.tv_nsec)
}
