#lang racket/base
(require racket/match
         dos)

(struct state (i ps) #:transparent)

(define (merge-effects st1 st2)
  (match-define (state i1 ps1) st1)
  (match-define (state i2 ps2) st2)
  (state (+ i1 i2) (tcons ps1 ps2)))

(define (t0 st)
  (for/fold ([st st])
            ([j (in-range 10)])
    (define i (state-i st))
    (displayln i)
    (dos-syscall
     (λ (k)
       (state (* i 2) (list k)))))
  (dos-syscall (λ (k) (state 0 null))))

(module+ main
  (for/fold ([st (state 1 t0)])
            ([i (in-range 20)])
    (dos-boot merge-effects st
              (state-ps st)
              (state 0 null))))

(module+ test
  (require rackunit)
  (check-equal? 2 (state-i (dos-test (state 1 null) t0))))
