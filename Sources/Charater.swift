//
//  print.swift
//  CKit
//
//  Created by Yuji on 7/16/16.
//
//

import Foundation

public extension Character {
    public static var null: Character {
        return Character(UnicodeScalar.init(0))
    }
    
    public static var digits: [Character] {
        return "0123456789".characters.sorted()
    }

    public static var lowercase: [Character] {
        return "abcdefghijklmnopqrstuvwxyz".characters.sorted()
    }
    
    public static var uppercase: [Character] {
        return "ABCDEFGHIJKLMNOPQRSTUVWXYZ".characters.sorted()
    }
    
    public var isAlphabit: Bool {
        return self.isLowercase || self.isUppercase
    }
    
    public var isUppercase: Bool {
        return Character.uppercase.contains(self)
    }
    
    public var isLowercase: Bool {
        return Character.lowercase.contains(self)
    }
    
    public var isdigits: Bool {
        return Character.digits.contains(self)
    }
}

@inline(__always)
public func stderr(_ string: String) {
    var msg = string
    write(STDERR_FILENO, &msg, msg.characters.count)
}

extension String : CustomStringConvertible {
    public var description: String {
        return self
    }
}

public extension String {
    public static func alignedText(strings: String..., spaces: [Int]) -> String {
        let astr = strings.enumerated().map { (index, string) -> String in
            var temp = string
            let space_to_insert = spaces[index] - string.characters.count
            for _ in 0 ..< space_to_insert {
                temp.append(Character(" "))
            }
            return temp
        }
        return astr.reduce("", {"\($0)\($1)"})
    }
}

public extension Strideable {
    @inline(__always)
    public mutating func decrement() {
        self -= 1
    }
    
    @inline(__always)
    public mutating func increment() {
        self += 1
    }
}
