#lang scribble/manual
@(require (for-label racket/base
                     racket/contract/base
                     racket/bool))

@title{@bold{DOS}: Delimited-continuation-based Operating-system Simulator}
@author{Jay McCarthy}

This library provides a set of operating-system-like kernels, where
the user can decide what the kernel's internal state is and how user
processes interact with that state. There are three kernels that make
concrete common kernel implementation choices.

The big picture of this library is that the @racketmodname[dos/win]
module makes @racketmodname[2htdp/universe]-style programs more
compositional by (a) using continuations to hide the internal
state (including control state) of components and (b) using
environments as a standard monoid-based inter-component communication
channel. A monoid is used to ensure that the components can be
evaluated in any order.

@table-of-contents[]

@section[#:tag "dos"]{DOS: bare-bones kernel}

@defmodule[dos]
@(require (for-label dos))

@racketmodname[dos] provides a bare-bones kernel with no assumptions
on what system calls are possible or what the kernel state is.  A
simple example is
@link["https://github.com/jeapostrophe/dos/blob/master/dos/examples/dos.rkt"]{included
in the source}.

@defproc[(dos-boot [+ (-> state? state? state?)]
                   [cur state?]
                   [ps (treeof (-> state? state?))]
                   [zero state?])
         state?]{         

Calls each process in @racket[ps] (which is a @racket[cons]-tree of
process functions) with @racket[cur] and expects that either (a) a new
state or (b) the process will call @racket[dos-syscall] and construct
a new state. The resulting states are combined using
@racket[+]. Assumes that @racket[state?], @racket[+], and
@racket[zero] form a
@link["https://en.wikipedia.org/wiki/Monoid"]{monoid}, i.e., that
states can be combined in any order and @racket[(+ a zero)] is the
same as @racket[a]. }

@defproc[(dos-syscall [k->state (-> continuation? state?)])
         state?]{
         
Calls @racket[k->state] with the current continuation and expects it
to return a state that will be delivered to @racket[dos-boot]. Returns
the @racket[cur] state that @racket[dos-boot] is called with if the
continuation is included in @racket[dos-boot]'s @racket[ps] argument. }

@defproc[(tcons [left any/c] [right any/c]) any/c]{ Returns a
@racket[cons]-tree such that if @racket[left] or @racket[right] are
@racket[null] then a @racket[cons] is not allocated.

This function is useful for constructing arguments to
@racket[dos-boot]'s @racket[ps] argument efficiently. }

@defproc[(dos-test [cur state?] [p (-> state? state?)]) state?]{

Runs the process @racket[p] with the @racket[cur] state and returns
the state that it returns or constructs with @racket[dos-syscall].}

@section[#:tag "os2"]{OS2: bare-banes kernel with process creation system-call}

@defmodule[dos/os2]
@(require (for-label dos/os2))

@racketmodname[dos/os2] extends @racketmodname[dos] by assuming that
when the OS state is manipulated new processes can be created.  A
simple example is
@link["https://github.com/jeapostrophe/dos/blob/master/dos/examples/os2.rkt"]{included
in the source}.

@defproc[(os2-boot [+ (-> state? state? state?)]
                   [cur state?]
                   [ps (treeof (-> state? state?))]
                   [zero state?])
         (values state? (treeof (-> state? state?)))]{         

Like @racket[dos-boot] but returns a list of processes in addition to the new state. }

@defproc[(os2-write [st state?] [#:threads ts (treeof (-> state? state?)) null])
         state?]{

A system call that returns the state @racket[st] and creates
additional processes specified in @racket[ts]. Returns the next state,
like @racket[dos-syscall].  }

@defproc[(os2-exit [st state?]) void?]{

Like @racket[os2-write], but does not return.}

@defproc[(os2-test [cur state?] [p (-> state? state?)]) state?]{

Runs the process @racket[p] with the @racket[cur] state and returns
the state that it computes via @racket[os2-write] or @racket[os2-exit].}

@section[#:tag "win"]{WIN: kernel with processes and shared registry}

@defmodule[dos/win]
@(require (for-label dos/win))

@racketmodname[dos/win] takes @racketmodname[dos/os2] and fixes the
state as a @deftech{environment}, or @deftech{registry}, or hash that
maps symbols to sets of values (represented as lists.)

@defproc[(win? [x any/c]) boolean?]{Identifies @racketmodname[dos/win]
kernel states.}

@defproc[(win-mbr [p (-> env? env?)] ...) win?]{Constructs a kernel
state where each of the @racket[p] are initial processes.}

@defproc[(win-write [#:threads ts (treeof (-> env? env?)) null] [key
symbol?] [val any/c] ... ...) env?]{Spawns new threads @racket[ts] and
adds mappings from each @racket[key] to each @racket[val] to the
registry. Returns the next registry.}

@defproc[(win-exit [key symbol?] [val any/c] ... ...) void?]{Like
@racket[win-write] but does not return.}

@defproc[(win-test [cur env?] [p (-> env? env?)]) env?]{Returns the
environment that @racket[p] writes when given @racket[cur].}

@defproc[(env-read1 [e env?] [k symbol?] [default any/c])
any/c]{Returns a value that @racket[e] holds for @racket[k] or
@racket[default] if it holds none.}

@defproc[(env-read [e env?] [k symbol?])
(listof any/c)]{Returns the values that @racket[e] holds for
@racket[k].}

@defproc[(win-boot [cur win?]) win?]{Simulates one cycle of the kernel
@racket[cur]'s operation and returns a new kernel state.}

These functions cannot be called from inside processes, because they
cannot capture @racket[win?] values.

@defproc[(win-env-replace [w win?] [k symbol?] [vs (listof any/c)])
win?]{Returns a new kernel state where the registry maps @racket[k] to
@racket[vs].}

@defproc[(win-env-read [w win?] [k symbol?]) (listof any/c)]{Like
@racket[env-read], but on the environment of @racket[w].}

@defproc[(win-env-read1 [w win?] [k symbol?] [default any/c]) any/c]{Like
@racket[env-read1], but on the environment of @racket[w].}

@section[#:tag "win+bb"]{WIN and @racket[big-bang] integration}

@defmodule[dos/win/big-bang]
@(require (for-label dos/win/big-bang
                     2htdp/image
                     2htdp/universe))

@racketmodname[dos/win/big-bang] implements some helpers for using
@racketmodname[dos/win] efficiently with
@racketmodname[2htdp/universe].  A simple example is
@link["https://github.com/jeapostrophe/dos/blob/master/dos/examples/win.rkt"]{included
in the source}, compare it to
@link["https://github.com/jeapostrophe/dos/blob/master/dos/examples/win-long.rkt"]{a
version that does not use} @racketmodname[dos].

@defproc[(win-on-tick [cur win?]) win?]{@racket[win-boot] with a
suggestive name. Suitable for use with @racket[on-tick].}

@defproc[(win-stop-when [k symbol?]) (-> win? boolean?)]{Returns a
function that returns something the environment maps @racket[k]
to. Suitable for use with @racket[stop-when]. }

@defproc[(win-to-draw [base any/c]) (-> win? any/c)]{Returns a
function that composes all the values that the registry maps
@racket['gfx] to using @racket[base] as the initial argument. Suitable
for use with @racket[to-draw] when @racket[base] is a @racket[image?]
and the function in @racket['gfx] consume and produce @racket[image?]
objects. }

@defproc[(win-on-mouse [w win?] [x integer?] [y integer?] [me any/c])
win?]{Stores @racket[x] in @racket['mouse-x] and @racket[y] in
@racket['mouse-y] and the state of the mouse button in
@racket['mouse-down?] of @racket[w]'s registry. Suitable for use with
@racket[on-mouse].}

@defproc[(win-on-key [w win?] [ke any/c]) win?]{Records the state of
the key that @racket[ke] corresponds to in the @racket['keys] entry in
@racket[w]'s environment. Suitable for use with @racket[on-key], when
@racket[win-on-release] is used with @racket[on-release].}

@defproc[(win-on-release [w win?] [ke any/c]) win?]{Records the state
of the key that @racket[ke] corresponds to in the @racket['keys] entry
in @racket[w]'s environment. Suitable for use with
@racket[on-release], when @racket[win-on-key] is used with
@racket[on-key].}

@defproc[(env-key? [e env?] [ke any/c]) boolean?]{Returns the state
of the key @racket[ke] in the environment @racket[e]. Suitable for use
within processes when @racket[win-on-key] is used with @racket[on-key]
and @racket[win-on-release] is used with @racket[on-release].}

