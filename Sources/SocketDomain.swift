
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
//  Created by yuuji on 6/2/16.
//  Copyright © 2016 yuuji. All rights reserved.
//

#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
    public enum SocketDomains: sa_family_t {
        case unspec     = 0
        case unix       = 1
        case inet       = 2
        case implink    = 3
        case pup        = 4
        case chaos      = 5
        case bs         = 6
        case iso        = 7
        case ecma       = 8
        case datakit    = 9
        case ccitt      = 10
        case sna        = 11
        case deCnet     = 12
        case dli        = 13
        case lat        = 14
        case hylink     = 15
        case appleTalk  = 16
        case route      = 17
        case link       = 18
        case pseudo_AF_XTP = 19
        case coip       = 20
        case cnt        = 21
        case pseudo_AF_RTIP = 22
        case ipx        = 23
        case sip        = 24
        case pseudo_AF_PIP = 25
        case ndrv       = 27
        case isdn       = 28
        case pseudo_AF_KEY = 29
        case inet6      = 30
        case natm       = 31
        case system     = 32
        case netBios    = 33
        case ppp        = 34
        case pseudo_AF_HDRCMPLT = 35
        case reserved_36 = 36
        case ieee80211  = 37
        case utun       = 38
        case max        = 40
    }
#elseif os(FreeBSD)
    public enum SocketDomains: UInt8 {
        case unspec     = 0
        case unix       = 1
        case inet       = 2
        case implink    = 3
        case pup        = 4
        case chaos      = 5
        case bs         = 6
        case iso        = 7
        case ecma       = 8
        case datakit    = 9
        case ccitt      = 10
        case sna        = 11
        case deCnet     = 12
        case dli        = 13
        case lat        = 14
        case hylink     = 15
        case appleTalk  = 16
        case route      = 17
        case link       = 18
        case pseudo_AF_XTP = 19
        case coip       = 20
        case cnt        = 21
        case pseudo_AF_RTIP = 22
        case ipx        = 23
        case sip        = 24
        case pseudo_AF_PIP = 25
        
        case isdn       = 26
        case pseudo_AF_KEY = 27
        case inet6      = 28
        case natm       = 29
        case atm        = 30
        case hdrcmplt   = 31
        case netgraph   = 32
        case slow       = 33
        case sluster    = 34
        case arp        = 35
        case bluetooth  = 36
        case ieee80211  = 37
        case inetsdp    = 40
        case inet6sdp   = 41
    }
#else
    
    public enum SocketDomains: sa_family_t {
        case unspec     = 0
        case unix       = 1
        case inet       = 2
        case ax25       = 3
        case ipx        = 4
        case appleTalk  = 5
        case netrom     = 6
        case bridge     = 7
        case atmpvc     = 8
        case x25        = 9
        case inet6      = 10
        case rose       = 11
        case DECnet     = 12
        case netbeui    = 13
        case security   = 14
        case key        = 15
        case netlink    = 16
        case link       = 17
        case ash        = 18
        case econet     = 19
        case atmsvc     = 20
        case rds        = 21
        case sna        = 22
        case irda       = 23
        case ppp0x      = 24
        case wanpipe    = 25
        case llc        = 26
        case ib         = 27
        case mpls       = 28
        case can        = 29
        case tipc       = 30
        case bluetooth  = 31
        case iucv       = 32
        case rxrpc      = 33
        case isdn       = 34
        case phonet     = 35
        case ieee802154 = 36
    }
    
#endif
