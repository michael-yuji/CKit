
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

public struct User
{
  private static var __cur_usr: User?
  private static var __cur_eusr: User?

  var usr: _usr

  /// Who own this process
  public static var currentUser: User
  {
    get {
      if __cur_usr == nil || __cur_usr!.uid != getuid() {
        __cur_usr = User(uid: getuid())
      }
      return __cur_usr!
    }

    set {
      if newValue.uid != currentUser.uid
      {
        __cur_usr = newValue
        setuid(newValue.uid)
      }
    }
  }

  /// On whose behave this process is acting
  public static var currentEffectiveUser: User
  {
    get {
      if __cur_eusr == nil || __cur_eusr!.uid != geteuid()
      {
        __cur_eusr = User(uid: geteuid())
      }
      return __cur_eusr!
    }

    set {
      if newValue.uid != currentEffectiveUser.uid
      {
        __cur_usr = newValue
        seteuid(newValue.uid)
      }
    }
  }


  /// The underlying passwd struct
  public var pw: passwd
  {
    return usr.pw
  }

  public init(uid: uid_t)
  {
    self.usr = _usr(uid: uid)
  }

  public init(name: String)
  {
    self.usr = _usr(name: name)
  }

  @available(*, unavailable, message: "Deprecated since it's too easy to misuse")
  public func perform<R>(action: () throws -> R) throws -> R
  {
    let cur_uid = geteuid()

    if seteuid(uid) == -1 {
      throw SystemError.last("geteuid")
    }

    do {
      let r = try action()
      seteuid(cur_uid)
      return r
    }

    catch {
      seteuid(cur_uid)
      throw error
    }

  }
}

extension User
{
  /// user uid
  public var uid: uid_t
  {
    return pw.pw_uid
  }

  /// user gid
  public var gid: gid_t
  {
    return pw.pw_gid
  }

  /// user name
  public var name: String
  {
    return String(cString: pw.pw_name)
  }

  /// The encrypted password
  public var passwd: String
  {
    return String(cString: pw.pw_passwd)
  }

  /// The home directory
  public var home: String
  {
    return String(cString: pw.pw_dir)
  }

  /// The default shell
  public var shell: String
  {
    return String(cString: pw.pw_shell)
  }

  #if os(FreeBSD) || os(OSX) || os(iOS) || os(watchOS) || os(tvOS)

  public var expiration: time_t
  {
    return pw.pw_expire
  }

  public var pwdChangeTime: time_t
  {
    return pw.pw_change
  }

  public var `class`: String
  {
    return String(cString: pw.pw_class)
  }
  #endif
}

extension User
{
  final class _usr
  {
    var pw: passwd = xlibc.passwd()

    var bufferptr: UnsafeMutablePointer<Int8>

    init(uid: uid_t)
    {
      bufferptr = UnsafeMutablePointer<Int8>
        .allocate(capacity: System.sizes.getpwd_r_bufsize)

      var ptr: UnsafeMutablePointer<passwd>? = nil

      getpwuid_r(uid, &self.pw, bufferptr,
             System.sizes.getpwd_r_bufsize, &ptr)
    }

    init(name: String)
    {
      bufferptr = UnsafeMutablePointer<Int8>
        .allocate(capacity: System.sizes.getpwd_r_bufsize)

      var ptr: UnsafeMutablePointer<passwd>? = nil

      getpwnam_r(name, &self.pw, bufferptr,
             System.sizes.getpwd_r_bufsize, &ptr)
    }

    deinit {
      bufferptr.deinitialize(count: System.sizes.getgrp_r_bufsize)
      bufferptr.deallocate()
      //bufferptr.deallocate(capacity: System.sizes.getpwd_r_bufsize)
    }
  }
}
