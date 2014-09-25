#lang racket/base
(require 2htdp/image
         2htdp/universe
         dos/win
         dos/win/big-bang)

(define (circle@ x y r)
  (λ (s) (place-image (circle r "solid" "blue") x y s)))

(define (mouse-tracking-ball env)
  (define r (env-read1 env 'radius 0))
  (define nr
    (if (env-key? env " ")
        0
        (+ r 0.1)))
  (define x (env-read1 env 'mouse-x 0))
  (define y (env-read1 env 'mouse-y 0))
  (mouse-tracking-ball
   (win-write
    #:threads (decaying-ball x y r)
    'gfx (circle@ x y r)
    'radius nr)))

(define ((decaying-ball x y r) env)
  (for ([i (in-range 1 11)])
    (win-write 'gfx (circle@ x y (/ r i))))
  (win-exit))

(module+ main
  (big-bang (win-mbr mouse-tracking-ball)
            (on-tick win-on-tick)
            (to-draw (win-to-draw (empty-scene 800 600)))
            (on-key win-on-key)
            (on-release win-on-release)
            (on-mouse win-on-mouse)
            (stop-when (win-stop-when 'mouse-click))))
