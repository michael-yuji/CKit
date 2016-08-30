
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
//  Created by Yuji on 6/3/16.
//  Copyright © 2016 yuuji. All rights reserved.
//

import Foundation

@inline(__always)
public func pointer<T>(of obj: inout T, advancedBy distance: Int = 0) -> UnsafePointer<T> {
    let ghost: (UnsafePointer<T>) -> UnsafePointer<T> = {$0}
    return withUnsafePointer(to: &obj, {ghost($0)}).advanced(by: distance)
}

@inline(__always)
public func mutablePointer<T>(of obj: inout T, advancedBy distance: Int = 0) -> UnsafeMutablePointer<T> {
    let ghost: (UnsafeMutablePointer<T>) -> UnsafeMutablePointer<T> = {$0}
    return withUnsafeMutablePointer(to: &obj, {ghost($0)}).advanced(by: distance)
}

public struct ConvenientPointer<T> {
    public var pointer: UnsafeMutablePointer<T>
    public var size: size_t
}

public extension UnsafeMutablePointer {
    @inline(__always)
    func cast<T>(to type: T.Type, NItems count: Int = 1) -> UnsafeMutablePointer<T> {
        return UnsafeMutableRawPointer(self).assumingMemoryBound(to: type)
    }
}

public extension UnsafePointer {
    @inline(__always)
    func cast<T>(to type: T.Type) -> UnsafePointer<T> {
        return UnsafeRawPointer(self).assumingMemoryBound(to: type)
    }
}

public extension UnsafeMutableRawPointer {
    @inline(__always)
    func cast<T>(to type: T.Type) -> UnsafeMutablePointer<T> {
        return self.assumingMemoryBound(to: type)
    }
}
