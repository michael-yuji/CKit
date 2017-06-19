
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

public typealias PointerType = AnyPointer
public typealias MutablePointerType = AnyMutablePointer

public protocol AnyPointer
{
    var rawPointer: UnsafeRawPointer { get }
}

public protocol AnyMutablePointer : AnyPointer
{
    var mutableRawPointer: UnsafeMutableRawPointer { get }
}

public protocol AnyBufferPointer
{
    var rawBuffer: UnsafeRawBufferPointer { get }
}

public protocol AnyMutableBufferPointer : AnyBufferPointer, AnyMutablePointer
{
    var mutableRawBuffer: UnsafeMutableRawBufferPointer { get }
}

@inline(__always)
public func rawPointer<T>(of obj: inout T,
                    advancedBy count: Int = 0) -> UnsafeRawPointer
{
    let ghost: (UnsafePointer<T>) -> UnsafePointer<T> = {$0}
    return withUnsafePointer(to: &obj, {
        ghost($0)
    }).advanced(by: count).rawPointer
}

@inline(__always)
public func mutableRawPointer<T>(of obj: inout T,
                           advancedBy count: Int = 0) -> UnsafeMutableRawPointer
{
    let ghost: (UnsafeMutablePointer<T>) -> UnsafeMutablePointer<T> = {$0}
    return withUnsafeMutablePointer(to: &obj, {
        ghost($0)
    }).advanced(by: count).mutableRawPointer
}

@inline(__always)
public func pointer<T>(of obj: inout T,
                    advancedBy count: Int = 0) -> UnsafePointer<T>
{
    let ghost: (UnsafePointer<T>) -> UnsafePointer<T> = {$0}
    return withUnsafePointer(to: &obj, {ghost($0)}).advanced(by: count)
}

@inline(__always)
public func mutablePointer<T>(of obj: inout T,
                           advancedBy count: Int = 0) -> UnsafeMutablePointer<T>
{
    let ghost: (UnsafeMutablePointer<T>) -> UnsafeMutablePointer<T> = {$0}
    return withUnsafeMutablePointer(to: &obj, {
        ghost($0)
    }).advanced(by: count)
}

@inline(__always)
public func pointer<T, R>(of obj: inout T, as r: R.Type,
                    advancedBy count: Int = 0) -> UnsafePointer<R>
{
    let ghost: (UnsafePointer<T>) -> UnsafePointer<T> = {$0}
    return withUnsafePointer(to: &obj, {
        ghost($0)
    }).advanced(by: count).cast(to: r)
}

@inline(__always)
public func mutablePointer<T,R>(of obj: inout T, as r: R.Type,
                           advancedBy count: Int = 0) -> UnsafeMutablePointer<R>
{
    let ghost: (UnsafeMutablePointer<T>) -> UnsafeMutablePointer<T> = {$0}
    return withUnsafeMutablePointer(to: &obj, {
        ghost($0)
    }).advanced(by: count).cast(to: r)
}

@inline(__always)
func reinterept_cast<T, X>(from obj: inout T, to: X.Type) -> X
{
    var ret: X!
    withUnsafeMutableBytes(of: &ret) { dest -> () in
        withUnsafeBytes(of: &obj) {
            dest.copyContents(from: $0)
        }
    }
    
    return ret
}

@inline(__always)
func reinterept_cast<T, X>(from obj: T, to: X.Type) -> X
{
    var obj = obj
    var ret: X!
    
    withUnsafeMutableBytes(of: &ret) { dest -> () in
        withUnsafeBytes(of: &obj) {
            dest.copyContents(from: $0)
        }
    }
    
    return ret
}

public extension UnsafeMutablePointer
{
    @inline(__always)
    func cast<T>(to type: T.Type) -> UnsafeMutablePointer<T>
    {
        return UnsafeMutableRawPointer(self).assumingMemoryBound(to: type)
    }
}

public extension UnsafePointer
{
    @inline(__always)
    func cast<T>(to type: T.Type) -> UnsafePointer<T>
    {
        return UnsafeRawPointer(self).assumingMemoryBound(to: type)
    }
}

public extension UnsafeMutableRawPointer
{
    @inline(__always)
    func cast<T>(to type: T.Type) -> UnsafeMutablePointer<T>
    {
        return self.assumingMemoryBound(to: type)
    }
}

extension AnyPointer
{
    public var integerValue: Int
    {
        return numerialValue
    }
    
    public var numerialValue: Int
    {
        var s = self
        return pointer(of: &s).cast(to: Int.self).pointee
    }
}

extension Array: AnyPointer
{
    @inline(__always)
    private static func toPointer<T>(_ p: UnsafePointer<T>) -> UnsafePointer<T>
    {
        return p
    }

    public var rawPointer: UnsafeRawPointer
    {
        return Array.toPointer(self).rawPointer
    }
}

extension UnsafePointer: AnyPointer
{
    public var rawPointer: UnsafeRawPointer
    {
        return UnsafeRawPointer(self)
    }
}

extension UnsafeRawPointer: AnyPointer
{
    public var rawPointer: UnsafeRawPointer
    {
        return self
    }
}

extension UnsafeBufferPointer: AnyPointer, AnyBufferPointer
{
    public var rawPointer: UnsafeRawPointer
    {
        return self.baseAddress!.rawPointer
    }
    
    public var rawBuffer: UnsafeRawBufferPointer
    {
        return UnsafeRawBufferPointer(self)
    }
}

extension UnsafeRawBufferPointer: AnyPointer, AnyBufferPointer
{
    public var rawPointer: UnsafeRawPointer
    {
        return self.baseAddress!
    }
    
    public var rawBuffer: UnsafeRawBufferPointer
    {
        return self
    }
}

extension UnsafeMutablePointer: AnyMutablePointer
{
    public var mutableRawPointer: UnsafeMutableRawPointer
    {
        return UnsafeMutableRawPointer(self)
    }

    public var rawPointer: UnsafeRawPointer
    {
        return UnsafeRawPointer(self)
    }
}

extension UnsafeMutableRawPointer: AnyMutablePointer
{
    public var mutableRawPointer: UnsafeMutableRawPointer
    {
        return self
    }

    public var rawPointer: UnsafeRawPointer
    {
        return UnsafeRawPointer(self)
    }
}

extension UnsafeMutableBufferPointer: AnyMutablePointer, AnyMutableBufferPointer
{
    public var mutableRawPointer: UnsafeMutableRawPointer
    {
        return self.baseAddress!.mutableRawPointer
    }

    public var rawPointer: UnsafeRawPointer
    {
        return self.baseAddress!.rawPointer
    }
    
    public var rawBuffer: UnsafeRawBufferPointer
    {
        return UnsafeRawBufferPointer(self)
    }
    
    public var mutableRawBuffer: UnsafeMutableRawBufferPointer
    {
        return UnsafeMutableRawBufferPointer(self)
    }
}

extension UnsafeMutableRawBufferPointer: AnyPointer, AnyMutableBufferPointer
{
    public var rawPointer: UnsafeRawPointer
    {
        return UnsafeRawPointer(self.baseAddress!)
    }
    
    public var mutableRawPointer: UnsafeMutableRawPointer
    {
        return self.baseAddress!
    }
    
    public var mutableRawBuffer: UnsafeMutableRawBufferPointer
    {
        return self
    }
    
    public var rawBuffer: UnsafeRawBufferPointer
    {
        return UnsafeRawBufferPointer(self)
    }
}

extension OpaquePointer
{
    public var mutableRawPointer: UnsafeMutableRawPointer
    {
        return UnsafeMutableRawPointer(self)
    }
    
    public var rawPointer: UnsafeRawPointer
    {
        return UnsafeRawPointer(self)
    }
}

@inline(__always)
private func roundedBytesCount<T>(_ raw: Int, _: T.Type) -> Int
{
    return raw - (raw % MemoryLayout<T>.size)
}

extension AnyMutableBufferPointer
{
    @discardableResult
    public func copyContents<T>(from buf: UnsafeMutableBufferPointer<T>) -> Int
    {
        let nbytes = min(roundedBytesCount(self.mutableRawBuffer.count, T.self),
                         roundedBytesCount(buf.rawBuffer.count, T.self))
        
        self.mutableRawBuffer.copyBytes(
            from: UnsafeRawBufferPointer(start: buf.rawBuffer.baseAddress!,
                                         count: nbytes)
        )
        return nbytes/MemoryLayout<T>.size
    }
    
    @discardableResult
    public func copyContents<T>(from buffer: UnsafeBufferPointer<T>) -> Int
    {
        let nbytes = min(roundedBytesCount(self.mutableRawBuffer.count, T.self),
                         roundedBytesCount(buffer.rawBuffer.count, T.self))
        
        self.mutableRawBuffer.copyBytes(
            from: UnsafeRawBufferPointer(start: buffer.rawBuffer.baseAddress!,
                                         count: nbytes)
        )
        return nbytes/MemoryLayout<T>.size
    }
    
}

extension UnsafeMutableRawBufferPointer {
    
    /// Copy bytes from other buffer. If the other buffer is bigger than the
    /// current buffer, only the bytes current buffer can hold will be copied
    ///
    /// - Parameter source: the source buffer to copy from
    /// - Returns: number of bytes copied
    @discardableResult
    public func copyContents(from source: UnsafeRawBufferPointer) -> Int
    {
        let nbytes = Swift.min(self.count, source.count)
        
        self.mutableRawBuffer.copyBytes(
            from: UnsafeRawBufferPointer(start: source.rawBuffer.baseAddress!,
                                         count: nbytes)
        )
        return nbytes
    }
    
    /// Copy bytes from other buffer. If the other buffer is bigger than the
    /// current buffer, only the bytes current buffer can hold will be copied
    ///
    /// - Parameter source: the source buffer to copy from
    /// - Returns: number of bytes copied
    @discardableResult
    public func copyContents(from source: UnsafeMutableRawBufferPointer) -> Int
    {
        let nbytes = Swift.min(self.mutableRawBuffer.count,
                               source.rawBuffer.count)
        
        self.mutableRawBuffer.copyBytes(
            from: UnsafeRawBufferPointer(start: source.rawBuffer.baseAddress!,
                                         count: nbytes)
        )
        return nbytes
    }
}

extension UnsafeMutableBufferPointer
{
    /// Copy bytes from other buffer. If the other buffer is bigger than the
    /// current buffer, only the bytes current buffer can hold will be copied
    ///
    /// - Parameter source: the source buffer to copy from
    /// - Returns: number of elements copied
    @discardableResult
    public func copyContents(from source: UnsafeRawBufferPointer) -> Int
    {
        let nbytes = Swift.min(roundedBytesCount(self.mutableRawBuffer.count,
                                                 Element.self),
                               roundedBytesCount(source.rawBuffer.count,
                                                 Element.self))
        
        self.mutableRawBuffer.copyBytes(
            from: UnsafeRawBufferPointer(start: source.rawBuffer.baseAddress!,
                                         count: nbytes)
        )
        return nbytes/MemoryLayout<Element>.size
    }
    
    /// Copy bytes from other buffer. If the other buffer is bigger than the
    /// current buffer, only the bytes current buffer can hold will be copied
    ///
    /// - Parameter source: the source buffer to copy from
    /// - Returns: number of elements copied
    @discardableResult
    public func copyContents(from source: UnsafeMutableRawBufferPointer) -> Int
    {
        let nbytes = Swift.min(roundedBytesCount(self.mutableRawBuffer.count,
                                                 Element.self),
                               roundedBytesCount(source.rawBuffer.count,
                                                 Element.self))
        
        self.mutableRawBuffer.copyBytes(
            from: UnsafeRawBufferPointer(start: source.rawBuffer.baseAddress!,
                                         count: nbytes)
        )
        return nbytes/MemoryLayout<Element>.size
    }
}
