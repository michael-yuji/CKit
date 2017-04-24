
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
//  Created by Yuji on 3/10/16.
//  Copyright © 2016 Yuji. All rights reserved.
//

public struct Epoll: FileDescriptorRepresentable {
    public var fileDescriptor: Int32
    
    
    public func add(fd: Int32, for events: EpollEvents) {
        var ev = epoll_event(events: events.rawValue,
                             data: epoll_data_t(fd: fd)) // to use pointer
        _ = epoll_ctl(self.fileDescriptor, EPOLL_CTL_ADD, fd, &ev)
    }
    
    public func remove(fd: Int32) {
        _ = epoll_ctl(self.fileDescriptor, EPOLL_CTL_DEL, fd, nil)
    }
    
    public func wait(maxevs: Int, timeout: Int = 0) -> [epoll_event] {
        var evs = [epoll_event](repeating: epoll_event(), count: maxevs)
        let nev = epoll_wait(fileDescriptor, &evs ,Int32(maxevs), Int32(timeout))
        return Array(evs.dropLast(maxevs - Int(nev)))
    }
    
    public func wait(maxevs: Int, timeout: Int = 0, handler: (epoll_event) -> ()) {
        var evs = [epoll_event](repeating: epoll_event(), count: maxevs)
        let nev = epoll_wait(fileDescriptor, &evs ,Int32(maxevs), Int32(timeout))
        for i in 0..<Int(nev) {
            handler(evs[i])
        }
    }
    
    public init() {
        fileDescriptor = epoll_create(1024)
    }
}

public struct EpollEvents : OptionSet {
    public typealias RawValue = UInt32
    public var rawValue: UInt32
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    public init(rawValue: Int32) {
        self.rawValue = UInt32(rawValue)
    }
    
    /// The associated file is available for `read` operations
    public static let pollin = EpollEvents(rawValue: EPOLLIN.rawValue)
    
    /// The associated file is available for `write` operations
    public static let pollout = EpollEvents(rawValue: EPOLLOUT.rawValue)
    
    /// Stream socket peer closed connection, or shutdown writing
    /// half of connection. (This flag is especially useful for
    /// writing simple code to detect peer shutdown when using
    /// Edge Triggered monitoring.
    public static let rdhup = EpollEvents(rawValue: EPOLLRDHUP.rawValue)
    
    /// There is urgent data available for `read` operations
    public static let pri = EpollEvents(rawValue: EPOLLPRI.rawValue)
    
    /// Error condition happened on the associated file descriptor.
    /// `epoll_wait` will always wait for this event; it is not
    /// necessary to set it in `events`
    public static let err = EpollEvents(rawValue: EPOLLERR.rawValue)
    
    /// Hang up happened on the associated file descriptor.
    /// `epoll_wait` will always wait for this event; it is not
    /// necessary to set it in `events`. Note that when reading
    /// from a channel such as a pipe or a stream socket, this
    /// event merely indicates that the peer closed its end of
    /// channel. Subsequent reads from the channel will return
    /// 0 (end of file) only after all outstanding data in the
    /// channel has been consumed.
    public static let hup = EpollEvents(rawValue: EPOLLHUP.rawValue)
    
    /// Sets the Edge Triggered behavior for the associated file
    /// descriptor. The default behavior for `epoll` is Level
    /// Triggered. See `epoll` for more detailed information
    /// about Edge and Level Triggered event distribution
    /// architectures.
    public static let edgeTrigger = EpollEvents(rawValue: EPOLLET.rawValue)
    
    /// Sets the one-shot behavior for the associated file descriptor.
    /// This means that after an event is pulled out with `epoll_wait`
    /// the associated file descriptor is internally disabled and
    /// no other events will be reported by the `epoll` interface.
    /// The user much call `epoll_ctl()` with `EPOLL_CTL_MOD` to
    /// rearm the file descriptor with a new event mask.
    public static let oneshot = EpollEvents(rawValue: EPOLLONESHOT.rawValue)
    
    /// If `EPOLLONESHOT` and `EPOLLET` are clear and the process
    /// has `CAP_BLOCK_SUSPEND` capability, ensure that the system
    /// does not enter "suspend" or "hibernate" while this event
    /// is pending or being processed. The event is considered as
    /// being "processed" from the time when it is returned by a
    /// call to `epoll_wait` descriptor, the closure of that file
    /// descriptor, the removal of the event file descriptor with
    /// `EPOLL_CTL_DEL` or the clearing of `EPOLLWAKEUP` for the
    /// event file descriptor with `EPOLL_CTL_MOD`. See also BUGS.
    public static let wakeup = EpollEvents(rawValue: EPOLLWAKEUP.rawValue)
    
    /// Sets an exclusive wakeup mode for the epoll file descriptor
    /// this is being attached to the target file descriptor, `fd`.
    /// When a wakeup event occurs and multiple epoll file descriptors
    /// are attached to the same target file using `EPOLLEXCLUSIVE`,
    /// one or more of the epoll file descriptors will receive an
    /// event with `epoll_wait`. The default in this scenario (when
    /// `EPOLLEXCLUSIVE` ts not set) is for all epoll file descriptors
    /// to receive an event. `EPOLLEXCLUSIVE` is thus useful for
    /// avoiding thundering herd problems in certain scenarios.
    ///
    /// If the same file descriptor is in multiple epoll instances,
    /// some with the `EPOLLEXCLUSIVE` flag, and others without, then
    /// events will be provided to all epoll instances that did not
    /// specify `EPOLLEXCLUSIVE`, and at least one of the epoll
    /// instances that did specify `EPOLLEXCLUSIVE`.
    ///
    /// The following values may be specified in conjunction with
    /// `EPOLLEXCLUSIVE: EPOLLIN, EPOLLOUT, EPOLLWAKEUP`, and `EPOLLET`.
    /// EPOLLHUP and EPOLLERR can also be specified, but this is not
    /// required: as usual, these events are always reported if they
    /// occur, regardless of whether they are specified in events.
    /// Attempts to specify other values in `events` yield an error.
    /// `EPOLLEXCLUSIVE` may be used only in an `EPOLL_CTL_ADD`
    /// operation; attempts to employ it with `EPOLL_CTL_MOD` yield an
    /// error. If `EPOLLEXCLUSIVE` has been set usng `epoll_ctl()`,
    /// then a subsequent `EPOLL_CTL_MOD` on the same `epfd`, `fd` pair
    /// yields an error. A call to `epoll_ctl()` that specifies
    /// `EPOLLEXCLUSIVE` in `events` and specifies the target file
    /// descriptor `fd` as an epoll instance will likewise fail. The
    /// error in all of these cases is EINVAL
    //        public static let exclusive = EpollEvents(rawValue: EPOLLEXCLUSIVE)
}
