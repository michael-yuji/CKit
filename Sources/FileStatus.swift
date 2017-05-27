
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

//import struct Foundation.Date
//import typealias Foundation.TimeInterval

public typealias cstat = xlibc.stat

public enum FileStatusError: Error
{
    case searchPermissionDenied
    case badFileDescriptor
    case badAddress
    case tooManySymbolicLinksEncountered
    case pathIs2Long
    case componentOfPathDoesNotExist
    case outOfMemory
    case componentOfPathIsNotDirectory
    case overflow
}

public struct FileStatus
{
    public var stat_ = cstat()
}

public extension FileStatus
{
    public var deviceId: dev_t
    {
        return stat_.st_dev
    }

    public var inodeNumber: ino_t
    {
        return stat_.st_ino
    }

    public var mode: mode_t
    {
        return stat_.st_mode
    }

    public var hardlinkCount: Int
    {
        return Int(stat_.st_nlink)
    }

    public var owner: User
    {
        return User(uid: stat_.st_uid)
    }

    public var deviceId_s: dev_t
    {
        return stat_.st_rdev
    }

    public var size: size_t
    {
        return size_t(stat_.st_size)
    }

    public var blockSize: Int
    {
        return Int(stat_.st_blksize)
    }

    public var blocksCount: Int
    {
        return Int(stat_.st_blocks)
    }

    public var lastAccessDate: time_t
    {
        #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
        return stat_.st_atimespec.tv_sec
        #elseif os(FreeBSD) || os(Linux)
        return stat_.st_atim.tv_sec
        #endif
    }

    public var modificationDate: time_t
    {
        #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
            return stat_.st_mtimespec.tv_sec
        #elseif os(FreeBSD) || os(Linux)
            return stat_.st_mtim.tv_sec
        #endif
    }

    public var lastStatusChange: time_t
    {
        #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
            return stat_.st_ctimespec.tv_sec
        #elseif os(FreeBSD) || os(Linux)
            return stat_.st_ctim.tv_sec
        #endif
    }
}

public func ==(lhs: stat, rhs: stat) -> Bool
{
    var l = lhs
    var r = rhs
    return memcmp(pointer(of: &l), pointer(of: &r), MemoryLayout<stat>.size) == 0
}

public func ==(lhs: FileStatus, rhs: FileStatus) -> Bool
{
    return lhs.stat_ == rhs.stat_
}

public extension FileStatus
{
    public var isBlock: Bool
    {
        return (self.mode & S_IFMT) == S_IFBLK
    }

    public var isChar: Bool
    {
        return (self.mode & S_IFMT) == S_IFCHR
    }

    public var isDir: Bool
    {
        return (self.mode & S_IFMT) == S_IFDIR
    }

    public var isFifo: Bool
    {
        return (self.mode & S_IFMT) == S_IFIFO
    }

    public var isSocket: Bool
    {
        return (self.mode & S_IFMT) == S_IFIFO
    }

    public var isRegularFile: Bool
    {
        return (self.mode & S_IFMT) == S_IFSOCK
    }

    public var isSymbolicLink: Bool
    {
        return (self.mode & S_IFMT) == S_IFLNK
    }

    #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS) || os(FreeBSD)
    public var isWhiteOut: Bool
    {
        return (self.mode & S_IFMT) == S_IFWHT
    }
    #endif
}

public extension FileStatus
{
    public init(path: String) throws
    {
        try verify(err: stat(path, &stat_))
    }

    public init(fd: Int32) throws
    {
        try verify(err: fstat(fd, &stat_))
    }

    internal func verify(err: Int32) throws
    {
        switch err {
        case EACCES:
            throw FileStatusError.searchPermissionDenied
        case EBADF:
            throw FileStatusError.badFileDescriptor
        case EFAULT:
            throw FileStatusError.badAddress
        case ELOOP:
            throw FileStatusError.tooManySymbolicLinksEncountered
        case ENAMETOOLONG:
            throw FileStatusError.pathIs2Long
        case ENOENT:
            throw FileStatusError.componentOfPathDoesNotExist
        case ENOMEM:
            throw FileStatusError.outOfMemory
        case ENOTDIR:
            throw FileStatusError.componentOfPathIsNotDirectory
        case EOVERFLOW:
            throw FileStatusError.overflow
        case -1:
            throw SystemError.last("stat")
        default:
            break
        }
    }
}
