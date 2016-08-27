//
//  User.swift
//  CKit
//
//  Created by yuuji on 8/26/16.
//
//

import Foundation

public struct User {
    
    public static var currentUser = User(uid: getuid())
    
    public var pw: UnsafeMutablePointer<passwd>
    
    public var name: String {
        return String(cString: pw.pointee.pw_name)
    }
    
    public var passwd: String {
        return String(cString: pw.pointee.pw_passwd)
    }
    
    public var home: String {
        return String(cString: pw.pointee.pw_dir)
    }
    
    public var shell: String {
        return String(cString: pw.pointee.pw_shell)
    }
    
    public var expiration: Date {
        return Date(timeIntervalSince1970: TimeInterval(pw.pointee.pw_expire))
    }
    
    public var pwdChangeTime: Date {
        return Date(timeIntervalSince1970: TimeInterval(pw.pointee.pw_change))
    }
    
    public var `class`: String {
        return String(cString: pw.pointee.pw_class)
    }
    
}

public extension User {
    public init(uid: uid_t) {
        self.pw = getpwuid(uid)
    }
    
    public init(name: String) {
        self.pw = getpwnam(name)
    }
}
