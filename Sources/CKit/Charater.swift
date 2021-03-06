
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
//  ON ANY THEORY OF L;IABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those
//  of the authors and should not be interpreted as representing official policies,
//  either expressed or implied, of the FreeBSD Project.
//
//  Created by Yuji on 7/16/16.
//  Copyright © 2016 yuuji. All rights reserved.
//

public extension Character
{
  static var null: Character
  {
    return Character(UnicodeScalar.init(0))
  }

  static var digits: [Character]
  {
    return "0123456789".sorted()
  }

  static var lowercase: [Character]
  {
    return "abcdefghijklmnopqrstuvwxyz".sorted()
  }

  static var uppercase: [Character]
  {
    return "ABCDEFGHIJKLMNOPQRSTUVWXYZ".sorted()
  }

  var isAlphabit: Bool
  {
    return self.isLowercase || self.isUppercase
  }

  var isUppercase: Bool
  {
    return Character.uppercase.contains(self)
  }

  var isLowercase: Bool
  {
    return Character.lowercase.contains(self)
  }

  var isdigits: Bool
  {
    return Character.digits.contains(self)
  }
}

@inline(__always)
public func stderr(_ string: String)
{
  var msg = string
  write(STDERR_FILENO, &msg, msg.count)
}

public extension String
{
  static func alignedText(strings: String..., spaces: [Int]) -> String
  {
    let astr = strings.enumerated().map
    { (__val:(Int, String)) -> String in let (index,string) = __val;
      var temp = string
      let space_to_insert = Swift.max(0, spaces[index] - string.count)
      for _ in 0 ..< space_to_insert {
        temp.append(Character(" "))
      }
      return temp
    }
    return astr.reduce("", {"\($0)\($1)"})
  }
}

public extension Strideable
{
  @inline(__always)
  mutating func decrement()
  {
    self = self.advanced(by: -1)
  }

  @inline(__always)
  mutating func increment()
  {
    self = self.advanced(by: 1)
  }
}
