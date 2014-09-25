#lang racket/base

(define 0x80 (make-continuation-prompt-tag 'dos))

(define (run-process-until-syscall p st)
  (call-with-continuation-barrier
   (λ ()
     (call-with-continuation-prompt
      (λ () (p st))
      0x80
      (λ (x) x)))))

(define (dos-syscall k->syscall)
  ;; First we capture our context back to the OS
  (call-with-current-continuation
   (λ (k)
     ;; Then we abort, give it to the OS, along with a syscall
     ;; specification
     (abort-current-continuation 0x80 (k->syscall k)))
   0x80))

(define (map-reduce f + a l)
  (cond
   [(null? l)
    a]
   [(pair? l)
    (+ (map-reduce f + a (car l))
       (map-reduce f + a (cdr l)))]
   [else
    (f l)]))

(define (dos-boot merge-effects last-state ps empty-effects)
  (map-reduce (λ (p) (run-process-until-syscall p last-state))
              merge-effects
              empty-effects
              ps))

(define (tcons x y)
  (cond [(null? x) y]
        [(null? y) x]
        [else (cons x y)]))

(define (dos-test st p)
  (run-process-until-syscall p st))

(require racket/contract/base)
(provide
 (contract-out
  [tcons
   (-> any/c any/c any/c)]
  [dos-syscall
   (-> (-> continuation? any/c)
       any/c)]
  [dos-test
   (-> any/c (-> any/c any/c)
       any/c)]
  [dos-boot
   (-> (-> any/c any/c any/c)
       any/c
       any/c ;; (treeof (-> any/c any/c))
       any/c
       any/c)]))
