
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
//  Created by yuuji on 3/27/17.
//

#if os(Linux)
// Have to use a custom sockaddr_storage here,
// The default sockaddr_storage in Linux SwiftGlibc
// "hide" the bytes between ss_family and __ss_align
// in some implementation of the Linux Kernel
// in that case, those "hidden" bytes are not copied
// when the sockaddr_storage copied to the stack.
// In those cases, 6 bytes will be missing when
// use the sockaddr_storage struct as sockaddr_un.
// which causes the socket bind to a empty string path.
public struct _sockaddr_storage
{
    public var ss_family: sa_family_t // 2 bytes
    // 126 bytes
    public var __ss_pad1:
    (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8)
    
    public init()
    {
        self.ss_family = 0
        self.__ss_pad1 =
            (
                0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                0,0,0,0,0,0,0,0,0,0,0,0,0,0
        )
    }
}
    
#else
public typealias _sockaddr_storage = xlibc.sockaddr_storage
#endif
//

extension sockaddr
{
    #if os(Linux)
    public var sa_len: UInt8
    {
        return UInt8(MemoryLayout<sockaddr_in6>.size)
    }
    #endif
}

#if os(Linux)
func get_socklen_by_family(_ family: Int32) -> UInt8
{
    switch family {
    case AF_INET:
        return UInt8(MemoryLayout<sockaddr_in>.size)
        
    case AF_INET6:
        return UInt8(MemoryLayout<sockaddr_in6>.size)
        
    case AF_UNIX:
        return UInt8(MemoryLayout<sockaddr_un>.size)
        
    case AF_LINK:
        return UInt8(MemoryLayout<sockaddr_dl>.size)

    default:
        return UInt8(MemoryLayout<sockaddr>.size)
    }
}
#endif

extension _sockaddr_storage
{
    #if os(Linux)
    public var ss_len: UInt8
    {
        return get_socklen_by_family(Int32(self.ss_family))
    }
    #endif
}

extension sockaddr_in
{
    init(port: in_port_t, addr: in_addr = in_addr(s_addr: 0))
    {
        #if os(Linux)
            self = sockaddr_in(sin_family: sa_family_t(AF_INET),
                               sin_port: port.bigEndian,
                               sin_addr: in_addr(s_addr: 0),
                               sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        #else
            self = sockaddr_in(sin_len: UInt8(MemoryLayout<sockaddr_in>.size),
                               sin_family: sa_family_t(AF_INET),
                               sin_port: port.bigEndian,
                               sin_addr: in_addr(s_addr:0),
                               sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        #endif
    }
    
    #if os(Linux)
    public var sin_len: UInt8
    {
        return UInt8(MemoryLayout<sockaddr_in>.size)
    }
    #endif
}

extension sockaddr_in6
{
    init(port: in_port_t, addr: in6_addr = in6addr_any)
    {
        #if os(Linux)
            self = sockaddr_in6(sin6_family: sa_family_t(AF_INET6),
                                sin6_port: port.bigEndian,
                                sin6_flowinfo: 0,
                                sin6_addr: addr,
                                sin6_scope_id: 0)
        #else
            self = sockaddr_in6(sin6_len: UInt8(MemoryLayout<sockaddr_in6>.size),
                                sin6_family: sa_family_t(AF_INET6),
                                sin6_port: port.bigEndian,
                                sin6_flowinfo: 0,
                                sin6_addr: addr,
                                sin6_scope_id: 0)
        #endif
    }
    
    #if os(Linux)
    public var sin6_len: UInt8
    {
        return UInt8(MemoryLayout<sockaddr_in6>.size)
    }
    #endif
}



