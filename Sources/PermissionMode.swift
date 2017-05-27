
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
//  Created by Yuji on 3/11/17.
//  Copyright © 2016 Yuji. All rights reserved.
//

public struct PremissionMode: OptionSet, CustomStringConvertible
{
    public typealias RawValue = mode_t
    public var rawValue: mode_t
    public init(rawValue: mode_t)
    {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: mode_t)
    {
        self.rawValue = rawValue
    }
    
    public var description: String
    {
        return
            (
                "\(self.contains(PremissionMode.user.r) ? "r" : "-")" +
                "\(self.contains(PremissionMode.user.w) ? "w" : "-")" +
                "\(self.contains(PremissionMode.user.x) ? "x" : "-")" +
                "\(self.contains(PremissionMode.group.r) ? "r" : "-")" +
                "\(self.contains(PremissionMode.group.w) ? "w" : "-")" +
                "\(self.contains(PremissionMode.group.x) ? "x" : "-")" +
                "\(self.contains(PremissionMode.other.r) ? "r" : "-")" +
                "\(self.contains(PremissionMode.other.w) ? "w" : "-")" +
                "\(self.contains(PremissionMode.other.x) ? "x" : "-")"
        )
    }
    
    public static let user =
        (r: PremissionMode(mode_t(S_IREAD)),
         w: PremissionMode(mode_t(S_IWRITE)),
         x: PremissionMode(mode_t(S_IEXEC)))
    
    public static let group =
        (r: PremissionMode(mode_t(S_IRGRP)),
         w: PremissionMode(mode_t(S_IWGRP)),
         x: PremissionMode(mode_t(S_IXGRP)))
    
    public static let other =
        (r: PremissionMode(mode_t(S_IROTH)),
         w: PremissionMode(mode_t(S_IWOTH)),
         x: PremissionMode(mode_t(S_IXOTH)))
}
