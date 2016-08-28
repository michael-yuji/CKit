
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

import Foundation

public struct POSIXFileTypes : RawRepresentable, CustomStringConvertible {
    public var rawValue: Int32
    public static let unknown = POSIXFileTypes(rawValue: DT_UNKNOWN)
    public static let namedPipe = POSIXFileTypes(rawValue: DT_FIFO)
    public static let characterDevice = POSIXFileTypes(rawValue: DT_CHR)
    public static let directory = POSIXFileTypes(rawValue: DT_DIR)
    public static let blockDevice = POSIXFileTypes(rawValue: DT_BLK)
    public static let regular = POSIXFileTypes(rawValue: DT_REG)
    public static let symbolicLink = POSIXFileTypes(rawValue: DT_LNK)
    public static let socket = POSIXFileTypes(rawValue: DT_SOCK)
    #if os(OSX) || os(FreeBSD)
    public static let whiteOut = POSIXFileTypes(rawValue: DT_WHT)
    #endif
    
    public var description: String {
        #if os(OSX) || os(FreeBSD)
            switch self.rawValue {
            case POSIXFileTypes.unknown.rawValue: return "unknown"
            case POSIXFileTypes.namedPipe.rawValue: return "namedPipe"
            case POSIXFileTypes.characterDevice.rawValue: return "chracterDevice"
            case POSIXFileTypes.directory.rawValue: return "directory"
            case POSIXFileTypes.blockDevice.rawValue: return "blockDevice"
            case POSIXFileTypes.regular.rawValue: return "regular"
            case POSIXFileTypes.symbolicLink.rawValue: return "softlink"
            case POSIXFileTypes.socket.rawValue: return "socket"
            case POSIXFileTypes.whiteOut.rawValue: return "whiteout"
            default: return "Invalid val"
            }
        #else
            
            switch self.rawValue {
            case POSIXFileTypes.unknown.rawValue: return "unknown"
            case POSIXFileTypes.namedPipe.rawValue: return "namedPipe"
            case POSIXFileTypes.characterDevice.rawValue: return "chracterDevice"
            case POSIXFileTypes.directory.rawValue: return "directory"
            case POSIXFileTypes.blockDevice.rawValue: return "blockDevice"
            case POSIXFileTypes.regular.rawValue: return "regular"
            case POSIXFileTypes.symbolicLink.rawValue: return "softlink"
            case POSIXFileTypes.socket.rawValue: return "socket"
            default: return "Invalid val"
            }
        #endif
    }
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
}

public struct Dirent: CustomStringConvertible {
    public var name: String
    public var ino: ino_t
    public var size: Int
    public var type: POSIXFileTypes
    
    public init(d: dirent) {
        var dirent = d
        self.name = String(cString: pointer(of: &(dirent.d_name)).cast(to: CChar.self))
        //        self.name = String(cString: pointer(of: &(dirent.d_name)).cast(to: CChar.self, NItems: Int(MAXNAMLEN + 1)))
        self.size = Int(dirent.d_reclen)
        self.type = POSIXFileTypes(rawValue: Int32(dirent.d_type))
        self.ino = dirent.d_ino
    }
    
    public var description: String {
        get {
            return String.alignedText( strings: name, "\(ino)", "\(size)", "\(type)", spaces: [25, 10, 7, 15])
        }
    }
}

public func files(at path: String) -> [Dirent] {
    guard let dfd = opendir(path.cString(using: .utf8)!) else {return []}
    defer {
        closedir(dfd)
    }
    
    var dirents = [Dirent]()
    var dir: dirent = dirent()
    var resloved: UnsafeMutablePointer<dirent>? = nil
    
    repeat {
        if readdir_r(dfd, &dir, &resloved) != 0 {
            break
        }
        
        if resloved == nil {
            break
        }

        dirents.append(Dirent(d: resloved!.pointee))
        
    } while (resloved != nil)
    
    return dirents
}

public func findFile_r(atDirPath path: String, file: String) -> Dirent? {
    guard let dfd = opendir(path.cString(using: .utf8)!) else {return nil}
    var dir: dirent = dirent()
    var result: UnsafeMutablePointer<dirent>? = nil
    
    
    repeat {
        if readdir_r(dfd, &dir, &result) != 0 {break}
        
        if result == nil { break }
        
        if Dirent(d: result!.pointee).name == file {
            closedir(dfd)
            return Dirent(d: result!.pointee)
        }
        
    } while (result != nil)
    closedir(dfd)
    return nil
}
