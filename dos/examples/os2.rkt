#lang racket/base
(require dos/os2)

(define (t0 i)
  (for/fold ([i i])
            ([j (in-range 10)])
    (displayln i)
    (if (and (even? i) (<= i 100))
        (os2-write #:threads t0 (* i 2))
        (os2-write (* i 2))))
  (os2-exit 0))

(for/fold ([st 1] [ps t0])
          ([i (in-range 20)])
  (os2-boot + st ps 0))
