
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
//  Created by Yuji on 3/12/17.
//  Copyright © 2017 Yuji. All rights reserved.
//

public struct Group
{
    /// the current group of the current user we're acting upon
    public static var current = Group(gid: User.currentUser.gid)
    
    /// the underlying group class
    var group: _group

    /// get the c group struct
    var cGroup: group {
        return group.cGroup
    }
    
    /// get the group id
    public var gid: gid_t {
        return cGroup.gr_gid
    }
    
    /// get the name of the group
    public var name: String {
        return String(cString: cGroup.gr_name)
    }
    
    /// the encrypted password
    public var password: String {
        return String(cString: cGroup.gr_passwd)
    }
    
    /// members of the group
    public var members: [String] {
        var mem = [String]()
        var ptr = cGroup.gr_mem
        while (ptr != nil && ptr!.pointee != nil && ptr!.pointee!.numerialValue > 0) {
            let string = String(cString: ptr!.pointee!)
            mem.append(string)
            ptr = ptr!.advanced(by: 1)
            
        }
        return mem
    }
    
    
    /// Initialize the struct with group id
    ///
    /// - Parameter gid: The group id
    public init(gid: gid_t) {
        self.group = _group(gid: gid)
    }

    /// Initialize the struct with group name
    ///
    /// - Parameter name: The group name
    public init(name: String) {
        self.group = _group(name: name)
    }
}

extension Group
{
    /// The underly group class
    class _group
    {
        /// The c group struct
        var cGroup: group = xlibc.group()
        
        /// The buffer to store the group informations
        var bufferptr: UnsafeMutablePointer<Int8>
        
        /// Initialize with group id
        init(gid: gid_t)
        {
            bufferptr = UnsafeMutablePointer<Int8>
                .allocate(capacity: System.sizes.getgrp_r_bufsize)
            
            var ptr: UnsafeMutablePointer<group>? = nil
            
            getgrgid_r(gid, &self.cGroup, bufferptr,
                       System.sizes.getgrp_r_bufsize, &ptr)
        }
        
        /// Initialize with group name
        init(name: String)
        {
            bufferptr = UnsafeMutablePointer<Int8>
                .allocate(capacity: System.sizes.getgrp_r_bufsize)

            var ptr: UnsafeMutablePointer<group>? = nil

            getgrnam_r(name, &self.cGroup, bufferptr,
                       System.sizes.getgrp_r_bufsize, &ptr)
        }
        
        deinit
        {
            bufferptr.deallocate(capacity: System.sizes.getgrp_r_bufsize)
        }
    }
}
