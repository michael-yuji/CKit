//
//  sys.swift
//  CKit
//
//  Created by Yuji on 7/16/16.
//
//

import Foundation

public struct Sysconf {
    
    public static var pagesize: Int {
        return sysconf(_SC_PAGESIZE)
    }
    
    public static var hostnameMaxLength: Int {
        return sysconf(_SC_HOST_NAME_MAX)
    }
    
    public static var loginnameMaxLength: Int {
        return sysconf(_SC_LOGIN_NAME_MAX)
    }
    
    public static var ttynameMaxLength: Int {
        return sysconf(_SC_TTY_NAME_MAX)
    }
    
    public static var maxFilesCount: Int {
        return sysconf(_SC_OPEN_MAX)
    }
    
    public static var maxChildProcCount: Int {
        return sysconf(_SC_CHILD_MAX)
    }
    
    public static var maxArgsCount: Int {
        return sysconf(_SC_ARG_MAX)
    }
    
    public static var  physicalPagesize: Int {
        return sysconf(_SC_PHYS_PAGES)
    }
    
    public static var cpusConfigured: Int {
        return sysconf(_SC_NPROCESSORS_CONF)
    }
    
    public static var cpusOnline: Int {
        return sysconf(_SC_NPROCESSORS_ONLN)
    }
    
    public static var clockTricks: Int {
        return sysconf(_SC_CLK_TCK)
    }
}
