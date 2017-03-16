
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
//  Created by Yuji on 3/11/17.
//  Copyright © 2017 Yuji. All rights reserved.
//

public struct FileFlags: OptionSet {
    public typealias RawValue = Int32
    public var rawValue: Int32
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    /// If the nonblock flag is speecified and `init`
    /// would result in the proceess being blocked for some reason
    /// (e.g., waiting for carrier on a dialup line), `init` returns
    /// immediately. The descriptor remains in non-blocking mode
    /// for subsequent operations
    public static let nonblock = FileFlags(rawValue: O_NONBLOCK)
    
    /// Open a file with `append` set causes each write on the file
    /// to be appended to the end.
    public static let append = FileFlags(rawValue: O_APPEND)
    
    #if !os(Linux)
    /// Atomically obtain a shared lock
    public static let sharelock = FileFlags(rawValue: O_SHLOCK)
    
    /// Atomically obtain an exclusive lock
    public static let exclusivelock = FileFlags(rawValue: O_EXLOCK)
    #endif
    
    /// Do not follow symbolic links
    public static let nosymlink = FileFlags(rawValue: O_NOFOLLOW)
    
    /// Create file if it does not exist
    public static let create = FileFlags(rawValue: O_CREAT)
    
    /// If `zero` is specified and the file exists, the file is 
    /// truncated to zero length
    public static let zero = FileFlags(rawValue: O_TRUNC)
    
    /// The init will throw error if `create` is specified and the
    /// file already exists If `ensureCreation` is set and the last
    /// component of the pathname is a symbolic link, `open()` will
    /// fail even if the symbolic points to a non-existent name.
    public static let ensureCreation = FileFlags(rawValue: O_EXCL)
}

public struct File: FileDescriptorRepresentable {
    public var fileDescriptor: Int32
    public var path: String
    public lazy var status: FileStatus = {
        return try! FileStatus(fd: self.fileDescriptor)
    }()
    
    public init(path: String, access: AccessMode, flags: FileFlags) throws {
        self.path = path
        self.fileDescriptor = try throwsys("open") {
            return path.withCString {
                open($0, flags.rawValue, access.rawValue)
            }
        }
    }
    
    public func chmod(permission: PremissionMode) throws {
        _ = try throwsys("open") {
            fchmod(fileDescriptor, permission.rawValue)
        }
    }
    
    public func chown(user: uid_t, group: gid_t) throws {
        _ = try throwsys("open") {
            fchown(fileDescriptor, user, group)
        }
    }
    
    public func chown(user: User) throws {
        _ = try throwsys("open") {
            fchown(fileDescriptor, user.uid, user.gid)
        }
    }
    
    public func chown(user: User, group: Group) throws {
        _ = try throwsys("open") {
            fchown(fileDescriptor, user.uid, group.gid)
        }
    }
    
}
