Rebol []
; Parse Roman Numerals
; Barry Arthur, 2016-10-07
; From Nigel Galloway's Java + ANTLR version, March 16th, 2012
; (https://www.rosettacode.org/wiki/Roman_numerals/Decode#ANTLR)
;
inc:  func ['word amount] [set word amount + get word]
inc1: func ['word] [inc :word 1]
;
parseRN:   [(number: 0 err: copy "") rn]
;
rn:        [any [Thousand (inc number 1000)] opt hundreds opt tens opt units]
;
hundreds:  [[(a-one: 0) h9 | (a-one: 0) h5] (if a-one > 3 [err: "Too many hundreds"])]
h9:        [Hundred   (inc1 a-one)     [
             FiveHund (inc number 400) |
             Thousand (inc number 900) |
             (inc number 100) any [Hundred (inc number 100 inc1 a-one)]]]
h5:        [FiveHund (inc number 500) any [Hundred (inc number 100 inc1 a-one)]]
;
tens:      [[(a-one: 0) t9 | (a-one: 0) t5] (if a-one > 3 [err: "Too many tens"])]
t9:        [ Ten     (inc1 a-one)    [
             Fifty   (inc number 40) |
             Hundred (inc number 90) |
             (inc number 10) any [Ten (inc number 10 inc1 a-one)]]]
t5:        [Fifty (inc number 50) any [Ten (inc number 10 inc1 a-one)]]
;
units:     [[(a-one: 0) u9 | (a-one: 0) u5] (if a-one > 3 [err: "Too many ones"])]
u9:        [ One  (inc1 a-one)   [
             Five (inc number 4) |
             Ten  (inc number 9) |
             (inc1 number) any [One (inc1 number inc1 a-one)]]]
u5:        [Five (inc number 5) any [One (inc1 number inc1 a-one)]]
;
One:       "I"
Five:      "V"
Ten:       "X"
Fifty:     "L"
Hundred:   "C"
FiveHund:  "D"
Thousand:  "M"
;
foreach r [MMXI MCMLVI XXCIII MCMXC MMVIII MDCLXVI IIIIX MIM
           MDCLXVI LXXIIX M MCXI CMXI MCM MMIX MCDXLIV MMXII] [
  rs: to string! r
  print rejoin [rs " -> "
    either parse rs parseRN [number]
                            [rejoin ["[FAIL: " either empty? err ["Invalid"] [err] "]"]]]
]