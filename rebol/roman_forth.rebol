Rebol [
  Title: "Roman Numbers"
  Source: "Thinking in Forth (Ans, 2004) by Leo Brodie, Figure 4.9, Page 153"
]
romans:     [I V X L C D M]
col:        0
ones:       does [col: 1]
tens:       does [col: 3]
hundreds:   does [col: 5]
thousands:  does [col: 7]
symbol:     func [offset] [pick romans (col + offset)]
oner:       does [prin symbol 0]
fiver:      does [prin symbol 1]
tener:      does [prin symbol 2]
oners:      func [cnt] [loop cnt [oner]]
almost:     func [div] [either zero? div [oner fiver] [oner tener]]
;
rigit: function [digit] [rem div] [
  rem: mod digit 5
  div: to integer! digit / 5
  either find [4 9] rem [almost div] [
    if not zero? div [fiver]
    oners rem
  ]
]
;
from: function [number divisor] [div num] [
  div: to integer! number / divisor
  num: number - (div * divisor)
  reduce [div num]
]
;
roman: function [number] [] [
  prin rejoin [number " -> "]
  if number > 3999 [print "TOO LARGE!" return]
  digit:    from  number  1000
  thousands rigit digit/1
  digit:    from  digit/2 100
  hundreds  rigit digit/1
  digit:    from  digit/2 10
  tens      rigit digit/1
  ones      rigit digit/2
  prin newline
]
;
roman 1    roman 4    roman 5    roman 6    roman 9    roman 10
roman 11   roman 14   roman 15   roman 16   roman 19   roman 20
roman 21   roman 44   roman 55   roman 66   roman 99   roman 100
roman 101  roman 104  roman 105  roman 106  roman 109  roman 110
roman 111  roman 444  roman 555  roman 666  roman 999  roman 1000
roman 3000 roman 3999 roman 4000
