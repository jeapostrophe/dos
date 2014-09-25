#lang racket/base
(require 2htdp/image
         2htdp/universe
         racket/match
         racket/list)

(define (circle@ x y r)
  (λ (s) (place-image (circle r "solid" "blue") x y s)))

(struct world (space-down? mouse-x mouse-y mouse-click? radius decaying))
(struct decay (x y r i))

(define (world-tick w)
  (match-define (world space-down? x y mouse-click? r decaying) w)
  (define nr
    (if space-down?
        0
        (+ r 0.1)))
  (world space-down? x y mouse-click? nr
         (cons (decay x y r 1)
               (for/list ([d (in-list decaying)]
                          [j (in-range 9)])
                 (match-define (decay x y r i) d)
                 (decay x y r (add1 i))))))

(define (world-draw w)
  (match-define (world space-down? x y mouse-click? r decaying) w)
  (define is ((circle@ x y r)
              (empty-scene 800 600)))
  (for/fold ([s is])
            ([d (in-list decaying)])
    (match-define (decay x y r i) d)
    ((circle@ x y (/ r i)) s)))

(define (world-on-key w k)
  (if (string=? k " ")
      (struct-copy world w
                   [space-down? #t])
      w))
(define (world-on-release w k)
  (if (string=? k " ")
      (struct-copy world w
                   [space-down? #f])
      w))

(define (world-on-mouse w x y me)
  (define nw
    (struct-copy world w
                 [mouse-x x]
                 [mouse-y y]))
  (cond
   [(string=? "button-down" me)
    (struct-copy world nw
                 [mouse-click? #t])]
   [(string=? "button-up" me)
    (struct-copy world nw
                 [mouse-click? #f])]
   [else
    nw]))

(define (world-stop-when w)
  (world-mouse-click? w))

(module+ main
  (big-bang (world #f 0 0 #f 0 empty)
            (on-tick world-tick)
            (to-draw world-draw)
            (on-key world-on-key)
            (on-release world-on-release)
            (on-mouse world-on-mouse)
            (stop-when world-stop-when)))
