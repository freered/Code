;; ==============================
;; Script: alien.r
;; downloaded from: www.REBOL.org
;; on: 14-May-2017
;; at: 9:11:03.196627 UTC
;; 
;; ==============================
REBOL [
    Title: "Alien Dialect"
    Date: 10-Mar-1999
    File: %alien.r
    Purpose: "It came from outer space"
    Comment: {
        Rebol is not tied to any specific syntax, and
        can even accommodate a program written entirely
        in punctuation marks.  This script is a good 
        example of which punctuation can be utilized
        in words, as well as showing the flexibility of
        dialects in REBOL.

        Remember: many punctuation characters
        are reserved for use by Rebol.

        Challenge to the Rebol learner:  Try to follow 
        what is going on in this script.
    }
    library: [
        level: 'advanced 
        platform: none 
        type: none 
        domain: 'x-file 
        tested-under: none 
        support: none 
        license: none 
        see-also: none
    ]
    Version: 1.0.0
    Author: "Anonymous"
]

!:    :do         `=`~:   char!            __: " " 
`-`:  :make        *!*:   integer!        `~-: 0   
&:    :func        ``=:   word!           `~.: 1   
_:    :load        !-.:  :head           `~..: 2   
|:    :if          |-.:  :tail          `~...: 3   
?:    :loop        |~.:  :insert       `~....: 4   
|~:   :print        `!:  :repeat           `-: 5   
|~|~: :prin       `-`~:  :copy             `.: 6   
`:    :add         _._:   block!          `..: 7   
||:   :any          &~:  :not            `...: 8   
`|:   :foreach    &!`~:  "^/"           `....: 9   

`~`~: & [&&.] [`-` _._ &&.]                            
                                       
&|~&: `~`~ {                           
    78 79 87 32 80 69 82 76    
    32 85 83 69 82 83 32 87    
    79 78 39 84 32 10 70 69    
    69 76 32 76 69 70 84 32 
    79 85 84                  
}                        

?||.: `-` `~- `~.... ** `~...; @% ^^/ \# $<>

&~|: & [] [
    ? ?||. [|~|~ `-` `=`~ (`.. * `.)]
]

&~| |~ &!`~
                         
|~_: & [!!!] [
    `| _! !!! [|~|~ [`-` `=`~ _! __]]
     |~ `-` `=`~ 10
]

|~_ &|~&

&~| |~|~ `-` `=`~ ` `... `~..
