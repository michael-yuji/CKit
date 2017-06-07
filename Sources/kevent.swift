

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
//  Copyright © 2017 Yuji. All rights reserved.
//


#if os(FreeBSD) || os(PS4)
    public enum KernelEventType: Int16
    {
        case read = -1
        case write = -2
        case aio = -3
        case vnode = -4
        case process = -5
        case signal = -6
        case timer = -7
        case user = -11
        
        public typealias RawValue = Int16
        public var rawValue: Int16
        {
            switch self {
            case .read:
                return -1
            case .write:
                return -2
            case .aio:
                return -3
            case .vnode:
                return -4
            case .process:
                return -5
            case .signal:
                return -6
            case .timer:
                return -7
            case .user:
                return -11
            default:
                return 0
            }
        }
        
        public init(rawValue: Int16)
        {
            self =
                rawValue == -1 ? .read :
                rawValue == -2 ? .write :
                rawValue == -3 ? .aio :
                rawValue == -4 ? .vnode :
                rawValue == -5 ? .process :
                rawValue == -6 ? .signal :
                rawValue == -7 ? .timer :
                rawValue == -11 ? .user :
                .user
        }
    }
#endif

#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
    public enum KernelEventType: Int16
    {
        case read = -1
        case write = -2
        case aio = -3
        case vnode = -4
        case process = -5
        case signal = -6
        case timer = -7
        case user = -10
        case macport = -8
        case vm = -12
        case except = -15
        
        public typealias RawValue = Int16
        public var rawValue: Int16
        {
            switch self {
            case .read:
                return -1
            case .write:
                return -2
            case .aio:
                return -3
            case .vnode:
                return -4
            case .process:
                return -5
            case .signal:
                return -6
            case .timer:
                return -7
            case .user:
                return -10
            case .macport:
                return -8
            case .vm:
                return -12
            case .except:
                return -15
            }
        }
        
        public init(rawValue: Int16)
        {
            self =
                rawValue == -1 ? .read :
                rawValue == -2 ? .write :
                rawValue == -3 ? .aio :
                rawValue == -4 ? .vnode :
                rawValue == -5 ? .process :
                rawValue == -6 ? .signal :
                rawValue == -7 ? .timer :
                rawValue == -10 ? .user :
                rawValue == -8 ? .macport :
                rawValue == -12 ? .vm :
                rawValue == -15 ? .except :
                .user
        }
    }
#endif


#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS) || os(FreeBSD) || os(PS4)
    
    public typealias KernelEvent = kevent
    
    public protocol KernelEventFlags
    {
        var rawValue: UInt32 { get }
    }
    
    /// A bit compatible type of kevent, with some more understandble name
    public struct KernelEventResult
    {
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
    
    /// basically kevent without action
    public struct KernelEventDescriptor {
        public var identifier: UInt
        public var type: KernelEventType
        public var flags: KernelEventFlags
        public var userData: KernelEventUserData?
    }
    
    // -MARK: Initialization
    extension KernelEventDescriptor
    {
        public init(event: KernelEvent)
        {
            self.identifier = event.ident
            self.type = KernelEventType(rawValue: event.filter)
            self.userData = .pointer(event.udata)
            
            switch self.type {
            case KernelEventType.vnode:
                self.flags = KernelEventVnodeFlags(rawValue: event.fflags)
            case KernelEventType.timer:
                self.flags = KernelEventTimerFlags(rawValue: event.fflags)
            case KernelEventType.process:
                self.flags = KernelEventProcessFlags(rawValue: event.fflags)
            default:
                self.flags = KernelEventFlagsNone()
            }
        }
        
        public init(ident: UInt,
                    type: KernelEventType,
                    flags: KernelEventFlags,
                    userData: KernelEventUserData? = nil)
        {
            self.identifier = ident
            self.type = type
            self.flags = flags
            self.userData = userData
        }
    }
    
    extension KernelEventDescriptor
    {
        public static func read(ident: Int32,
                                userData: KernelEventUserData? = nil
            ) -> KernelEventDescriptor
        {
            return KernelEventDescriptor(ident: UInt(ident),
                                         type: .read,
                                         flags: KernelEventFlagsNone(),
                                         userData: userData)
        }
        
        public static func write(ident: Int32,
                                 userData: KernelEventUserData? = nil
            ) -> KernelEventDescriptor
        {
            return KernelEventDescriptor(ident: UInt(ident),
                                         type: .write,
                                         flags: KernelEventFlagsNone(),
                                         userData: userData)
        }
        
        public static func file(fd: Int32,
                                for evs: KernelEventFlags.Vnode,
                                userData: KernelEventUserData? = nil
            ) -> KernelEventDescriptor
        {
            return KernelEventDescriptor(ident: UInt(fd),
                                         type: .vnode,
                                         flags: evs,
                                         userData: userData)
        }
        
        public static func timer(ident: UInt,
                                 unit: KernelEventFlags.Timer,
                                 userData: KernelEventUserData? = nil
            ) -> KernelEventDescriptor
        {
            return KernelEventDescriptor(ident: ident,
                                         type: .timer,
                                         flags: unit,
                                         userData: userData)
        }
        
        public static func process(pid: pid_t,
                                   for evs: KernelEventFlags.Process,
                                   userData: KernelEventUserData? = nil
            ) -> KernelEventDescriptor
        {
            return KernelEventDescriptor(ident: UInt(pid),
                                         type: .process,
                                         flags: evs,
                                         userData: userData)
        }
        
        public static func signal(sig: Int32,
                                  userData: KernelEventUserData? = nil
            ) -> KernelEventDescriptor
        {
            return KernelEventDescriptor(ident: UInt(sig),
                                         type: .signal,
                                         flags: KernelEventFlagsNone(),
                                         userData: userData)
        }
        
        public static func user(ident: UInt,
                                options: KernelEventFlags.User,
                                userData: KernelEventUserData? = nil
            ) -> KernelEventDescriptor
        {
            return KernelEventDescriptor(ident: ident,
                                         type: .user,
                                         flags: options,
                                         userData: userData)
        }
        
        public func makeEvent(_ action: KernelEventAction) -> KernelEvent
        {
            return KernelEvent(ident: identifier,
                               filter: type.rawValue,
                               flags: action.rawValue,
                               fflags: flags.rawValue,
                               data: 0,
                               udata: userData == nil ? nil : userData!.rawValue)
        }
    }
    
    extension KernelEventDescriptor: Equatable
    {
        public static func ==(lhs: KernelEventDescriptor,
                              rhs: KernelEventDescriptor) -> Bool
        {
            return lhs.identifier == rhs.identifier && lhs.type == rhs.type
        }
    }
    
    public extension xlibc.kevent
    {
        public static func readEvent(_ ident: Int32,
                                     action: KernelEventAction,
                                     udata: UnsafeMutableRawPointer? = nil
            ) -> kevent
        {
            return KernelEvent(ident: UInt(ident),
                               filter: KernelEventType.read.rawValue,
                               flags: action.rawValue,
                               fflags: 0, data: 0,
                               udata: udata)
        }
        
        public static func writeEvent(_ ident: Int32,
                                      action: KernelEventAction,
                                      udata: UnsafeMutableRawPointer? = nil
            ) -> kevent
        {
            return KernelEvent(ident: UInt(ident),
                               filter: KernelEventType.write.rawValue,
                               flags: action.rawValue,
                               fflags: 0, data: 0,
                               udata: udata)
        }
        
        public static func fileEvent(_ ident: Int32,
                                     action: KernelEventAction,
                                     filter: KernelEventFlags.Vnode,
                                     udata: UnsafeMutableRawPointer? = nil
            ) -> kevent
        {
            return KernelEvent(ident: UInt(ident),
                               filter: KernelEventType.write.rawValue,
                               flags: action.rawValue,
                               fflags: filter.rawValue,
                               data: 0, udata: udata)
        }
        
        public static func processEvent(_ pid: pid_t,
                                        action: KernelEventAction,
                                        filter: KernelEventFlags.Process,
                                        udata: UnsafeMutableRawPointer? = nil
            ) -> kevent
        {
            return KernelEvent(ident: UInt(pid),
                               filter: KernelEventType.process.rawValue,
                               flags: action.rawValue,
                               fflags: filter.rawValue, data: 0,
                               udata: udata)
        }
        
        public static func signalEvent(_ signal: Int32,
                                       action: KernelEventAction,
                                       udata: UnsafeMutableRawPointer? = nil
            ) -> kevent
        {
            return KernelEvent(ident: UInt(signal),
                               filter: KernelEventType.signal.rawValue,
                               flags: action.rawValue,
                               fflags: 0, data: 0,
                               udata: udata)
        }
        
        public static func timerEvent(id: UInt,
                                      action: KernelEventAction,
                                      timeout: Int,
                                      unit: KernelEventFlags.Timer,
                                      udata: UnsafeMutableRawPointer? = nil
            ) -> kevent
        {
            return KernelEvent(ident: id,
                               filter: KernelEventType.timer.rawValue,
                               flags: action.rawValue,
                               fflags: unit.rawValue,
                               data: timeout, udata: udata)
        }
    }
    
#if arch(arm) || arch(i386)
    public enum KernelEventUserData
    {
        case int(Int)
        case uint(UInt)
        case int64(Int64)
        case uint64(UInt64)
        case int16(Int16)
        case uint16(UInt16)
        case int8(Int8)
        case uint8(UInt8)
        
        case pointer(UnsafeMutableRawPointer)
        var rawValue: UnsafeMutableRawPointer!
        {
            switch self {
            case let .int(i):
                return UInt(i) == 0 ?
                    nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            case let .uint(i):
                return UInt(i) == 0 ?
                    nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            case let .int64(i):
                return UInt(i) == 0 ?
                    nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            case let .uint64(i):
                return UInt(i) == 0 ?
                    nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            case let .int16(i):
                return UInt(i) == 0 ?
                    nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            case let .uint16(i):
                return UInt(i) == 0 ?
                    nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            case let .int8(i):
                return UInt(i) == 0 ?
                    nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            case let .uint8(i):
                return UInt(i) == 0 ?
                    nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            case let .pointer(p):
                return p
            }
        }
    }
#endif
    
#if arch(x86_64) || arch(arm64)
    public enum KernelEventUserData
    {
        case int(Int)
        case uint(UInt)
        case int64(Int64)
        case uint64(UInt64)
        case int32(Int32)
        case uint32(UInt32)
        case int16(Int16)
        case uint16(UInt16)
        case int8(Int8)
        case uint8(UInt8)
        
        case pointer(UnsafeMutableRawPointer)
        var rawValue: UnsafeMutableRawPointer!
        {
            switch self {
            case let .int(i):
                return UInt(i) == 0 ?
                    nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            case let .uint(i):
                return UInt(i) == 0 ?
                    nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            case let .int64(i):
                return UInt(i) == 0 ?
                    nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            case let .uint64(i):
                return UInt(i) == 0 ?
                    nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            case let .int32(i):
                return UInt(i) == 0 ?
                    nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            case let .uint32(i):
                return UInt(i) == 0 ?
                    nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            case let .int16(i):
                return UInt(i) == 0 ?
                    nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            case let .uint16(i):
                return UInt(i) == 0 ?
                    nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            case let .int8(i):
                return UInt(i) == 0 ?
                    nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            case let .uint8(i):
                return UInt(i) == 0 ?
                    nil : UnsafeMutableRawPointer(bitPattern: UInt(i))
            case let .pointer(p):
                return p
            }
        }
    }
#endif
    
    
    public struct KernelEventAction: OptionSet
    {
        public typealias RawValue = UInt16
        public var rawValue: UInt16
        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }
        
        public static let add
            = KernelEventAction(rawValue: UInt16(EV_ADD))
        public static let delete
            = KernelEventAction(rawValue: UInt16(EV_DELETE))
        public static let enable
            = KernelEventAction(rawValue: UInt16(EV_ENABLE))
        public static let disable
            = KernelEventAction(rawValue: UInt16(EV_DISABLE))
        public static let dispatch
            = KernelEventAction(rawValue: UInt16(EV_DISPATCH))
        public static let receipt
            = KernelEventAction(rawValue: UInt16(EV_RECEIPT))
        public static let oneshot
            = KernelEventAction(rawValue: UInt16(EV_ONESHOT))
        public static let clear
            = KernelEventAction(rawValue: UInt16(EV_CLEAR))
        public static let error
            = KernelEventAction(rawValue: UInt16(EV_ERROR))
        public static let eof
            = KernelEventAction(rawValue: UInt16(EV_EOF))
    }
    
    public struct KernelEventReadFlags: KernelEventFlags, RawRepresentable
    {
        public typealias RawValue = UInt32
        public var rawValue: UInt32
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
    }
    
    public struct KernelEventWriteFlags: KernelEventFlags, RawRepresentable
    {
        public typealias RawValue = UInt32
        public var rawValue: UInt32
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
    }
    
    public struct KernelEventVnodeFlags: KernelEventFlags, RawRepresentable
    {
        public typealias RawValue = UInt32
        public var rawValue: UInt32
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        public static let attributesChanged
            = KernelEventVnodeFlags(rawValue: UInt32(NOTE_ATTRIB))
        public static let delete
            = KernelEventVnodeFlags(rawValue: UInt32(NOTE_DELETE))
        public static let extend
            = KernelEventVnodeFlags(rawValue: UInt32(NOTE_EXTEND))
        public static let link
            = KernelEventVnodeFlags(rawValue: UInt32(NOTE_LINK))
        public static let rename
            = KernelEventVnodeFlags(rawValue: UInt32(NOTE_RENAME))
        public static let revoke
            = KernelEventVnodeFlags(rawValue: UInt32(NOTE_REVOKE))
        public static let write
            = KernelEventVnodeFlags(rawValue: UInt32(NOTE_WRITE))
    }
    
    public struct KernelEventProcessFlags: KernelEventFlags, RawRepresentable
    {
        public typealias RawValue = UInt32
        public var rawValue: UInt32
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        public static let exit
            = KernelEventProcessFlags(rawValue: UInt32(NOTE_EXIT))
        public static let fork
            = KernelEventProcessFlags(rawValue: UInt32(NOTE_FORK))
        public static let exec
            = KernelEventProcessFlags(rawValue: UInt32(NOTE_EXEC))
        public static let track
            = KernelEventProcessFlags(rawValue: UInt32(NOTE_TRACK))
    }
    
    public struct KernelEventSignalFlags: KernelEventFlags, RawRepresentable
    {
        public typealias RawValue = UInt32
        public var rawValue: UInt32
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
    }
    
    public struct KernelEventTimerFlags: KernelEventFlags, RawRepresentable
    {
        public typealias RawValue = UInt32
        public var rawValue: UInt32
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        public static let seconds
            = KernelEventTimerFlags(rawValue: UInt32(NOTE_SECONDS))
        public static let macroseconds
            = KernelEventTimerFlags(rawValue: UInt32(NOTE_USECONDS))
        public static let nanoseconds
            = KernelEventTimerFlags(rawValue: UInt32(NOTE_NSECONDS))
    }
    
    public struct KernelEventUserFlags: KernelEventFlags, RawRepresentable
    {
        public typealias RawValue = UInt32
        public var rawValue: UInt32
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        public static let none
            = KernelEventUserFlags(rawValue: UInt32(NOTE_FFNOP))
        public static let ignore
            = KernelEventUserFlags(rawValue: UInt32(NOTE_FFNOP))
        public static let trigger
            = KernelEventUserFlags(rawValue: UInt32(NOTE_TRIGGER))
        public static let copy
            = KernelEventUserFlags(rawValue: UInt32(NOTE_FFNOP))
    }
    
    public struct KernelEventFlagsNone: KernelEventFlags, RawRepresentable
    {
        public typealias RawValue = UInt32
        public var rawValue: UInt32
        {
            return 0
        }
        public init(rawValue: UInt32) {}
        public init() {}
    }
    
    public extension KernelEventFlags
    {
        public typealias Read = KernelEventReadFlags
        public typealias Write = KernelEventWriteFlags
        public typealias Vnode = KernelEventVnodeFlags
        public typealias Process = KernelEventProcessFlags
        public typealias Signal = KernelEventSignalFlags
        public typealias Timer = KernelEventTimerFlags
        public typealias User = KernelEventUserFlags
        public typealias None = KernelEventFlagsNone
    }
    
#endif
