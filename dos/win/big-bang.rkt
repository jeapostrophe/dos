#lang racket/base
(require dos/win)

(define ((win-stop-when k) w)
  (win-env-read1 w k #f))

(define ((win-to-draw is) w)
  (for/fold ([s is])
            ([f (in-list (win-env-read w 'gfx))])
    (f s)))

(define (win-on-mouse w0 x y me)
  (define w1 (win-env-replace w0 'mouse-click (list (string=? me "button-down"))))
  (define w2 (win-env-replace w1 'mouse-x (list x)))
  (define w3 (win-env-replace w2 'mouse-y (list y)))
  w3)

(define (win-on-key-signal w ke up?)
  (define keys (win-env-read1 w 'keys (hash)))
  (define nkeys (hash-set keys ke up?))
  (win-env-replace w 'keys (list nkeys)))
(define (win-on-key w ke)
  (win-on-key-signal w ke #t))
(define (win-on-release w ke)
  (win-on-key-signal w ke #f))
(define (env-key? env k)
  (hash-ref (env-read1 env 'keys (hash)) k #f))

(require racket/contract/base)
(provide
 (rename-out
  [win-boot win-on-tick])
 (contract-out
  [win-stop-when
   (-> symbol?
       (-> win? boolean?))]
  [win-to-draw
   (-> any/c
       (-> win? any/c))]
  [win-on-mouse
   (-> win? integer? integer? any/c
       win?)]
  [win-on-key
   (-> win? any/c
       win?)]
  [win-on-release
   (-> win? any/c
       win?)]
  [env-key?
   (-> hash? any/c
       boolean?)]))
