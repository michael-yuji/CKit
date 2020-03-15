
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

#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
public typealias DirentRawType = Int32
#elseif os(Linux)
public typealias DirentRawType = Int
#endif

public typealias POSIXFileTypes = FileTypes

public struct FileTypes : RawRepresentable, CustomStringConvertible
{
  public var rawValue: DirentRawType

  public static let unknown = FileTypes(rawValue: DT_UNKNOWN)

  public static let namedPipe = FileTypes(rawValue: DT_FIFO)

  public static let streamDevice = FileTypes(rawValue: DT_CHR)

  public static let directory = FileTypes(rawValue: DT_DIR)

  public static let blockDevice = FileTypes(rawValue: DT_BLK)

  public static let regular = FileTypes(rawValue: DT_REG)

  public static let symbolicLink = FileTypes(rawValue: DT_LNK)

  public static let socket = FileTypes(rawValue: DT_SOCK)

  #if os(OSX) || os(FreeBSD)
  public static let whiteOut = FileTypes(rawValue: DT_WHT)
  #endif

  public var description: String {
    switch self.rawValue {
      case FileTypes.unknown.rawValue:
        return "unknown"
      case FileTypes.namedPipe.rawValue:
        return "named pipe"
      case FileTypes.streamDevice.rawValue:
        return "stream device"
      case FileTypes.directory.rawValue:
        return "directory"
      case FileTypes.blockDevice.rawValue:
        return "block device"
      case FileTypes.regular.rawValue:
        return "regular"
      case FileTypes.symbolicLink.rawValue:
        return "softlink"
      case FileTypes.socket.rawValue:
        return "socket"
      default:
        #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS) || os(FreeBSD)
        if self.rawValue == FileTypes.whiteOut.rawValue {
          return "whiteout"
        }
        #endif
        return "Invalid val"
      }

  }

  public init(rawValue: DirentRawType)
  {
    self.rawValue = rawValue
  }
}

public typealias Dirent = DirectoryEntry

public struct Directory {

  public fileprivate(set) var path: String

  public fileprivate(set) var contents = [Dirent]()

  public init(path: String) throws
  {
    self.path = path

    guard let dfd = path.withCString({
      opendir($0)
    }) else {
      throw StaticSystemError.last("opendir")
    }

    var dir: dirent = dirent()

    var resloved: UnsafeMutablePointer<dirent>? = nil

    #if os(Linux)
    let path = path.characters[path.endIndex] == "/" ? path : (path + "/")
    #else
    let path = path.hasSuffix("/") ? path : (path + "/")
    #endif

    repeat
    {
      if readdir_r(dfd, &dir, &resloved) != 0 {
        break
      }

      if resloved == nil {
        break
      }

      contents.append(Dirent(basePath: path, dirent: resloved!.pointee))

    } while (resloved != nil)

    closedir(dfd)
  }
}

public struct DirectoryEntry : CustomStringConvertible
{
  /// where is this item located
  public fileprivate(set) var basePath: String
  /// the name of the entry
  public fileprivate(set) var name: String
  /// file number of this entry
  public fileprivate(set) var ino: ino_t
  /// length of the record
  public fileprivate(set) var size: Int
  /// file type
  public fileprivate(set) var type: FileTypes

  /// the full path of the entry
  public var fullpath: String {
    return basePath + name
  }

  public init(basePath: String, dirent d: dirent)
  {
    var dirent = d
    self.basePath = basePath
    self.name = String(cString: pointer(of: &(dirent.d_name),
                      as: CChar.self))
    self.size = Int(dirent.d_reclen)
    self.type = FileTypes(rawValue: DirentRawType(dirent.d_type))
    self.ino = dirent.d_ino
  }

  public var description: String {
    return "\(name) : \(type) {\n  ino: \(ino)\n  size: \(size)\n}"
  }

  public var formattedString: String {
    return String.alignedText(strings: name, "\(ino)", "\(size)", "\(type)",
                  spaces: [25, 10, 7, 15])
  }
}

extension DirectoryEntry
{
  public static func files(at path: String) -> [DirectoryEntry]
  {
    guard let dfd = path.withCString({
      opendir($0)
    }) else {
      perror("opendir")
      return []
    }

    var dirents = [DirectoryEntry]()

    var dir: dirent = dirent()

    var resloved: UnsafeMutablePointer<dirent>? = nil

    #if os(Linux)
    let path = path.characters[path.endIndex] == "/" ? path : (path + "/")
    #else
    let path = path.hasSuffix("/") ? path : (path + "/")
    #endif

    repeat
    {
      if readdir_r(dfd, &dir, &resloved) != 0 {
        break
      }

      if resloved == nil {
        break
      }

      dirents.append(Dirent(basePath: path, dirent: resloved!.pointee))

    } while (resloved != nil)

    closedir(dfd)

    return dirents
  }

  public static func find(entry: String, in path: String) -> DirectoryEntry?
  {
    guard let dfd = path.withCString({
      opendir($0)

    }) else {
      return nil
    }

    var dir: dirent = dirent()

    var result: UnsafeMutablePointer<dirent>? = nil

    repeat
    {
      if readdir_r(dfd, &dir, &result) != 0 {break}

      if result == nil { break }

      if Dirent(basePath: path, dirent: result!.pointee).name == entry {
        closedir(dfd)
        return Dirent(basePath: path, dirent: result!.pointee)
      }

    } while (result != nil)

    closedir(dfd)

    return nil
  }
}
