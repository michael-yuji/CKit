//
//  FileStatus.swift
//  CKit
//
//  Created by yuuji on 8/26/16.
//
//

import Foundation

public enum FileStatusError: Error {
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
public struct FileStatus {
    public var stat_: UnsafeMutablePointer<stat>!
}

public extension FileStatus {
    public var deviceId: dev_t {
        return stat_.pointee.st_dev
    }
    public var inodeNumber: ino_t {
        return stat_.pointee.st_ino
    }
    public var mode: mode_t {
        return stat_.pointee.st_mode
    }
    public var hardlinkCount: Int {
        return Int(stat_.pointee.st_nlink)
    }
    public var owner: User {
        return User(uid: stat_.pointee.st_uid)
    }
    public var deviceId_s: dev_t {
        return stat_.pointee.st_rdev
    }
    public var size: size_t {
        return size_t(stat_.pointee.st_size)
    }
    public var blockSize: Int {
        return Int(stat_.pointee.st_blksize)
    }
    public var blocksCount: Int {
        return Int(stat_.pointee.st_blocks)
    }
    public var lastAccessDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(stat_.pointee.st_atimespec.tv_sec))
    }
    public var modificationDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(stat_.pointee.st_mtimespec.tv_sec))
    }
    public var lastStatusChange: Date {
        return Date(timeIntervalSince1970: TimeInterval(stat_.pointee.st_ctimespec.tv_sec))
    }
}

public extension FileStatus {
    public var isBlock: Bool {
        return (self.mode & S_IFMT) == S_IFBLK
    }
    public var isChar: Bool {
        return (self.mode & S_IFMT) == S_IFCHR
    }
    public var isDir: Bool {
        return (self.mode & S_IFMT) == S_IFDIR
    }
    public var isFifo: Bool {
        return (self.mode & S_IFMT) == S_IFIFO
    }
    public var isSocket: Bool {
        return (self.mode & S_IFMT) == S_IFIFO
    }
    public var isRegularFile: Bool {
        return (self.mode & S_IFMT) == S_IFSOCK
    }
    public var isSymbolicLink: Bool {
        return (self.mode & S_IFMT) == S_IFLNK
    }
    #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS) || os(FreeBSD)
    public var isWhiteOut: Bool {
        return (self.mode & S_IFMT) == S_IFWHT
    }
    #endif
}

public extension FileStatus {
    public init(path: String) throws {
        try verify(err: stat(path, stat_))
    }
    
    public init(fd: Int32) throws {
        try verify(err: fstat(fd, stat_))
    }
    
    internal func verify(err: Int32) throws {
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
        default:
            break
        }
    }
}
