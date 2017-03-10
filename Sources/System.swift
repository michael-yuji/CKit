
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
//  Created by Yuji on 7/16/16.
//
//

#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
public typealias sys_conf_arg_t = Int32
#elseif os(Linux)
public typealias sys_conf_arg_t = Int32
#endif

public typealias Sysconf = System

public struct System {
    
    public static let maximum = Maximum()
    public static let cpus = CPUs()
    public static let sizes = Sizes()
    
    public struct Maximum {
        public var hostname: Int {
            return sysconf(sys_conf_arg_t(_SC_HOST_NAME_MAX))
        }
        
        public var ttyname: Int {
            return sysconf(sys_conf_arg_t(_SC_TTY_NAME_MAX))
        }
        
        public var loginname: Int {
            return sysconf(sys_conf_arg_t(_SC_LOGIN_NAME_MAX))
        }
        
        public var fildescs: Int {
            return sysconf(sys_conf_arg_t(_SC_OPEN_MAX))
        }
        
        public var childProces: Int {
            return sysconf(sys_conf_arg_t(_SC_CHILD_MAX))
        }
        
        public var args: Int {
            return sysconf(sys_conf_arg_t(_SC_ARG_MAX))
        }
        
        public var pathname: Int {
            return Int(xlibc.PATH_MAX)
        }
    }
    
    public struct Sizes {
        public var page: Int {
            return sysconf(sys_conf_arg_t(_SC_PAGESIZE))
        }
        
        public var physicalPages: Int {
            return sysconf(sys_conf_arg_t(_SC_PHYS_PAGES))
        }
    }
    
    public struct CPUs {
        public var configuared: Int {
            return sysconf(sys_conf_arg_t(_SC_NPROCESSORS_CONF))
        }
        
        public var onlines: Int {
            return sysconf(sys_conf_arg_t(_SC_NPROCESSORS_ONLN))
        }
        
        public var clkTricksPerSec: Int {
            
            return sysconf(sys_conf_arg_t(_SC_CLK_TCK))
        }
    }
    
    @available(*, deprecated, message: "use System.cpus.configuared instead")
    public static var cpusConfigured: Int {
        return sysconf(sys_conf_arg_t(_SC_NPROCESSORS_CONF))
    }
    
    @available(*, deprecated, message: "use System.cpus.onlines instead")
    public static var cpusOnline: Int {
        return sysconf(sys_conf_arg_t(_SC_NPROCESSORS_ONLN))
    }
    
    @available(*, deprecated, message: "use System.cpus.clkTricksPerSec instead")
    public static var clockTricks: Int {
        return sysconf(sys_conf_arg_t(_SC_CLK_TCK))
    }

    @available(*, deprecated, message: "use System.sizes.page instead")
    public static var pagesize: Int {
        return sysconf(sys_conf_arg_t(_SC_PAGESIZE))
    }
    
    @available(*, deprecated, message: "se System.sizes.physicalPages instead")
    public static var  physicalPagesize: Int {
        return sysconf(sys_conf_arg_t(_SC_PHYS_PAGES))
    }

    @available(*, deprecated, message: "use System.maximum.hostname instead")
    public static var hostnameMaxLength: Int {
        return sysconf(sys_conf_arg_t(_SC_HOST_NAME_MAX))
    }

    @available(*, deprecated, message: "use System.maximum.loginname instead")
    public static var loginnameMaxLength: Int {
        return sysconf(sys_conf_arg_t(_SC_LOGIN_NAME_MAX))
    }

    @available(*, deprecated, message: "use System.maximum.ttyname instead")
    public static var ttynameMaxLength: Int {
        return sysconf(sys_conf_arg_t(_SC_TTY_NAME_MAX))
    }

    @available(*, deprecated, message: "use System.maximum.fildescs instead")
    public static var maxFilesCount: Int {
        return sysconf(sys_conf_arg_t(_SC_OPEN_MAX))
    }

    @available(*, deprecated, message: "use System.maximum.childProcess instead")
    public static var maxChildProcCount: Int {
        return sysconf(sys_conf_arg_t(_SC_CHILD_MAX))
    }

    @available(*, deprecated, message: "use System.maximum.args instead")
    public static var maxArgsCount: Int {
        return sysconf(sys_conf_arg_t(_SC_ARG_MAX))
    }
}
