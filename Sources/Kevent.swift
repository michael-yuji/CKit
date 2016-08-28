
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
//  Created by yuuji on 8/26/16.
//
//

import Foundation

#if os(FreeBSD) || os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
    @inline(__always)
    public func EV_SET(kevent _ke: inout kevent,
                       ident: Int32, filter: Int32,
                       flags: Int32, fflags: Int32,
                       data: Int32, udata: UnsafeMutableRawPointer!) {
        let event: UnsafeMutablePointer<kevent> = mutablePointer(of: &_ke)
        event.pointee.ident = UInt(ident)
        event.pointee.filter = Int16(filter)
        event.pointee.flags = UInt16(flags)
        event.pointee.fflags = UInt32(fflags)
        event.pointee.data = Int(data)
        event.pointee.udata = udata
    }
    
    public struct KEVAction: OptionSet, RawRepresentable {
        public typealias RawValue = Int32
        public var rawValue: Int32
        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
    }
    
    public extension KEVAction {
        public static let add = KEVAction(rawValue: EV_ADD)
        public static let enable = KEVAction(rawValue: EV_ENABLE)
        public static let disable = KEVAction(rawValue: EV_DISABLE)
        public static let dispatch = KEVAction(rawValue: EV_DISPATCH)
        public static let delete = KEVAction(rawValue: EV_DELETE)
        public static let receive = KEVAction(rawValue: EV_RECEIPT)
        public static let oneshot = KEVAction(rawValue: EV_ONESHOT)

        public static let clear = KEVAction(rawValue: EV_ENABLE)

        public static let eof = KEVAction(rawValue: EV_EOF)

    }
    
    internal func ==(lhs: KernelEvent, rhs: KernelEvent) -> Bool {
        return lhs.identifier == rhs.identifier && lhs.filter == rhs.filter
    }

    internal protocol KernelEvent {
        var ret: kevent {get set}
        var identifier: Int32 { get set }
        var filter: Int32 { get set }
        var flags: Int32 { get set }
        var fflags: Int32 { get }
    }
    
    
    public struct KEVFileDescriptorRead: KernelEvent {
        var ret = kevent()
        var identifier: Int32
        var filter: Int32 = EVFILT_READ
        var flags: Int32
        var fflags: Int32 = 0
    }
    
    public struct KEVFileDescriptorWrite: KernelEvent {
        var ret = kevent()
        var identifier: Int32
        var filter: Int32 = EVFILT_WRITE
        var flags: Int32
        var fflags: Int32 = 0
    }

    public struct KEVProcEvents: OptionSet, RawRepresentable {
        public typealias RawValue = UInt32
        public var rawValue: UInt32
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        public static let exit  = KEVProcEvents(rawValue: NOTE_EXIT)
        public static let fork  = KEVProcEvents(rawValue: UInt32(NOTE_FORK))
        public static let exec  = KEVProcEvents(rawValue: UInt32(NOTE_EXEC))
        public static let track = KEVProcEvents(rawValue: UInt32(NOTE_TRACK))
    }
    
    public struct KEVProcess: KernelEvent {
        var ret = kevent()
        var identifier: Int32
        var filter: Int32 = EVFILT_PROC
        var flags: Int32 = 0
        var fflags: Int32 {
            return Int32(events.rawValue)
        }
        var events: KEVProcEvents
        public var action: (KEVProcEvents) -> ()
    }
    
    public extension KEVProcess {
        public init(uid: uid_t, for events: KEVProcEvents, perform action: @escaping (KEVProcEvents) -> ()) {
            self.identifier = Int32(uid)
            self.events = events
            self.action = action
        }
        
        public var uid: uid_t {
            get {
                return uid_t(identifier)
            } set {
                identifier = Int32(newValue)
            }
        }
    }
    
    public enum KEVTimerUnit: RawRepresentable {
        public typealias RawValue = Int32
        case seconds
        case microseconds
        case nanoseconds
    }
    
    public extension KEVTimerUnit {
        public init?(rawValue: RawValue) {
            switch rawValue {
            case NOTE_SECONDS:
                self = .seconds
            case NOTE_USECONDS:
                self = .microseconds
            case NOTE_NSECONDS:
                self = .nanoseconds
            default:
                return nil
            }
        }
        public var rawValue: RawValue {
            get {
                switch self {
                case .seconds: return NOTE_SECONDS
                case .microseconds: return NOTE_USECONDS
                case .nanoseconds: return NOTE_NSECONDS
                }
            } set {
                switch rawValue {
                case NOTE_SECONDS:
                    self = .seconds
                case NOTE_USECONDS:
                    self = .microseconds
                case NOTE_NSECONDS:
                    self = .nanoseconds
                default:
                    break
                }
            }
        }
    }
    
    public enum KEVTimerMode {
        case once
        case periodic
    }
    
    public struct KEVTimer: KernelEvent {
        var ret = kevent()
        var identifier: Int32 = Int32(arc4random())
        var filter: Int32 = EVFILT_TIMER
        var flags: Int32 = 0
        var fflags: Int32 {
            return unit.rawValue
        }
        public var mode: KEVTimerMode
        public var unit: KEVTimerUnit
        public var time: time_t
        public var action: () -> ()
    }
    
    public extension KEVTimer {
        public init(scalar: UInt, unit: KEVTimerUnit, mode: KEVTimerMode = .periodic, perform action: @escaping () -> ()) {
            self.time = Int(scalar)
            self.unit = unit
            self.mode = mode
            self.action = action
        }
    }
//    
//    public struct KEVSingal: KernelEvent {
//        var ret = kevent()
//        var identifier: Int32
//        var filter: Int32 = EVFILT_SIGNAL
//        var flags: Int32
//        var fflags: Int32
//    }
//    
    public struct KEVFileEvents: OptionSet, RawRepresentable {
        public typealias RawValue = UInt32
        public var rawValue: UInt32
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        public static let delete    = KEVFileEvents(rawValue: UInt32(NOTE_DELETE))
        public static let write     = KEVFileEvents(rawValue: UInt32(NOTE_WRITE))
        public static let attrib    = KEVFileEvents(rawValue: UInt32(NOTE_ATTRIB))
        public static let link      = KEVFileEvents(rawValue: UInt32(NOTE_LINK))
        public static let rename    = KEVFileEvents(rawValue: UInt32(NOTE_RENAME))
        public static let revoke    = KEVFileEvents(rawValue: UInt32(NOTE_REVOKE))
    }
    
    public struct KEVFileMonitor: KernelEvent {
        var ret = kevent()
        var identifier: Int32
        var filter: Int32 = EVFILT_VNODE
        var flags: Int32 = 0
        var fflags: Int32 {
            return Int32(events.rawValue)
        }
        public var events: KEVFileEvents
        public var action: (KEVFileEvents) -> ()
    }
    
    public extension KEVFileMonitor {
        public var fd: Int32 {
            get {
                return identifier
            } set {
                identifier = newValue
            }
        }
        
        public init(path: String, flag: Int32 = O_RDWR, for events: KEVFileEvents, perform action: @escaping (KEVFileEvents) -> ()) {
            identifier = open(path, flag)
            self.events = events
            self.action = action
        }
        
        public init(fd: Int32, for events: KEVFileEvents, perform action: @escaping (KEVFileEvents) -> ()) {
            identifier = fd
            self.events = events
            self.action = action
        }
    }
    public struct KernelQueue {
        var kq = kqueue()
        
    }
#endif





