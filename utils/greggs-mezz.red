Red [
	File: 	 %greggs-mezz.red
	Author:  "Gregg Irwin"
	Purpose: "An interim mezzanine dump, while Red is still moving fast."
	Tabs:	 4
	Comment: {
		Not everything here has been well-tested or, well, tested. Most
		of the functions are ports from R2, with many more to come. I'm
		combining everything in one file for ease of experimentation, so
		you don't have to worry about includes or dependencies with the
		funcs spread out in categorized files.
	}
]


e.g.: :comment			; for example			exempli gratia


;-------------------------------------------------------------------------------
;# Types

immediate?: func [
	"Returns true if value is any type of immediate value"
	value [any-type!]
][
	find immediate! type? :value
]

scalar?: func [
	"Returns true if value is any type of scalar value"
	value [any-type!]
][
	find scalar! type? :value
]

to-char: func [i [integer!]][#"^(00)" + i]

to-path: func [spec][
	; LOAD FORM is used to clean up specs that have refinements 
	; in them. Refinement values get their sigil doubled, which
	; FORM removes, so they are sanitized. More overhead, but we
	; could make that optional if this func lives on.
	load form append clear '_/_ spec
]

;-------------------------------------------------------------------------------
;# Math and Numeric

average: func [
	"Returns the average of all values in a block"
	block [any-block!] "Block of numeric values"
][
	if empty? block [return none]
	divide  sum block  length? block
]

divisible?: func [
	"Returns true if A is evenly divisible by B"
	a [number! char! pair! tuple! vector!]
	b [number! char! pair! tuple! vector!]
][
	zero? a // b
]

limit: function [
	"Returns a value constrained between two boundaries (inclusive)"
	value
	bound1
	bound2
][
	lower: min bound1 bound2
	upper: max bound1 bound2
	max lower min upper value
]

linear-interpolate: func [
	"Interpolate a value between input and output ranges"
	in-min  [number!] "Minimum input value"
	in-max  [number!] "Maximum input value"
	out-min [number!] "Minimum output value"
	out-max [number!] "Maximum output value"
	value   [number!] "Value to interpolate"
][
	add out-min ((value - in-min) / (in-max - in-min) * (out-max - out-min))
]
;repeat i 10 [print [i linear-interpolate 0.0 10.0 -1.0 0.0 to float! i]]
;foreach i [10 50 100 150 200] [print [i linear-interpolate 0.0 200.0 20.0 50.0 to float! i]]

make-linear-interpolater: function [
	"Returns a function that interpolates a value between input and output ranges"
	in-min  [number!] "Minimum input value" 
	in-max  [number!] "Maximum input value" 
	out-min [number!] "Minimum output value"
	out-max [number!] "Maximum output value"
][
	in-range: in-max - in-min
	out-range: out-max - out-min
	scale: out-range / in-range
	func compose [
		(rejoin ["Interpolate a value from [" in-min " to " in-max "] to [" out-min " to " out-max "]."])
		value [number!] "Value to interpolate"
	] compose/deep [
		;add (out-min) (to paren! compose [value - (in-min)]) * (scale)
		; Can't use TO/MAKE to make a paren! yet.
		add (out-min) (head insert copy quote ()  compose [value - (in-min)]) * (scale)
	]
]
;e.g. [
;	lin-terp-fn: make-linear-interpolater 0.0 10.0 -1.0 0.0
;	repeat i 10 [print [i lin-terp-fn to float! i]]
;	lin-terp-fn: make-linear-interpolater 0.0 200.0 20.0 50.0
;	foreach i [10 50 100 150 200] [print [i lin-terp-fn to float! i]]
;]

near?: func [
	"Returns true if the values are <= 1E-15 apart"
	value1 [number! time!] ; money! date! 
	value2 [number! time!] ; money! date! 
	/within  "Specify an alternate maximum difference (epsilon)."
		e [number! time!] "The epsilon value."	; money! 
][
	either date? value1 [
		e: to time! absolute any [e 1E-9]
		e >= abs difference value1 value2
	][
		e: absolute any [e  to value1 1E-15]
		e >= abs value1 - value2
	]
]

product: function [
	"Returns the product of all values in a block"
	values [block!] "Block of numeric values"
][
	result: any [
		attempt [make pick values 1 1]
		attempt [add 1 (0 * pick values 1)]
		1
	]
	foreach value reduce values [result: result * value]
	result
]

sum: function [
	"Returns the sum of all values in a block"
	values [block!] "Block of numeric values"
] [
	result: any [
		attempt [make pick values 1 0]
		attempt [0 * pick values 1]
		0
	]
	foreach value reduce values [result: result + value]
	result
]

;-------------------------------------------------------------------------------
;# General

decr: function [
	"Decrements a value or series index"
	value [scalar! series! any-word! any-path!] "If value is a word, it will refer to the decremented value"
	/by "Change by this amount"
		amount [scalar!]
][
	incr/by value negate any [amount 1]
]

default: function [
	"Sets the value(s) one or more words refer to, if the word is none or unset"
	'word "Word, or block of words, to set."
	value "Value, or block of values, to assign to words."
][
	def: func [w "Word" v "Value"][
		; We're setting one word, so don't need to use set/only.
		if any [not value? :w  none? get w][set w :v]
		get w
	]
	; CASE is used, rather than COMPOSE, to avoid the block allocation.
	case [
		word?  :word [def word :value]
		block? :word [
			collect [
				repeat i length? word [
					keep/only def word/:i either block? :value [value/:i][:value]
				]
			]
		]
	]
]
;e.g. [
;	default a 1
;	default [a b c] [2 3 4]
;	default f :append
;	default [g h i j k l m] [1 2 [3] 4 5 6 7]
;	default [g h i j k l m n o] [. . . . . . . .]
;]

; For series! args, 'advance is a nicer name.
incr: function [
	"Increments a value or series index."
	value [scalar! series! any-word! any-path!] "If value is a word, it will refer to the incremented value"
	/by "Change by this amount"
		amount [scalar!]
][
	amount: any [amount 1]
	
	if integer? value [return add value amount]			;-- This speeds up our most common case by 4.5x
														;	though we are still 5x slower than just adding 
														;	1 to an int directly and doing nothing else.

	; All this just to be smart about incrementing percents.
	if all [
		integer? amount
		1 = absolute amount
		any [percent? value  percent? attempt [get value]]
	][amount: to percent! (1% * sign? amount)]			;-- % * int == float, so we cast.
		
	case [
		scalar? value [add value amount]
		any [
			any-word? value
			any-path? value								;!! Check any-path before series.
		][
			op: either series? get value [:skip] [:add]
			set value op get value amount
			:value                                      ;-- Return the word for chaining calls.
		]
		series? value [skip value amount]
	]
]
;e.g. [
;	w: 1
;	incr w
;	w
;	incr 'w
;	w
;	b: [1 2 3 x 4 y 5 z [6 7 8]]
;	incr b
;	b
;	incr 'b
;	b
;	incr 'b/x
;	b
;	incr/by 'b/y 2
;	b
;	incr 'b/z
;	b
;	incr 'b/z/1
;	b
;	v: 1.2.3
;	incr v
;	v
;	incr 'v
;	v
;	incr/by v 2.3.4
;	incr #"A"
;	incr 1:2:3
;	incr 1x2
;	incr 1%
;]


opt: func [
	"If condition is TRUE, return value, otherwise return empty value of the same type"
	condition
	value "Some types, e.g., word types, return none if condition is false."
][
	either condition [ value ][ attempt [make value 0] ]
]
;e.g. [
;	opt true 'a
;	opt true "A"
;	opt false 'a
;	opt false "test"
;	opt false 100
;	opt false http://www.red-lang.org
;	opt false 10x10
;	opt false 1:2:3
;]

; I've tried a number of variations on this func, name, refinements,
; dialect, etc., so consider this as one of many possibilities.
set...: func [
	"Like SET, but the first refinement! in words will refer to the rest of the values"
	words  [block!]  "Words to set"
	values [series!] "Values words will refer to"
	/local w
][
	parse words [
		any [
			set w refinement! (set w values) to end
			| set w word! (set w pick values 1   values: next values)
		]
	]
]
;e.g. [
;	set... [a /__] [1 2 3 4 5]   ;?? __
;	set... [a b /__] [1 2 3 4 5] ;?? __
;	set... [a b c] [5 6]
;	set... [a b c /__] [1 2 [x y z] 3 4 5] ;?? __
;]


time-it: func [block /count ct /local t baseline][
	ct: any [ct 1]
	t: now/time/precise
	loop ct [do []]
	baseline: now/time/precise - t
	t: now/time/precise
	loop ct [do block]
	now/time/precise - t - baseline
]

; It's easy to do a simpler version of this if you don't want
; the default key option.
time-marks: object [
	data: #()

	_key: func [key][(any [key #__DEFAULT])]
		
	_get: func [key][data/(_key key)]
	_set: func [key][data/(_key key): now/time/precise]
	_clr: func [key][data/(_key key): none]
	
	set 'get-time-mark   func [/key k] [_get k]
	set 'set-time-mark   func [/key k] [_set k]
	set 'clear-time-mark func [/key k] [_clr k]
	
	set 'time-since-mark func [/key k] [
		if none? _get k [
			print ["##ERROR time-since-mark called for unknown key:" _key k]
			return none
		]
		now/time/precise - _get k
	]
]
;print time-since-mark
;set-time-mark
;print time-since-mark
;wait 1
;set-time-mark/key 'a
;wait 2
;print [time-since-mark  time-since-mark/key 'a]


true?: func [
	"Returns true if an expression can be used as true."
	value [any-type!]
][
	not not :value
]

;-------------------------------------------------------------------------------
;# Comparison

between?: func [
	"Returns TRUE if value is between the two boundaries (inclusive)"
	value
	bound1
	bound2
][
	all [
		value >= min bound1 bound2
		value <= max bound1 bound2
	]
]


compare: func [
	"Returns -1 if a < b, 1 if a > b, 0 if a = b"
	a b
][
	either a < b [-1][ either a > b [1][0] ]
]


longer-of: func [
	"Returns the longer of two series"
	a [series!] b [series!]
][
	get pick [a b] longer? a b
]
;pick-longer: :longer

longer?: func [
	"Returns true if A is longer than B"
	a [series!] b [series!]
][
	greater? length? a length? b
]
;more?:    :longer?
;more-in?: :longer?


shorter?: func [
	"Returns true if A is shorter than B"
	a [series!] b [series!]
][
	lesser? length? a length? b
]
;fewer?:   :shorter?
;less-in?: :shorter?

shorter-of: func [
	"Returns the shorter of two series"
	a [series!] b [series!]
][
	get pick [a b] shorter? a b
]
;pick-shorter: :shorter


;-------------------------------------------------------------------------------
;# Set predicates

disjoint?: func [
	"Returns true if A and B have no elements in common; false otherwise"
	a [series! bitset!]
	b [series! bitset!]
][
	empty? intersect a b
]

intersect?: func [
	"Returns true if A and B have at least one element in common; false otherwise"
	a [series! bitset!]
	b [series! bitset!]
][
	not empty? intersect a b
]

subset?: func [
	"Returns true if A is a subset of B; false otherwise"
	a [series! bitset!]
	b [series! bitset!]
][
	empty? exclude a b
]

superset?: func [
	"Returns true if A is a superset of B; false otherwise"
	a [series! bitset!]
	b [series! bitset!]
][
	subset? b a
]

;-------------------------------------------------------------------------------
;# Filespecs

at-suffix: function [
	"Returns a filespec at its suffix or tail"
	path [any-string!]
][
	any [find/last path suffix? path  tail path]
]

change-suffix: func [
	"Changes the suffix of a filespec and returns the new filespec"
	path   [any-string!] "(modified)"
	suffix [any-string!] "The new suffix"
][
	append remove-suffix path suffix
]

dir?: func [
	"Returns true if a filespec ends with a path marker"
	path [file! url!]
][
	true? find "/\" last path
]

dirize: func [
	"Returns a copy of a filespec with a trailing path marker"
	path [file! string! url!]
][
	path: copy path								; Always return a copy of the path.
	either slash = last path [path][append path slash]
]

file-of: func [
	"Returns the filename portion of a filespec"
	path [any-string!]
][
	second split-path path
]

path-of: func [
	"Returns the path portion of a filespec"
	path [any-string!]
][
	first split-path path
]

remove-suffix: func [
	"Removes the suffix from a filespec"
	path [any-string!] "(modified)"
][
	head clear at-suffix path
]

;!! Red has SPLIT-PATH now, so I'm not including one. I do have 
;	one, and notes and tests based on Ladislav's implementation 
;	where it holds that `file = rejoin split-path file`
; This does not match current Red behavior. It arguably 
; makes more sense, but will break R2 code in some cases.
; Ladislav's func only seems to go really wrong in the case
; of ending with a slash that's the only slash in the 
; value which return an empty path and entire filespec as 
; the target. Schemes (http://) don't work well either.

undirize: func [
	"Returns a copy of a filespec with no trailing path marker"
	path [file! string! url!]
][
	path: copy path								; Always return a copy of the path.
	if slash = last path [take/last path]
	path
]


;-------------------------------------------------------------------------------
;# Strings

ordinal-suffix: func [n [integer!]] [
	either find ["11" "12" "13"] copy skip tail form n -2 ["th"] [
		switch/default absolute (n // 10) [1 ["st"] 2 ["nd"] 3 ["rd"]] ["th"]
	]
]

as-ordinal: func [n [integer!]] [
	append form n ordinal-suffix n
]
;repeat i 24 [print as-ordinal i]


;-------------------------------------------------------------------------------
;# Functions

; We have other reflective functions (words-of, body-of, etc.), but
; this is a little higher level, sounded fun to do, and may prove
; useful as we write more Red tools. It also shows how to make your
; own typesets and use them when parsing.
arity-of: function [
	"Returns the fixed-part arity of a function spec"
	spec [any-function! block!]
	/with refs [refinement! block!] "Count one or more refinements, and add their arity"
][
	if any-function? :spec [spec: spec-of :spec]		; extract func specs to block
	t-w: make typeset! [word! get-word! lit-word!]		; typeset for words to count
	t-x: make typeset! [refinement! set-word!]			; typeset for breakpoint, set-word is for return:
	n: 0
	; Match our word typeset until we hit a breakpoint that indicates
	; the end of the fixed arity part of the spec. 'Skip ignores the
	; datatype and doc string parts of the spec.
	parse spec rule: [any [t-w (n: n + 1) | t-x break | skip]]
	; Do the same thing for each refinement they want to count the
	; args for. First match thru the refinement, then start counting.
	if with [foreach ref compose [(refs)] [parse spec [thru ref rule]]]
	n
]
;e.g. [
;	print arity-of :append
;	print arity-of/with :append /only
;	print arity-of/with :append /dup
;	print arity-of :load
;	print arity-of/with :load /as
;
;	test-fn: func [a b /c d /e f g /h i j k /local x y x return: [integer!]][]
;
;	print arity-of :test-fn
;	print arity-of/with :test-fn /c
;	print arity-of/with :test-fn /e
;	print arity-of/with :test-fn /h
;	print arity-of/with :test-fn [/c /e /h]
;
;	print arity-of :arity-of
;	print arity-of/with :arity-of /with
;]

;-------------------------------------------------------------------------------
;# Control

; Basic, forward-only forskip
;forskip: function [
;    "Evaluates a block at intervals in a series"
;    ;[throw catch]
;    'word [word!]    "Word set to each position in series (must refer to a series)"
;    size  [integer!] "Number of values to skip each time"
;    body  [block!]   "Block to evaluate each time"
;][
;	;TBD: Redish error handling.
;    if not positive? size [cause-error 'script 'invalid-arg [size]]
;    if not [series? get word] [
;    	cause-error 'script 'invalid-arg ["forskip expected word argument to refer to a series"]
;	]
;    orig: get word
;    ; This test is a little tricky at a glance. ANY will be satisified until
;    ; we hit the tail of the series. On each pass we move towards the tail.
;    ; Once we hit the tail, ANY will evaluate the paren in the test, which
;    ; resets the word to the original position in the series and returns
;    ; false, which causes WHILE to break.
;    while [any [not tail? get word (set word orig  false)]] [
;        set/any 'result do body
;        set word skip get word size
;        get/any 'result
;    ]
;]
; This forskip can go backwards as well
forskip: func [
	"Evaluates a block at regular intervals in a series"
	'word [word!]    "Word referring to the series to traverse (modified)"
	width [integer!] "Interval size (width of each skip)"
	body  [block!]   "Body to evaluate at each position"
	/local orig op result
][
	if zero? width [return none]

	;TBD: Redish error handling.
	if not [series? get word][
		cause-error 'script 'invalid-arg ["forskip expected word argument to refer to a series"]
	]
	; Store original position in series, so we can restore it.
	orig: get word
	; What is our "reached the end" test?
	op: either positive? width [:tail?][:head?]
	if all [negative? width  tail? get word][
		; We got a negative width, so we're going backwards, and we're at the
		; tail. That means we want to step back one interval to find the start
		; of the first "record".
		set word skip get word width
	]
	; This test is a little tricky at a glance. ANY will be satisified until
	; we hit the tail of the series. On each pass we move towards the tail.
	; Once we hit the tail, ANY will evaluate the paren in the test, which
	; resets the word to the original position in the series and returns
	; false, which causes WHILE to break.
	while [ any [not op get word (set word orig  false)] ][
		set/any 'result do body
		set word skip get word width
		get/any 'result
	]
	if all [
		negative? width
		divisible? subtract index? orig 1 width
		;?? check orig = get word for BREAK support?
	][
		; We got a negative width, so we're going backwards, and the above 
		; WHILE loop ended before processing the element at the head of the
		; series. Plus we reset the word to its original position, *and* we
		; would have landed right on the head. Because of all that, we want
		; to process the head element.
		set word head get word
		set/any 'result do body
		set word orig
	]
	get/any 'result

]
;e.g. [
;	b: [1 2 3 4 5 6]
;	forskip b 2 [print [b/1 b/2]]
;	forskip b 3 [print [b/1 b/2 b/3]]
;	forskip b 4 [print [b/1 b/2 b/3 b/4]]
;	forskip b 4 [print [b/1 b/2 break b/3 b/4]]
;	tbb: back tb: tail blk: [1 2 3 4 5 6]
;	forskip blk 2 [print mold blk]
;	forskip tb -2 [print mold tb]
;	forskip tbb -2 [print mold tbb]
;]

;-------------------------------------------------------------------------------
;# Higher-Order Functions (HOFs)

; Should args come first? That's the normal series-first model, but 
; also backwards from normal func call order, which may be confusing.
apply: func [
	"Apply a function to a block of arguments."
	fn  [any-function!] "Function to apply"
	args [block!] "Arguments for function"
	/only "Use arg values as-is, do not reduce the block"
][
	; Renaud Gombert's simple approach. There is a reason Brian Hawley's
	; R2 version is so complex. The question is whether the complexity 
	; is justified. It may very well be, but this is soooo Redbolish.
	args: either only [copy args][reduce args]
	do head insert args :fn
]

filter: function [
	"Returns two blocks: items that pass the test, and those that don't"
	series [series!]
	test [any-function!] "Test (predicate) to perform on each value; must take one arg"
	/only "Return a single block of values that pass the test"
][
	;TBD: Is it worth optimizing to avoid collecting values we won't need to return?
	either only [
		collect [foreach value series [if test :value [keep/only :value]]]
	][
		; First block is values that pass the test, second for those that fail.
		result: reduce [copy [] copy []]
		foreach value series [
			; Coercing the result of the test to logic! lets us safely
			; use it with PICK, where true picks the first item, and
			; false the second.
			append/only pick result make logic! test :value :value
		]
		result
	]
]
e.g. [
	filter [1 2 3 4 5 6 7] :even?
	filter [1 2 3 4 5 6 7] :odd?
	filter/only [1 2 3 4 5 6 7] :odd?
	filter [/only /dup 3] :refinement?
]

keep-each: func [
	"Keeps only values from a series where body block returns TRUE."
	'word [get-word! word! block!] "Word or block of words to set each time (will be local)"
	data  [series!]
	body  [block!] "Block to evaluate; return TRUE to collect"
][
	remove-each :word data compose [not do (body)]
]

map-each: function [
	"Evaluates body for each value in a series, returning all results."
	'word [word! block!] "Word, or words, to set on each iteration"
	data [series!] ; map!
	body [block!]
	/local tmp
][
	collect [
		foreach :word data [
			; @dockimbel said it should return a block of the same size
			; as the input, but there is no hard decision on whether 
			; unset results should be returned as NONE. They are different,
			; as unset! is treated as a truthy value.
			; Supporting unset! results means COLLECT's KEEP func has to
			; be modded to allow any-type! in its spec.
			if not unset? set/any 'tmp do body [keep/only :tmp]
			;keep/only either unset? set/any 'tmp do body [none][:tmp]
			;keep/only do body
		]
	]
]

use: func [
	"Defines words local to a block evaluation."
	vars [block!] "Words local to the block"
	body [block!] "Block to evaluate"
][
	; R3: apply make closure! reduce [to block! vars copy/deep body] []
	; Renaud Gombert's simple approach
	do has vars body
]


;-------------------------------------------------------------------------------
;# Series

array: function [
	"Makes and initializes a block of of values (NONE by default)"
	size [integer! block!] "Size or block of sizes for each dimension"
	/initial "Specify an initial value for elements"
		value "For each item: called if a func, deep copied if a series"
][
	if block? size [
		if tail? more-sizes: next size [more-sizes: none]
		size: first size
		if not integer? size [
			; throw error, integer expected
			cause-error 'script 'expect-arg reduce ['array 'size type? get/any 'size]
		]
	]
	result: make block! size
	case [
		block? more-sizes [
			loop size [append/only result array/initial more-sizes :value]
		]
		series? :value [
			loop size [append/only result copy/deep value]
		]
		any-function? :value [
			loop size [append/only result value]
		]
		'else [
			append/dup result value size
		]
	]
	result
]
;e.g. [
;	array 3
;	array [2 3]
;	array [2 3 4]
;	array/initial 3 0
;	array/initial 3 does ['x]
;]

binary-search: function [
	"Returns the index where a value is (success), or the index of the insertion point as a negative offset (not found)"
	series [series!]    "Pre-sorted series"
	value               "Value to find"
][
	if empty? series [return none]

	low: 1
	high: length? series
	
	while [low <= high] [
		; Normally I would just use ROUND, but this is one place we do
		; care about performance, because this func could get called a
		; lot depending on the application.
		;mid: round/down low + (high - low / 2)
		mid: to integer! low + (high - low / 2)
		; Pick is faster than path syntax, and just as clear here.
		cmp-val: pick series mid
		either cmp-val = value [return mid] [
			either cmp-val < value [low: mid + 1] [high: mid - 1]
		]
	]
	negate low
]
e.g. [
	binary-search [1 2 3 4 5 6] 4
	binary-search [1 2 3 4 5 6] 7
	binary-search [1 2 3 4 5 6] 0
]

collect-values: func [
	"Collect values in a block, by datatype or custom parse rule"
	block [block!]
	rule  "Datatype, prototype value, or parse rule"
	/deep "Include nested blocks"
	/local top-rule v
][
	rule: switch/default type?/word rule [
		datatype! [reduce [rule]]					; Turn a plain datatype into a parse rule for that type.
		block! typeset! [rule]						; Blocks and typesets (e.g. any-word!) work directly as rules.
	][ reduce [type? rule] ]						; Turn a prototype value into a rule for that value's type.

	; If they didn't spec /deep, any-block! skips nested blocks.
	; /deep does *not* look into nested path or string values.
	;!! We need good examples for `parse into` and its limitations.
	deep: either deep [
		[any-path! | any-string! | into top-rule]	; Don't parse into nested paths or strings
	][any-block!]									; any-block! skips nested blocks

	collect [
		parse block top-rule: [
			any [set v rule (keep/only v) | deep | skip]
		]
	]
]
;e.g. [
;	blk: [1 a 2 'b 3 c: 4 :d [a 'b c: :d  E 'F G: :H]]
;	print mold collect-values blk any-word!
;	print mold collect-values/deep blk any-word!
;	print mold collect-values blk set-word! 
;	print mold collect-values blk [set-word! | get-word!]
;	print mold collect-values/deep blk [set-word! | get-word!]
;	print mold collect-values/deep blk first [a:]
;	print mold collect-values/deep blk integer!
;	blk: [a/b/c 'j/k/l x/y/z: [d/e/f 'g/h/i t/u/v:]]
;	print mold collect-values blk path!
;	print mold collect-values blk lit-path!
;	print mold collect-values blk set-path!
;	print mold collect-values/deep blk path!
;	print mold collect-values/deep blk lit-path!
;	print mold collect-values/deep blk set-path!
;	blk: [[a] [b] (c) [[d] (e) ([f])]]
;	print mold collect-values blk block!
;	print mold collect-values/deep blk block!
;	print mold collect-values blk paren!
;	print mold collect-values blk first [()]
;	print mold collect-values/deep blk paren!
;	print mold collect-values blk any-block!
;	blk: [1 2.0 "b" %file a 3x3 [4.4.4.4 #5 50%]]
;	print mold collect-values blk [number! | tuple!]
;	print mold collect-values/deep blk [number! | tuple!]
;]

collect-words: function [
	"Collect words used in a block"
	block [block!]
	/deep "Include nested blocks"
	/set  "Collect set-words only"
][
	word-rule: either set [set-word!][any-word!]
	unique either deep [
		collect-values/deep block word-rule
	][
		collect-values block word-rule
	]
]
;e.g. [
;	blk: [1 a 2 'b 3 c: 4 :d [a 'b c: :d  E 'F G: :H]]
;	print mold collect-words blk
;	print mold collect-words/deep blk
;	print mold collect-words/set blk
;	print mold collect-words/deep/set blk
;]

dup: function [									; dupe dupl
	"Returns a new block with the fill value duplicated n times."
	fill
	count [integer!] "Negative numbers are treated as zero"
	/string "Return a string instead of a block"
	;?? would /str be better as the refinement name?
][
	append/dup copy either string [ "" ][ [] ] fill count
]

gather: function [
	"Gather the specified values from each item in the block"
	block [block!] "Block of items to gather data from"
	keys           "One or more indexes or keys to gather"
	/only          "Insert results as sub-blocks"
][
	keys: compose [(keys)]						; blockify keys for consistent iteration
	collect [
		foreach item block [
			vals: collect [
				foreach key keys [keep/only item/:key]
			]
			either only [keep/only vals] [keep vals]
		]
	]
]
e.g. [
	blk: [[1 2 3] [4 5 6] [7 8 9]]
	gather blk [1 3]
	gather/only blk [1 3]
	gather blk 2

	blk: reduce [object [x: y: z: none] object [x: 1 y: 2 z: 3]]
	gather blk [x z]
	gather/only blk [x z]
	gather blk 'y

	blk: reduce [#(a: 1 b: 2 c: 3) #(x: 4 y: 5 z: 6) #(a: 1 b: 22 z: 33)]
	gather blk [a z]
	gather/only blk [a z]
	gather blk 'b

]

join: func [
	"Concatenates values."
	value "Base value"
	rest  "Value or block of values"
][
	value: either series? :value [copy value] [form :value]
	repend value :rest
]

split-parts: function [
	"Split a series into variable size pieces"
	series [series!] "The series to split"
	sizes  [block!]  "Must contain only integers; negative values mean ignore that part"
][
	if not parse sizes [some integer!][ cause-error 'script 'invalid-arg [sizes] ]
	map-each len sizes [
		either positive? len [
			copy/part series series: skip series len
		][
			series: skip series negate len
			()										;-- return unset so that nothing is added to output
		]
	]
]
e.g. [
	blk: [a b c d e f g h i j k]
	split-parts blk [1 2 3]
	split-parts blk [1 -2 3]
	split-parts blk [1 -2 3 10]
]

;-------------------------------------------------------------------------------

starts-with?: func [							; head-is? begins-with?
	series	[series!]
	value
	/only
][
	;!! This scalar test is an optimization. Need to profile and weigh the gain.
	either scalar? value [ value = first series ][
		;!! A `refine` func would be nice here.
		make logic! either only [ find/match/only series value ][ find/match series value ]
	]
]
;e.g. [
;	starts-with? {"A"} #"^""
;	starts-with? {--A--} "--"
;	starts-with? {-+A+-} "-+"
;	starts-with? {[AAA]} "["
;	starts-with? {-->A->|} '-->
;	starts-with? [--> A ->| ] '-->
;	starts-with? first [(--> A ->|)] '-->
;	starts-with? '--/A/| '--
;	starts-with? #{FFEEDDCC} #{FF}
;]
	
ends-with?: function [							; tail-is?
	series	[series!]
	value
	/only
][
	;!! This scalar test is an optimization. Need to profile and weigh the gain.
	either scalar? value [ value = last series ][
		;!! A `refine` func would be nice here.
		pos: either only [
			find/last/tail/only series value
		][
			find/last/tail series value
		]
		either pos [ tail? pos ][ false ]
	]
]
;e.g. [
;	ends-with? {"A"} #"^""
;	ends-with? {--A--} "--"
;	ends-with? {-+A+-} "+-"
;	ends-with? {[AAA]} "]"
;	ends-with? {-->A->|} '->|
;	ends-with? {-->->|} '->|
;	ends-with? [--> A ->| ] '-->
;	ends-with? first [(--> A ->|)] '->|
;	ends-with? '--/A/| '|
;	ends-with? #{FFEEDDCC} #{CC}
;]

;?? Should the ensure* funcs alway COPY?

ensure-starts-with: func [						; ensure-head-is
	series	[series!] "(modified)"
	value
	/only
][
	either only [
		either starts-with? series value [ series ][ head insert series value ]
	][
		either starts-with?/only series value [ series ][ head insert/only series value ]
	]
]
;e.g. [
;	ensure-starts-with "A" "-->"
;	ensure-starts-with [A] '-->
;	ensure-starts-with first [(A)] '-->
;	ensure-starts-with 'a/b '-->
;	ensure-starts-with #{00000000} #{FF}
;]

ensure-ends-with: func [						; ensure-tail-is
	series	[series!] "(modified)"
	value
	/only
][
	either only [
		either ends-with? series value [ series ][ append series value ]
	][
		either ends-with?/only series value [ series ][ append/only series value ]
	]
]
;e.g. [
;	ensure-ends-with "A" "-->"
;	ensure-ends-with [A] '-->
;	ensure-ends-with first [(A)] '-->
;	ensure-ends-with 'a/b '-->
;	ensure-ends-with #{00000000} #{FF}
;]


enclose: func [
	"Returns a copy of the series with leading and trailing values added"
	series	[series!]
	values
	/local a b
][
	;rejoin either immediate? values [ [values series values] ][	; A single value gets used at both ends
	;	[first values  series  last values]
	;]
	either any [immediate? values  binary? values][ set [a b] values ][
		a: first values  b: last values
	]
	series: either series? series [ copy series ][ form series ]
	append head insert series a b
]
;enbrace:   func [s] [enclose s "{}"]
;enbracket: func [s] [enclose s "[]"]
;enparen:   func [s] [enclose s "()"]
enquote:   func [s] [enclose s #"^""]
;entag:     func [s] [enclose s "<>"]

;e.g. [
;	enclose "A" "[]"
;	enclose "A" #"^""
;	enclose [A] '..
;	enclose [A] '-->
;	enclose [A] ['<-- '-->]
;	enclose [A] [|-- (--|)]
;	enclose first [(A)] '..
;	enclose 'a/b/c '--
;	enclose 'a/b/c ['<-- '-->]
;	enclose #{0000} #{FF}
;	enclose #{0000} #{FFEE}
;	enclose #{0000} [#{FF} #{EE}]
;]

enclosed?: func [
	"Returns true if a series begins and ends with leading and trailing values"
	series	[series!]
	values
	/local a b
][
	either immediate? values [ set [a b] values ][ a: first values  b: last values ]
	make logic! all [starts-with? series a  ends-with? series b]
]
;e.g. [
;	; Passing tests
;	enclosed? {"A"} #"^""
;	enclosed? {--A--} "--"
;	enclosed? {-+A+-} ["-+" "+-"]
;	enclosed? {[AAA]} "[]"
;	enclosed? {-->A->|} [--> ->|]
;	enclosed? {-->->|} [--> ->|]
;	enclosed? [--> a b  c |] [--> |]
;	enclosed? first [(--> a b  c |)] [--> |]
;	enclosed? '--/b/c/-- '--
;	enclosed? '--/b/c/| [-- |]
;	enclosed? #{FF0000FF} #{FF}
;	; Intentionally failing tests
;	enclosed? {"A"} #"'"
;	enclosed? {--A--} "__"
;	enclosed? {-+A-} ["-+" "+-"]
;	enclosed? {[AAA)} "[]"
;	enclosed? {-->A->} [--> ->|]
;	enclosed? {-->>|} [--> ->|]
;]

;-------------------------------------------------------------------------------
;# Objects

;http://www.rebol.net/cgi-bin/r3blog.r?view=0241#comments
clone: function [
	"Deep make an object"
	object [object!]
	/with
		spec [block!] "Extra spec to apply"
][
	cloners!: union series! make typeset! [object! map! bitset!]
	new: make object any [spec clear []]
	foreach word words-of new [
		val: get in new word
		if find cloners! type? :val [
			new/:word: either object? val [ clone val ][ copy/deep val ]
		]
	]
	new
]

e.g. [
	o1: object [n: 1 a: "A" b: #() sub-o: object [aa: "AA" bb: #()] fn: func [x][x]]
	o2: clone o1
	append o2/a "a"
	append o2/sub-o/aa "aa"
	o2/b/c: #c
	o2/sub-o/bb/c: #cc
	append body-of get in o2 'fn [ensure x]
	?? o1
	?? o2
]

