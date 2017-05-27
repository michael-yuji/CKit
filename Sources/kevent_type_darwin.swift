
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
//  Created by Yuji on 3/10/17.
//  Copyright © 2017 Yuji. All rights reserved.
//

#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
let _evfilt_read: Int16 = -1
let _evfilt_write: Int16 = -2
let _evfilt_aio: Int16 = -3
let _evfilt_vnode: Int16 = -4
let _evfilt_proc: Int16 = -5
let _evfilt_signal: Int16 = -6
let _evfilt_timer: Int16 = -7
let _evfilt_macport: Int16 = -8
let _evfilt_user: Int16 = -10
let _evfilt_vm: Int16 = -12
let _evfilt_except: Int16 = -15

public enum KernelEventType: Int16
{
    public typealias RawValue = Int16
    public var rawValue: Int16
    {
        switch self {
        case .read:
            return _evfilt_read
        case .write:
            return _evfilt_write
        case .vnode:
            return _evfilt_vnode
        case .signal:
            return _evfilt_signal
        case .timer:
            return _evfilt_timer
        case .user:
            return _evfilt_user
        case .vm:
            return _evfilt_vm
        case .machport:
            return _evfilt_macport
        case .proc:
            return _evfilt_proc
        default:
            return _evfilt_except
        }
    }
    
    public init(rawValue: Int16)
    {
        self =
            rawValue == _evfilt_read ? .read :
            rawValue == _evfilt_write ? .write:
            rawValue == _evfilt_vnode ? .vnode :
            rawValue == _evfilt_proc ? .proc :
            rawValue == _evfilt_timer ? .timer :
            rawValue == _evfilt_signal ? .signal :
            rawValue == _evfilt_vm ? .vm :
            rawValue == _evfilt_macport ? .machport :
            rawValue == _evfilt_except ? .except :
            .user
    }
    /// Takes a file descriptor as the identifier, and returns whenever there
    /// is data available to read. The behavior of the filter is slightly
    /// different depending on descriptor type.
    ///
    /// *Sockets*
    ///
    /// Socket which have previously been passed to `listen()` return when there
    /// is an incoming connection pending. `data` contains the size of the listen
    /// backlog.
    /// Other socket descriptors return when there is data to be read, subject to
    /// the SO_RCVLOWAT value of the socket buffer. This maybe overridden with a
    /// per-filter low water mark at the time the filter is added by setting the
    /// `NOTE_LOWAT` flag in `fflags`, and specifying the new low water mark in
    /// `data`. On return `data` contains the number of bytes of protocol data
    /// available to read.
    /// If the read direction of the socket has shutdown, then the filter also sets
    /// `EV_EOF` in `flags`, and returns the socket error (if any) in fflags. It is
    /// possible for EOF to be returned (indicating the connection is gone) while
    /// there is still data pending in the socket buffer.
    ///
    /// *Vnodes*
    ///
    /// Returns when the file pointer is not at the end of file. `data` contains the
    /// offset from current position to end of file, and may be negative.
    /// This behavior is different from `poll`, where read events are triggered for
    /// regular files unconditionally. This event can be triggered unconditionally by
    /// setting the `NOTE_FILE_POLL` (FreeBSD) flag in `fflags`.
    ///
    /// *Fifos, Pipes*
    ///
    /// Returns when the there is data to read; `data` contains the numener of bytes
    /// available.
    /// When the last writer disconnects, the filter will set EV_EOF in `flags`. This
    /// may be cleared by passing in `EV_CLEAR`, at which point the filter will resume
    /// waiting for data to become available before returning.
    ///
    /// *Device nodes (OS X)*
    ///
    /// Returns when there is data to read from the device; `data` contains the number
    /// of bytes available. If the device does not support returning number of bytes, it
    /// will not allow the filter to be attached. However, if the `NOTE_LOWAT` flag is
    /// specified and the `data` field contains 1 on input, those devices will attach
    /// count of bytes to read on output.
    ///
    /// *BPF devices (FreeBSD)*
    ///
    /// Returns when the BPF buffer is full, the `BPF` timeout has expired, or when the BPF
    /// has `immediate mode` enabled and these is any data to read; `data` contains the
    /// number of bytes available.
    case read = -1

    /// Takes a file descriptor as the identifier, and returns whenever it is
    /// possible to write to the descriptor. For sockets, pipes and fifos, `data`
    /// will contain the amount of space remaining in the write buffer. The filter
    /// will set `EV_EOF` when the reader disconnects, and for the fifo case, this
    /// may be cleared by use of `EV_CLEAR`. Note that this filter is not supported
    /// for vnodes.
    ///
    /// For sockets, the low water mark and socket error handling is identical to the
    /// `EVFILT_READ` case
    case write = -2

    /// In Darwin, Returns when the file pointer is not at the end of file. `data` contains
    /// the offset from current position to end of file, and maybe negative.
    ///
    /// In BSD, Takes a file descriptor as the identifier and the events to watch for in
    /// `fflags`, and returns when one or more of the requested events occurs on the
    /// descriptor. The events to monitor are:
    ///
    /// *NOTE_ATTRIB*
    ///
    /// The file referenced by the descriptor had its attributes changed.
    ///
    /// *NOTE_CLOSE*
    ///
    /// A file descriptor referencing the monitored file, was closed. The closed file
    /// descriptor did not have write access.
    ///
    /// *NOTE_CLOSE_WRITE*
    ///
    /// A file descriptor referencing the monitored file, was closed. The closed file
    /// descriptor has write access.
    ///
    /// This note, as well as `NOTE_CLOSE`, are not activated when files are closed forcibly
    /// by `unmount` or `revoke`. Instead, `NOTE_REVOKE` is sent for such events.
    ///
    /// *NOTE_DELETE*
    ///
    /// The `unlink()` system call was called on the file referenced by the descriptor.
    ///
    /// *NOTE_EXTEND*
    ///
    /// For regular file, the file referenced by the descriptor was extended.
    ///
    /// For directory, reports that a directory entry was added or removed, as the result
    /// of rename operation. The `NOTE_EXTEND` event is not reported when a name is changed
    /// inside the directory.
    ///
    /// *NOTE_LINK*
    ///
    /// The link count on the file changed. In particular, the `NOTE_LINK` event is reported
    /// if a subdirectory was created pr de;eted inside the directory referenced by the
    /// descriptor.
    ///
    /// *NOTE_OPEN*
    ///
    /// The file referenced by the descriptor was opened.
    ///
    /// *NOTE_READ*
    ///
    /// A read occurred on the file referenced by the descriptor.
    ///
    /// *NOTE_RENAME*
    ///
    /// The file referenced by the descriptor was renamed
    ///
    /// *NOTE_REVOKE*
    ///
    /// Access to the file was revoked via `revoke(2)` or the underlying file system was
    /// unmounted.
    ///
    /// *NOTE_WRITE*
    ///
    /// A write occurred on the file referenced by the descriptor.
    ///
    /// On return, `fflags` contains the events which triggered the filter.
    case vnode = -4


    /// Takes the process ID to monitor as the identifier and the events to watch
    /// for in `fflags`, and returns when the process performs one or more of the
    /// requested events. If a process can normally see another process, it can
    /// attach an event to it. The events to monitor are:
    ///
    /// *NOTE_EXIT*
    ///
    /// The process has exited. The exit status will be stored in `data`.
    ///
    /// *NOTE_FORK*
    ///
    /// The process created a child process via `fork()` or similar call.
    ///
    /// *NOTE_EXEC*
    ///
    /// The process executed a new process via `execve` or similar call.
    ///
    /// *NOTE_SIGNAL*
    ///
    /// The process was sent a signal. Status can be checked via waitpid or similar call.
    case proc = -5


    /// Takes the signal number to monitor as the identifier and returns when the
    /// given signal is delivered to the process. This coexists with the `signal()`
    /// and `sigaction()` facilities, and has a lower precedence. Only signals
    /// sent to the process, not to a particular thread, will trigger and the
    /// filter. The filter will record all attempts to deliver a signal to a
    /// process, even if the signal has been marked as `SIG_IGN`. Event notification
    /// happends before normal signal delivery processing. `data` returns the number
    /// of times the signal has been generated since the last call to `kevent()`.
    /// This filter automatically sets the `EV_CLEAR` flag internally.
    case signal = -6

    /// Establishes an arbitrary timer identified by `ident`. When adding a timer,
    /// `data` specifies the timeout period. The timer will be periodic unless `EV_ONESHOT`
    /// is specified. On return, `data` contains the number of times the timeout has
    /// expired since the last call to `kevent()`. This filter automatically sets
    /// the `EV_CLEAR` flag internally. There is a system wide limit on the number
    /// of timers which is controlled by the `kern.kq_calloutmax` sysctl (FreeBSD).
    ///
    /// *NOTE_SECONDS*
    ///
    /// `data` is in seconds.
    ///
    /// *NOTE_USECONDS*
    ///
    /// `data` is in microseconds.
    ///
    /// *NOTE_NSECONDS*
    ///
    /// `data` is in nanoseconds.
    ///
    /// *NOTE_ABSOLUTE (Darwin)*
    ///
    /// `data` is an absolute timeout
    ///
    /// *NOTE_CRITICAL (Darwin)*
    ///
    /// system makes a best effort to fire this timer as scheduled.
    ///
    /// *NOTE_BACKGROUND (Darwin)*
    ///
    /// system has extra leeway to coalesce this timer.
    ///
    /// *NOTE_LEEWAY (Darwin)*
    ///
    /// exit[1] holds user-supplied slop in deadline for timer coalescing.
    ///
    /// If `fflags` is not set, the default is milliseconds. On return, fflags
    /// contains the events which triggered the filter.
    case timer = -7

    /// Establishes a user event identified by `ident` which is not associated with
    /// any kernel mechanism but is triggered by user level code. The lower 24 bits
    /// of the fflags may be used for user defined flags and manipulated using the
    /// following:
    ///
    /// *NOTE_FFNOP*
    ///
    /// Ignore the input fflags.
    ///
    /// *NOTE_FFAND*
    ///
    /// Bitwise AND fflags.
    ///
    /// *NOTE_FFCOPY*
    ///
    /// Copy `fflags`.
    ///
    /// *NOTE_FFCTRLMASK*
    ///
    /// Control mask for fflags
    ///
    /// *NOTE_FFLAGSMASK*
    ///
    /// User defined flag mask for fflags.
    ///
    /// A user event is triggered for output with the following:
    ///
    /// *NOTE_TRIFFER*
    ///
    /// Cause the event to be triffered/
    case user = -10

    /// Takes the name of a mach port, or port set, in `ident` and waits until a
    /// message is enqueued on the port or port set. When a message is detected,
    /// but not directly received by the kevent call, the name of the specific port
    /// where the message is enqueued is returned in `data`. If `fflags` contains
    /// `MACH_RCV_MSG`, the `ext[0]` and `ext[1]` flags are assumed to contain
    /// a pointer to the buffer where the message is to be received and the size
    /// of the receive buffer, respectively. If `MACH_RCV_MSG` is specified,
    /// yet the buffer size in `ext[1]` is zero, The space for the buffer may be
    /// carved out of the data_out area provided to `kevent_qos() if there is enough
    /// space remaining there.
    case machport = -8

    /// Takes a descriptor as the identifier, and returns whenever one of the
    /// specified exceptional conditions has occurred on the descriptor. Conditions
    /// are specified in `fflags`. Currently, this filter can be used to monitor the
    /// arrival of out-of-band data on a socket descriptor using the filter flag
    /// `NOTE_OOB`
    ///
    /// If the read direction of the socket has shutdown, then the filter also set
    /// `EV_EOF` in `flags`, and returns the socket error (if any) in `fflags`.
    case except = -15

    case vm = -12
}
#endif
