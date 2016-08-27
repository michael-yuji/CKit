//
//  Kevent.swift
//  CKit
//
//  Created by yuuji on 8/26/16.
//
//

import Foundation

#if os(FreeBSD) || os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
@inline(__always)
public func EV_SET(kevent _ke: inout kevent, ident: Int32, filter: Int32, flags: Int32, fflags: Int32, data: Int32, udata: UnsafeMutablePointer<Void>!) {
    let event: UnsafeMutablePointer<kevent> = mutablePointer(of: &_ke)
    event.pointee.ident = UInt(ident)
    event.pointee.filter = Int16(filter)
    event.pointee.flags = UInt16(flags)
    event.pointee.fflags = UInt32(fflags)
    event.pointee.data = Int(data)
    event.pointee.udata = udata
}
#endif
