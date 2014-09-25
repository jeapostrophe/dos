#lang racket/base
(require racket/match
         dos)

(struct os2 (state procs))

(define (os2-exit st)
  (dos-syscall (λ (k) (os2 st null))))

(define (os2-write #:threads [ts null] st)
  (dos-syscall (λ (k) (os2 st (tcons k ts)))))

(define (os2-boot merge-st last-st ps empty-st)
  (define (merge-bst b1 b2)
    (match-define (os2 st1 ps1) b1)
    (match-define (os2 st2 ps2) b2)
    (os2 (merge-st st1 st2) (tcons ps1 ps2)))
  (match-define (os2 next-st next-ps)
                (dos-boot merge-bst last-st ps (os2 empty-st null)))
  (values next-st next-ps))

(require racket/contract/base)
(provide
 (contract-out
  [os2-exit
   (-> any/c any)]
  [os2-write
   (->* (any/c)
        (#:threads any/c)
        any/c)]
  [os2-boot
   (-> (-> any/c any/c any/c)
       any/c
       any/c
       any/c
       (values any/c
               any/c))]))
