
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
//  Created by Yuji on 3/10/17.
//  Copyright © 2017 Yuji. All rights reserved.
//

#if !os(Linux)
public typealias KernelEvent = kevent
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
}
    
// MARK: Initialization
extension KernelEventDescriptor {
    public init(event: KernelEvent) {
        self.identifier = event.ident
        self.type = KernelEventType(rawValue: event.filter)
        
        typealias T = KernelEventType
        
        self.type = KernelEventType(rawValue: event.filter)
        
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
}

// MARK: Convenience init
extension KernelEventDescriptor {
    public static func read(ident: Int32, userData: KernelEventUserData? = nil) -> KernelEventDescriptor{
        return KernelEventDescriptor(ident: UInt(ident), type: .read, flags: KernelEventFlagsNone(),userData: userData)
    }
    
    public static func write(ident: Int32, userData: KernelEventUserData? = nil) -> KernelEventDescriptor {
        return KernelEventDescriptor(ident: UInt(ident), type: .write, flags: KernelEventFlagsNone(),userData: userData)
    }
    
    public static func file(fd: Int32, for evs: KernelEventFlags.Vnode,userData: KernelEventUserData? = nil) -> KernelEventDescriptor {
        return KernelEventDescriptor(ident: UInt(fd), type: .vnode, flags: evs, userData: userData)
    }
    
    public static func timer(ident: UInt, unit: KernelEventFlags.Timer, userData: KernelEventUserData? = nil) -> KernelEventDescriptor {
        return KernelEventDescriptor(ident: ident, type: .timer, flags: unit, userData: userData)
    }
    
    public static func process(pid: pid_t, for evs: KernelEventFlags.Process, userData: KernelEventUserData? = nil) -> KernelEventDescriptor {
        return KernelEventDescriptor(ident: UInt(pid), type: .proc, flags: evs, userData: userData)
    }
    
    public static func signal(sig: Int32, userData: KernelEventUserData? = nil) -> KernelEventDescriptor {
        return KernelEventDescriptor(ident: UInt(sig), type: .signal, flags: KernelEventFlagsNone(), userData: userData)
    }
    
    public static func user(ident: UInt, options: KernelEventFlags.User, userData: KernelEventUserData? = nil) -> KernelEventDescriptor {
        return KernelEventDescriptor(ident: ident, type: .user, flags: options, userData: userData)
    }
    
    public func makeEvent(_ action: KernelEventAction) -> KernelEvent {
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
    case pointer(UnsafeMutableRawPointer)
    
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
            return p
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
    
    public init() {
        self.rawValue = 0
    }

    public static let none = KernelEventUserFlags(rawValue: NOTE_FFNOP)
    public static let ignore = KernelEventUserFlags(rawValue: NOTE_FFNOP)
    public static let trigger = KernelEventUserFlags(rawValue: NOTE_TRIGGER)
    
    public static let copy = KernelEventUserFlags(rawValue: NOTE_FFNOP)
    
    public static func bitand(bits: Int32) -> KernelEventUserFlags {
        return KernelEventUserFlags(rawValue: NOTE_FFAND | (bits & NOTE_FFLAGSMASK))
    }
    
    public static func bitor(bits: Int32) -> KernelEventUserFlags {
        return KernelEventUserFlags(rawValue: NOTE_FFOR | UInt32(bits & NOTE_FFLAGSMASK))
    }
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
    
#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
    
    public extension KernelEventFlags
    {
        public typealias VM = KernelEventVMFlags
        public typealias Except = KernelEventExceptFlags
    }
    
    public struct KernelEventExceptFlags: KernelEventFlags, RawRepresentable {
        public typealias RawValue = UInt32
        public var rawValue: UInt32
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        public static let oob = KernelEventExceptFlags(rawValue: UInt32(NOTE_OOB))
    }
    
    public struct KernelEventVMFlags: KernelEventFlags, RawRepresentable {
        public typealias RawValue = UInt32
        public var rawValue: UInt32
        
        public init(rawValue: Int32) {
            self.rawValue = UInt32(rawValue)
        }
        
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        public static let pressure = KernelEventVMFlags(rawValue: NOTE_VM_PRESSURE)
    }
#endif
#endif
