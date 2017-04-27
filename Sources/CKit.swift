
//  Copyright (c) 2017, Yuji
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
//  Created by Yuji on 3/6/17.
//  Copyright © 2017 Yuji. All rights reserved.
//

@_exported import xlibc

@inline(__always)
public func memcpy(_ dst: MutablePointer, _ src: Pointer, _ bytes: Int) {
    dst.mutableRawPointer.copyBytes(from: src.rawPointer, count: bytes)
}

public protocol IntegerValueConvertiable {
    var integerValue: Int { get }
}

extension Int : IntegerValueConvertiable {
    public var integerValue: Int {
        return self
    }
}

extension UInt : IntegerValueConvertiable {
    public var integerValue: Int {
        return Int(self)
    }
}

extension Int32 : IntegerValueConvertiable {
    public var integerValue: Int {
        return Int(self)
    }
}

extension UInt32 : IntegerValueConvertiable {
    public var integerValue: Int {
        return Int(self)
    }
}

extension Int16 : IntegerValueConvertiable {
    public var integerValue: Int {
        return Int(self)
    }
}

extension UInt16 : IntegerValueConvertiable {
    public var integerValue: Int {
        return Int(self)
    }
}

extension Int64 : IntegerValueConvertiable {
    public var integerValue: Int {
        return Int(self)
    }
}

extension UInt64 : IntegerValueConvertiable {
    public var integerValue: Int {
        return Int(self)
    }
}
