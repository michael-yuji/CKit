
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
//  Created by Yuji on 3/10/16.
//  Copyright © 2016 Yuji. All rights reserved.
//

#if !os(Linux)
public typealias KernelEvent = xlibc.kevent

public protocol KernelEventFlags {
    var rawValue: UInt32 {get}
}
    
public struct KernelEventResult {
    
    /// identifier
    public var ident: UInt
    
    /// type of filter
    public var type: Int16
    
    /// action (EV_ADD, EV_ENABLE, ... )
    public var action: UInt16
    
    /// filter specified flags
    public var flag: UInt32
    
    /// data
    public var data: Int
    
    /// User defined data
    public var udata: UnsafeMutableRawPointer!
}

public struct KernelEventDescriptor {
    public var identifier: UInt
    public var type: KernelEventType
    public var flags: KernelEventFlags
    public var userData: KernelEventUserData?

    public init(event: KernelEvent) {
        self.identifier = event.ident
        self.type = KernelEventType(rawValue: event.filter)

        typealias T = KernelEventType

        self.type =
            event.filter == T.read.rawValue ? .read :
            event.filter == T.write.rawValue ? .write :
            event.filter == T.signal.rawValue ? .signal :
            event.filter == T.vnode.rawValue ? .vnode :
            event.filter == T.timer.rawValue ? .timer :
            event.filter == T.proc.rawValue ? .proc :
             .user
        
        self.userData = .pointer(event.udata)
        
        switch self.type {
        case KernelEventType.vnode:
            self.flags = KernelEventVnodeFlags(rawValue: event.fflags)
        case KernelEventType.timer:
            self.flags = KernelEventTimerFlags(rawValue: event.fflags)
        case KernelEventType.proc:
            self.flags = KernelEventProcessFlags(rawValue: event.fflags)
        default:
            self.flags = KernelEventFlagsNone()
        }
    }
    
    public init(ident: UInt, type: KernelEventType, flags: KernelEventFlags, userData: KernelEventUserData? = nil) {
        self.identifier = ident
        self.type = type
        self.flags = flags
        self.userData = userData
    }
    
    public static func readEv(ident: Int32, userData: KernelEventUserData? = nil) -> KernelEventDescriptor{
        return KernelEventDescriptor(ident: UInt(ident), type: .read, flags: KernelEventFlagsNone(),userData: userData)
    }
    
    public static func writeEv(ident: Int32, userData: KernelEventUserData? = nil) -> KernelEventDescriptor {
        return KernelEventDescriptor(ident: UInt(ident), type: .write, flags: KernelEventFlagsNone(),userData: userData)
    }
    
    public static func fileEv(fd: Int32, for evs: KernelEventFlags.Vnode,userData: KernelEventUserData? = nil) -> KernelEventDescriptor {
        return KernelEventDescriptor(ident: UInt(fd), type: .vnode, flags: evs, userData: userData)
    }
    
    public static func timerEv(ident: UInt, unit: KernelEventFlags.Timer, userData: KernelEventUserData? = nil) -> KernelEventDescriptor {
        return KernelEventDescriptor(ident: ident, type: .timer, flags: unit, userData: userData)
    }
    
    public static func processEv(pid: pid_t, for evs: KernelEventFlags.Process, userData: KernelEventUserData? = nil) -> KernelEventDescriptor {
        return KernelEventDescriptor(ident: UInt(pid), type: .proc, flags: evs, userData: userData)
    }
    
    public static func signalEv(sig: Int32, userData: KernelEventUserData? = nil) -> KernelEventDescriptor {
        return KernelEventDescriptor(ident: UInt(sig), type: .signal, flags: KernelEventFlagsNone(), userData: userData)
    }
    
    public static func userEv(ident: UInt, options: KernelEventFlags.User, userData: KernelEventUserData? = nil) -> KernelEventDescriptor {
        return KernelEventDescriptor(ident: ident, type: .user, flags: options, userData: userData)
    }
    
    internal func makeEvent(_ action: KernelEventAction) -> KernelEvent {
        return KernelEvent(ident: identifier, filter: type.rawValue, flags: action.rawValue, fflags: flags.rawValue, data: 0, udata: userData == nil ? nil : userData!.rawValue)
    }
}
    
extension KernelEventDescriptor: Equatable {
    public static func ==(lhs: KernelEventDescriptor, rhs: KernelEventDescriptor) -> Bool {
        return lhs.identifier == rhs.identifier && lhs.type == rhs.type
    }
}
 
public extension xlibc.kevent {
    
    public static func readEvent(_ ident: Int32, action: KernelEventAction, udata: UnsafeMutableRawPointer? = nil) -> kevent {
        return KernelEvent(ident: UInt(ident),
                    filter: KernelEventType.read.rawValue,
                    flags: action.rawValue,
                    fflags: 0, data: 0,
                    udata: udata)
    }
    
    public static func writeEvent(_ ident: Int32, action: KernelEventAction, udata: UnsafeMutableRawPointer? = nil) -> kevent {
        return KernelEvent(ident: UInt(ident),
                    filter: KernelEventType.write.rawValue,
                    flags: action.rawValue,
                    fflags: 0, data: 0,
                    udata: udata)
    }
    
    public static func fileEvent(_ ident: Int32, action: KernelEventAction, filter: KernelEventFlags.Vnode, udata: UnsafeMutableRawPointer? = nil) -> kevent {
        return KernelEvent(ident: UInt(ident),
                    filter: KernelEventType.write.rawValue,
                    flags: action.rawValue,
                    fflags: filter.rawValue,
                    data: 0, udata: udata)
    }
    
    public static func processEvent(_ pid: pid_t, action: KernelEventAction, filter: KernelEventFlags.Process, udata: UnsafeMutableRawPointer? = nil) -> kevent {
        return KernelEvent(ident: UInt(pid),
                    filter: KernelEventType.proc.rawValue,
                    flags: action.rawValue,
                    fflags: filter.rawValue, data: 0,
                    udata: udata)
    }
    
    public static func signalEvent(_ signal: Int32, action: KernelEventAction, udata: UnsafeMutableRawPointer? = nil) -> kevent {
        return KernelEvent(ident: UInt(signal),
                    filter: KernelEventType.signal.rawValue,
                    flags: action.rawValue,
                    fflags: 0, data: 0,
                    udata: udata)
    }
    
    public static func timerEvent(id: UInt, action: KernelEventAction, timeout: Int, unit: KernelEventFlags.Timer, udata: UnsafeMutableRawPointer? = nil) -> kevent {
        return KernelEvent(ident: id,
                    filter: KernelEventType.timer.rawValue,
                    flags: action.rawValue,
                    fflags: unit.rawValue,
                    data: timeout, udata: udata)
    }
}
    
public struct KernelEventType: RawRepresentable, Equatable {
    
    public typealias RawValue = Int16
    public var rawValue: Int16
    public init(rawValue: Int16) {
        self.rawValue = rawValue
    }
    
    public init(rawValue: Int32) {
        self.rawValue = Int16(rawValue)
    }
    
    public static func ==(lhs: KernelEventType, rhs: KernelEventType) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    /// Takes a file descriptor as the identifier, and returns whenever there
    /// is data available to read. The behavior of the filter is slightly
    /// different depending on descriptor type.
    ///
    /// *Sockets*
    ///
    /// Socket which have previously been passed to `listen()` return when there
    /// is an incoming connection pending. `data` contains the size of the listen
    /// backlog.
    /// Other socket descriptors return when there is data to be read, subject to
    /// the SO_RCVLOWAT value of the socket buffer. This maybe overridden with a
    /// per-filter low water mark at the time the filter is added by setting the
    /// `NOTE_LOWAT` flag in `fflags`, and specifying the new low water mark in
    /// `data`. On return `data` contains the number of bytes of protocol data
    /// available to read.
    /// If the read direction of the socket has shutdown, then the filter also sets
    /// `EV_EOF` in `flags`, and returns the socket error (if any) in fflags. It is
    /// possible for EOF to be returned (indicating the connection is gone) while
    /// there is still data pending in the socket buffer.
    ///
    /// *Vnodes*
    ///
    /// Returns when the file pointer is not at the end of file. `data` contains the
    /// offset from current position to end of file, and may be negative.
    /// This behavior is different from `poll`, where read events are triggered for
    /// regular files unconditionally. This event can be triggered unconditionally by
    /// setting the `NOTE_FILE_POLL` (FreeBSD) flag in `fflags`.
    ///
    /// *Fifos, Pipes*
    ///
    /// Returns when the there is data to read; `data` contains the numener of bytes
    /// available.
    /// When the last writer disconnects, the filter will set EV_EOF in `flags`. This
    /// may be cleared by passing in `EV_CLEAR`, at which point the filter will resume
    /// waiting for data to become available before returning.
    ///
    /// *Device nodes (OS X)*
    ///
    /// Returns when there is data to read from the device; `data` contains the number
    /// of bytes available. If the device does not support returning number of bytes, it
    /// will not allow the filter to be attached. However, if the `NOTE_LOWAT` flag is
    /// specified and the `data` field contains 1 on input, those devices will attach
    /// count of bytes to read on output.
    ///
    /// *BPF devices (FreeBSD)*
    ///
    /// Returns when the BPF buffer is full, the `BPF` timeout has expired, or when the BPF
    /// has `immediate mode` enabled and these is any data to read; `data` contains the
    /// number of bytes available.
    public static let read = KernelEventType(rawValue: EVFILT_READ)
    
    /// Takes a file descriptor as the identifier, and returns whenever it is
    /// possible to write to the descriptor. For sockets, pipes and fifos, `data`
    /// will contain the amount of space remaining in the write buffer. The filter
    /// will set `EV_EOF` when the reader disconnects, and for the fifo case, this
    /// may be cleared by use of `EV_CLEAR`. Note that this filter is not supported
    /// for vnodes.
    ///
    /// For sockets, the low water mark and socket error handling is identical to the
    /// `EVFILT_READ` case
    public static let write = KernelEventType(rawValue: EVFILT_WRITE)
    
    /// The sigevent portion of the AIO request is filled in, with `sigev_notify_kqueue`
    /// containing the kevent flags which should be `EV_ONESHOT`, `EV_CLEAR`, or
    /// `EV_DISPATCH`, `sigev_value` containing the udata value, and `sigev_notify` set
    /// to `SIGEVKernelEventENT`. When the `aio_*()` system call is made, the event will be
    /// registered with the specified kqueue, and the ident argument set to the
    /// `struct aiocb` returned by the `aio_*()` system call. The filter returns under
    /// the same conditions as `aio_error()`.
    ///
    /// Absolute useless in Darwin, aka Apple Platform since it's not implemented.
    public static let aio = KernelEventType(rawValue: EVFILT_AIO)
    
    /// In Darwin, Returns when the file pointer is not at the end of file. `data` contains
    /// the offset from current position to end of file, and maybe negative.
    ///
    /// In BSD, Takes a file descriptor as the identifier and the events to watch for in
    /// `fflags`, and returns when one or more of the requested events occurs on the
    /// descriptor. The events to monitor are:
    ///
    /// *NOTE_ATTRIB*
    ///
    /// The file referenced by the descriptor had its attributes changed.
    ///
    /// *NOTE_CLOSE*
    ///
    /// A file descriptor referencing the monitored file, was closed. The closed file
    /// descriptor did not have write access.
    ///
    /// *NOTE_CLOSE_WRITE*
    ///
    /// A file descriptor referencing the monitored file, was closed. The closed file
    /// descriptor has write access.
    ///
    /// This note, as well as `NOTE_CLOSE`, are not activated when files are closed forcibly
    /// by `unmount` or `revoke`. Instead, `NOTE_REVOKE` is sent for such events.
    ///
    /// *NOTE_DELETE*
    ///
    /// The `unlink()` system call was called on the file referenced by the descriptor.
    ///
    /// *NOTE_EXTEND*
    ///
    /// For regular file, the file referenced by the descriptor was extended.
    ///
    /// For directory, reports that a directory entry was added or removed, as the result
    /// of rename operation. The `NOTE_EXTEND` event is not reported when a name is changed
    /// inside the directory.
    ///
    /// *NOTE_LINK*
    ///
    /// The link count on the file changed. In particular, the `NOTE_LINK` event is reported
    /// if a subdirectory was created pr de;eted inside the directory referenced by the
    /// descriptor.
    ///
    /// *NOTE_OPEN*
    ///
    /// The file referenced by the descriptor was opened.
    ///
    /// *NOTE_READ*
    ///
    /// A read occurred on the file referenced by the descriptor.
    ///
    /// *NOTE_RENAME*
    ///
    /// The file referenced by the descriptor was renamed
    ///
    /// *NOTE_REVOKE*
    ///
    /// Access to the file was revoked via `revoke(2)` or the underlying file system was
    /// unmounted.
    ///
    /// *NOTE_WRITE*
    ///
    /// A write occurred on the file referenced by the descriptor.
    ///
    /// On return, `fflags` contains the events which triggered the filter.
    public static let vnode = KernelEventType(rawValue: EVFILT_VNODE)
    
    
    /// Takes the process ID to monitor as the identifier and the events to watch
    /// for in `fflags`, and returns when the process performs one or more of the
    /// requested events. If a process can normally see another process, it can
    /// attach an event to it. The events to monitor are:
    ///
    /// *NOTE_EXIT*
    ///
    /// The process has exited. The exit status will be stored in `data`.
    ///
    /// *NOTE_FORK*
    ///
    /// The process created a child process via `fork()` or similar call.
    ///
    /// *NOTE_EXEC*
    ///
    /// The process executed a new process via `execve` or similar call.
    ///
    /// *NOTE_SIGNAL*
    ///
    /// The process was sent a signal. Status can be checked via waitpid or similar call.
    public static let proc = KernelEventType(rawValue: EVFILT_PROC)
    
    
    /// Takes the signal number to monitor as the identifier and returns when the
    /// given signal is delivered to the process. This coexists with the `signal()`
    /// and `sigaction()` facilities, and has a lower precedence. Only signals
    /// sent to the process, not to a particular thread, will trigger and the
    /// filter. The filter will record all attempts to deliver a signal to a
    /// process, even if the signal has been marked as `SIG_IGN`. Event notification
    /// happends before normal signal delivery processing. `data` returns the number
    /// of times the signal has been generated since the last call to `kevent()`.
    /// This filter automatically sets the `EV_CLEAR` flag internally.
    public static let signal = KernelEventType(rawValue: EVFILT_SIGNAL)
    
    
    /// Establishes an arbitrary timer identified by `ident`. When adding a timer,
    /// `data` specifies the timeout period. The timer will be periodic unless `EV_ONESHOT`
    /// is specified. On return, `data` contains the number of times the timeout has
    /// expired since the last call to `kevent()`. This filter automatically sets
    /// the `EV_CLEAR` flag internally. There is a system wide limit on the number
    /// of timers which is controlled by the `kern.kq_calloutmax` sysctl (FreeBSD).
    ///
    /// *NOTE_SECONDS*
    ///
    /// `data` is in seconds.
    ///
    /// *NOTE_MSECONDS*
    ///
    /// `data` is in milliseconds.
    ///
    /// *NOTE_USECONDS*
    ///
    /// `data` is in microseconds.
    ///
    /// *NOTE_NSECONDS*
    ///
    /// `data` is in nanoseconds.
    ///
    /// *NOTE_ABSOLUTE (Darwin)*
    ///
    /// `data` is an absolute timeout
    ///
    /// *NOTE_CRITICAL (Darwin)*
    ///
    /// system makes a best effort to fire this timer as scheduled.
    ///
    /// *NOTE_BACKGROUND (Darwin)*
    ///
    /// system has extra leeway to coalesce this timer.
    ///
    /// *NOTE_LEEWAY (Darwin)*
    ///
    /// exit[1] holds user-supplied slop in deadline for timer coalescing.
    ///
    /// If `fflags` is not set, the default is milliseconds. On return, fflags
    /// contains the events which triggered the filter.
    public static let timer = KernelEventType(rawValue: EVFILT_TIMER)
    
    
    /// Establishes a user event identified by `ident` which is not associated with
    /// any kernel mechanism but is triggered by user level code. The lower 24 bits
    /// of the fflags may be used for user defined flags and manipulated using the
    /// following:
    ///
    /// *NOTE_FFNOP*
    ///
    /// Ignore the input fflags.
    ///
    /// *NOTE_FFAND*
    ///
    /// Bitwise AND fflags.
    ///
    /// *NOTE_FFCOPY*
    ///
    /// Copy `fflags`.
    ///
    /// *NOTE_FFCTRLMASK*
    ///
    /// Control mask for fflags
    ///
    /// *NOTE_FFLAGSMASK*
    ///
    /// User defined flag mask for fflags.
    ///
    /// A user event is triggered for output with the following:
    ///
    /// *NOTE_TRIFFER*
    ///
    /// Cause the event to be triffered/
    public static let user = KernelEventType(rawValue: EVFILT_USER)
    
    #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
    /// Takes the name of a mach port, or port set, in `ident` and waits until a
    /// message is enqueued on the port or port set. When a message is detected,
    /// but not directly received by the kevent call, the name of the specific port
    /// where the message is enqueued is returned in `data`. If `fflags` contains
    /// `MACH_RCV_MSG`, the `ext[0]` and `ext[1]` flags are assumed to contain
    /// a pointer to the buffer where the message is to be received and the size
    /// of the receive buffer, respectively. If `MACH_RCV_MSG` is specified,
    /// yet the buffer size in `ext[1]` is zero, The space for the buffer may be
    /// carved out of the data_out area provided to `kevent_qos() if there is enough
    /// space remaining there.
    public static let machPort = KernelEventType(rawValue: EVFILT_MACHPORT)
    
    /// The following has not documented in either Darwin nor FreeBSD
    //        public static let fileSystem = Filter(rawValue: EVFILT_FS)
    //        public static let virtualMemory = Filter(rawValue: EVFILT_VM)
    #endif
    
    
    
    /// Takes a descriptor as the identifier, and returns whenever one of the
    /// specified exceptional conditions has occurred on the descriptor. Conditions
    /// are specified in `fflags`. Currently, this filter can be used to monitor the
    /// arrival of out-of-band data on a socket descriptor using the filter flag
    /// `NOTE_OOB`
    ///
    /// If the read direction of the socket has shutdown, then the filter also set
    /// `EV_EOF` in `flags`, and returns the socket error (if any) in `fflags`.
    public static let exception = KernelEventType(rawValue: EVFILT_EXCEPT)
    
}
    
#if arch(x86_64) || arch(arm64)
public enum KernelEventUserData {
    case int(Int)
    case uint(UInt)
    case int64(Int64)
    case uint64(UInt64)
    case int32(Int64)
    case uint32(UInt32)
    case int16(Int16)
    case uint16(UInt16)
    case int8(Int8)
    case uint8(UInt8)
    case pointer(MutablePointerType)
    
    var rawValue: UnsafeMutableRawPointer! {
        switch self {
        case let .int(i):
            return UInt(i) == 0 ? nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
        case let .uint(i):
            return UInt(i) == 0 ? nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            
        case let .int64(i):
            return UInt(i) == 0 ? nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
        case let .uint64(i):
            return UInt(i) == 0 ? nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            
        case let .int32(i):
            return UInt(i) == 0 ? nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
        case let .uint32(i):
            return UInt(i) == 0 ? nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            
        case let .int16(i):
            return UInt(i) == 0 ? nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
        case let .uint16(i):
            return UInt(i) == 0 ? nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            
        case let .int8(i):
            return UInt(i) == 0 ? nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
        case let .uint8(i):
            return UInt(i) == 0 ? nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            
        case let .pointer(p):
            return p.mutableRawPointer
        }
    }
}
#else
public enum KernelEventUserData {
    case int(Int)
    case uint(UInt)
    case int32(Int64)
    case uint32(UInt32)
    case int16(Int16)
    case uint16(UInt16)
    case pointer(MutablePointerType)
    
    var rawValue: UnsafeMutableRawPointer! {
        switch self {
        case let .int(i):
            return UInt(i) == 0 ? nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
        case let .uint(i):
            return UInt(i) == 0 ? nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            
        case let .int32(i):
            return UInt(i) == 0 ? nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
        case let .uint32(i):
            return UInt(i) == 0 ? nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            
        case let .int16(i):
            return UInt(i) == 0 ? nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
        case let .uint16(i):
            return UInt(i) == 0 ? nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            
        case let .int8(i):
            return UInt(i) == 0 ? nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
        case let .uint8(i):
            return UInt(i) == 0 ? nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            
        case let .pointer(p):
            return p.mutableRawPointer
        }
    }
}
#endif
    
public struct KernelEventAction: OptionSet {
    public typealias RawValue = UInt16
    public var rawValue: UInt16
    
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
    
    public init(rawValue: Int32) {
        self.rawValue = UInt16(rawValue)
    }
    
    public static let add = KernelEventAction(rawValue: EV_ADD)
    public static let delete = KernelEventAction(rawValue: EV_DELETE)
    public static let enable = KernelEventAction(rawValue: EV_ENABLE)
    public static let disable = KernelEventAction(rawValue: EV_DISABLE)
    public static let dispatch = KernelEventAction(rawValue: EV_DISPATCH)
    public static let receipt = KernelEventAction(rawValue: EV_RECEIPT)
    public static let oneshot = KernelEventAction(rawValue: EV_ONESHOT)
    public static let clear = KernelEventAction(rawValue: EV_CLEAR)
    public static let outOfBand = KernelEventAction(rawValue: EV_OOBAND)
    public static let error = KernelEventAction(rawValue: EV_ERROR)
    public static let eof = KernelEventAction(rawValue: EV_EOF)
}

public struct KernelEventVnodeFlags: KernelEventFlags, RawRepresentable {
    public typealias RawValue = UInt32
    public var rawValue: UInt32
    
    public init(rawValue: Int32) {
        self.rawValue = UInt32(rawValue)
    }
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    public static let attributesChanged = KernelEventVnodeFlags(rawValue: NOTE_ATTRIB)
    public static let delete = KernelEventVnodeFlags(rawValue: NOTE_DELETE)
    public static let extend = KernelEventVnodeFlags(rawValue: NOTE_EXTEND)
    public static let link = KernelEventVnodeFlags(rawValue: NOTE_LINK)
    public static let rename = KernelEventVnodeFlags(rawValue: NOTE_RENAME)
    public static let revote = KernelEventVnodeFlags(rawValue: NOTE_REVOKE)
    public static let write = KernelEventVnodeFlags(rawValue: NOTE_WRITE)
}

public struct KernelEventProcessFlags: KernelEventFlags, RawRepresentable {
    public typealias RawValue = UInt32
    public var rawValue: UInt32
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    public init(rawValue: Int32) {
        self.rawValue = UInt32(rawValue)
    }

    public static let exit = KernelEventProcessFlags(rawValue: NOTE_EXIT)
    public static let fork = KernelEventProcessFlags(rawValue: NOTE_FORK)
    public static let exec = KernelEventProcessFlags(rawValue: NOTE_EXEC)
    public static let track = KernelEventProcessFlags(rawValue: NOTE_TRACK)
}

public struct KernelEventTimerFlags: KernelEventFlags {
    public typealias RawValue = UInt32
    public var rawValue: UInt32
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    public init(rawValue: Int32) {
        self.rawValue = UInt32(rawValue)
    }
    
    public static let seconds = KernelEventTimerFlags(rawValue: NOTE_SECONDS)
    public static let macroseconds = KernelEventTimerFlags(rawValue: NOTE_USECONDS)
    public static let nanoseconds = KernelEventTimerFlags(rawValue: NOTE_NSECONDS)
}

public struct KernelEventUserFlags: KernelEventFlags, RawRepresentable {
    public typealias RawValue = UInt32
    public var rawValue: UInt32
    
    public init(rawValue: Int32) {
        self.rawValue = UInt32(rawValue)
    }
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    public static let ignore = KernelEventUserFlags(rawValue: NOTE_FFNOP)
    public static let bitand = KernelEventUserFlags(rawValue: NOTE_FFAND)
    public static let bitor = KernelEventUserFlags(rawValue: NOTE_FFOR)
    public static let copy = KernelEventUserFlags(rawValue: NOTE_FFNOP)
    public static let cntrlmask = KernelEventUserFlags(rawValue: NOTE_FFCTRLMASK)
    public static let flagsmask = KernelEventUserFlags(rawValue: NOTE_FFLAGSMASK)
    public static let trigger = KernelEventUserFlags(rawValue: NOTE_TRIGGER)
}
    
public struct KernelEventFlagsNone: KernelEventFlags, RawRepresentable {
    public typealias RawValue = UInt32
    public var rawValue: UInt32 {
        return 0
    }
    public init(rawValue: UInt32) {}
    public init() {}
}
    
public extension KernelEventFlags
{
    public typealias Vnode = KernelEventVnodeFlags
    public typealias Timer = KernelEventTimerFlags
    public typealias Process = KernelEventProcessFlags
    public typealias User = KernelEventUserFlags
    public typealias None = KernelEventFlagsNone
}
#endif
