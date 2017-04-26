
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

public struct Group {
    
    public static var current = Group(gid: User.currentUser.gid)
    
    var group: _group

    var cGroup: group {
        return group.cGroup
    }
    
    public var gid: gid_t {
        return cGroup.gr_gid
    }
    
    public var name: String {
        return String(cString: cGroup.gr_name)
    }
    
    public var password: String {
        return String(cString: cGroup.gr_passwd)
    }
    
    public var members: [String] {
        var mem = [String]()
        var ptr = cGroup.gr_mem
        while (ptr != nil && ptr!.pointee != nil && ptr!.pointee!.numerialValue > 0) {
            let string = String(cString: ptr!.pointee!, encoding: .ascii)
            guard let str = string else {
                break
            }
            mem.append(str)
            ptr = ptr!.advanced(by: 1)
            
        }
        return mem
    }
    
    public init(gid: gid_t) {
        self.group = _group(gid: gid)
    }
    
    public init(name: String) {
        self.group = _group(name: name)
    }
}

extension Group {
    class _group {
        var cGroup: group = xlibc.group()
        
        var bufferptr: UnsafeMutablePointer<Int8>
        
        init(gid: gid_t) {
            bufferptr = UnsafeMutablePointer<Int8>
                .allocate(capacity: System.sizes.getgrp_r_bufsize)
            var ptr: UnsafeMutablePointer<group>? = nil
            getgrgid_r(gid, &self.cGroup,
                       bufferptr,
                       System.sizes.getgrp_r_bufsize,
                       &ptr)
        }
        
        init(name: String) {
            bufferptr = UnsafeMutablePointer<Int8>
                .allocate(capacity: System.sizes.getgrp_r_bufsize)
            var ptr: UnsafeMutablePointer<group>? = nil
            getgrnam_r(name, &self.cGroup,
                       bufferptr,
                       System.sizes.getgrp_r_bufsize,
                       &ptr)
        }
        
        deinit {
            bufferptr.deallocate(capacity: System.sizes.getgrp_r_bufsize)
        }
    }
}
