#lang racket/base
(require racket/match
         racket/list
         dos/os2)

(struct win (env ps))

(define (hash-append ht k v)
  (hash-update ht k (λ (l) (append v l)) empty))

(define empty-env (hasheq))
(define (merge-env ht1 ht2)
  (for/fold ([ht ht1])
            ([(k v) (in-hash ht2)])
    (hash-append ht k v)))

(define (env-read env k)
  (hash-ref env k empty))
(define (env-read1 env k d)
  (define vs (env-read env k))
  (if (empty? vs) d (first vs)))

(define (hasheq/l kvs)
  (let loop ([h (hasheq)]
             [kvs kvs])
    (match kvs
      [(list)
       h]
      [(list-rest k v kvs)
       (loop (hash-append h k (list v))
             kvs)])))

(define (win-write #:threads [ts null] . kvs)
  (os2-write #:threads ts (hasheq/l kvs)))

(define (win-exit . kvs)
  (os2-exit (hasheq/l kvs)))

(define (win-mbr . ts)
  (win empty-env ts))

(define (win-boot w)
  (match-define (win env ps) w)
  (define-values
    (new-env new-ps)
    (os2-boot merge-env env ps empty-env))
  (win new-env new-ps))

(define (win-env-replace w k vs)
  (match-define (win env ps) w)
  (win (hash-set env k vs) ps))
(define (win-env-read w k)
  (match-define (win env ps) w)
  (env-read env k))
(define (win-env-read1 w k d)
  (match-define (win env ps) w)
  (env-read1 env k d))

(require racket/contract/base)
(provide
 (contract-out
  [win?
   (-> any/c boolean?)]
  [win-mbr
   (->* () () #:rest any/c
        win?)]
  [win-write
   (->* ()
        (#:threads any/c)
        #:rest any/c
        hash?)]
  [win-exit
   (->* () ()
        #:rest any/c
        hash?)]
  [env-read1
   (-> hash? symbol? any/c
       any/c)]
  [env-read
   (-> hash? symbol?
       (listof any/c))]
  [win-boot
   (-> win? win?)]
  [win-env-replace
   (-> win? symbol? (listof any/c)
       win?)]
  [win-env-read
   (-> win? symbol?
       (listof any/c))]
  [win-env-read1
   (-> win? symbol? any/c
       any/c)]))
