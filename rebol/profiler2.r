### USE CASE 
#	date: 19/05/2016
#	system: Ubuntu 64 + wine 32 bits, Proc intel i5

# Replace the file %red-master/system/utils/profiler.r
#   by the current file
# Edit the file %red-master/system/compiler.r
#   and change the line ~11 to "profiler/active?: yes""
# Open a rebol2 console and compile the red's console

REBOL/View 2.7.8.3.1 1-Jan-2011
Copyright 2000-2011 REBOL Technologies.  All rights reserved.
REBOL is a trademark of REBOL Technologies. WWW.REBOL.COM

>> do/args %red.r "%environment/console/console.red"'

-=== Red Compiler 0.6.0 ===-

Compiling /red-master/environment/console/console.red ...
...compilation time : 862 ms

Compiling to native code...
...compilation time : 106346 ms
...linking time     : 239 ms
...output file size : 446256 bytes
...output file      : \red-master\console.exe

>> profiler/report

Function                       Count      Elapsed Time         % of ET
------------------------------------------------------------------------
compile                        1          0:01:46.585          100.0 %
 < <root>                       1
  > init                         1                 6 ms            0.00 %
  > init                         1                 6 ms            0.00 %
  > process                      1                92 ms            0.08 %
  > run                          1              2.52 sec           2.37 %
  > finalize                     1           0:01:26              80.87 %
  > set-verbose-level            5                 0 ms             0.0 %
  > output-logs                  1                 0 ms             0.0 %
  > emit-main-prolog             1                 0 ms             0.0 %
  > comp-start                   1                50 ms            0.04 %
  > comp-runtime-prolog          1              8.99 sec           8.43 %
  > comp-runtime-epilog          1                 0 ms             0.0 %
  > clean-up                     2                 0 ms             0.0 %
  > make-job                     1                 0 ms             0.0 %

comp-dialect                   1444       0:01:37.225          91.21 %
 < comp-func-body               1372
 < fetch-into                   67
 < run                          5
  > pop-calls                    15297           104 ms            0.09 %
  > fetch-func                   1372           1.54 sec           1.45 %
  > comp-directive               295             281 ms            0.26 %
  > comp-alias                   73               14 ms            0.01 %
  > fetch-expression             13557         15.30 sec          14.36 %
...

REBOL [
	Title:   "REBOL code profiling tool"
	Author:  ["Nenad Rakocevic" "Steeve Antoine"]
	File: 	 %profiler.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	changes: [
		"18/05/2016 - caller/callee stats, /per-unit experimentation"
	]
	TODO: ["Show if a function is recursive"]
	Usage: {
		1) Include it in your existing application:
		
				do %<path-to>/profiler.r
				profiler/set-active yes					;-- switches function patching on/off
		
		2) The profiler needs an object as input to patch all object's functions
		   for profiling using the 'make-profilable function:
		   
		   		my-app: make-profilable context [...]
		   		
		3) Run your application as usual.
		
		4) Print profiling report (from console or included in your app code):
		
				profiler/report
		   
		   You get a table with all profiled functions, calls count and elasped time.
		   
		   Following a function:
		   	 Prefixed lines with '<' denotes a caller.
		   	 Prefixed lines with '>' denotes a callee (called function).
		   	 A callee gets a fractionnal elapsed time of its total duration
		 		which may be skewed if the callee is recursive (not detected).

		   By default, only the top 20 functions are reported, to print them all:
		   
		   		profiler/report/all
		   		
		   To sort results by count instead of elapsed time:
		   
		   		profiler/report/count
		   		profiler/report/all/count
		 
		 5) The profiler needs a fresh start for each run (stats clearing
		    has not been implemented yet, any taker?)
		    
		   
		 Hope it will help you improve your apps!
	}
	Example: {
		REBOL []
		
		do %profiler.r
		profiler/set-active yes		;-- just change it to NO for normal execution
		
		a: make-profilable context [
			foo: func [a /ref][wait (random 10) / 100 bar a + 1]
			bar: func [b][wait (random 10) / 100 b * 1 + 1 - 1]
			
			run: has [c][
				c: 0
				foreach i [1 2 3 4 5 6 7 8 9 0][
					c: c + foo i
					c: c + bar i
				]
				print c
			]
		]
		
		a/run
		profiler/report
		
		halt
	}
]

exportable: context [
	export: func [words [block!]][						;-- export argument words to global context
		foreach w words [set bind w system/words get :w]
	]
]

profiler: make exportable [

	;-- storage place for proxified functions
	store: make block! 400

	;-- property use to enable/disable the profiler without changing anything else
	active?: yes
	
	;-- temporary stack for nested objects used by 'make-profilable
	obj-stack: make block! 1
	
	;-- Stack to register caller->callee call counts
	call-stack: append make block! 50 [<root>]
	
	clean: func [spec [block!]][
		;-- remove everything we don't need in function's spec block
		remove-each item spec [
			not find [word! refinement! get-word! lit-word!] type?/word item
		]
		;-- remove all local variables
		clear find spec /local
		
		;-- duplicate all refinements in spec, by adding a word! version 
		;-- just after the refinement! value (refinements have no binding)
		forall spec [
			if refinement? spec/1 [
				insert at spec 2 to word! spec/1
				spec: next spec
			]
		]
		spec
	]

	upd-callers: func [blk /tmp][
		poke tmp: any [
				find/tail blk pick call-stack 1
				back insert tail blk reduce [pick call-stack 1 0]
		] 1 tmp/1 + 1
	]

	proxify: func [
		fun [function!] name 
		/local parms specs args patch
	][
		specs: head clear any [
			find copy third :fun /local
			tail copy third :fun
		]
		
		parms: copy args: copy first :fun
		clear find args /local
		args: map-each w args [to get-word! w]
		parms: map-each w parms [either w = /local [w][to word! w]]
		
		fun: make function! specs append reduce [
			make function! parms copy/deep second :fun 
		] args 
		
		;-- patch the code body of the new func
		;-- no collisions with the func parameters or locals
		patch: use [
			res depth count duration start name*
		] copy/deep [
			name*: name
			duration: 0:0
			count: depth: 0
			[ 
			;-- store stats in literal local block (call depth, calls count, time)
			# [depth count duration]
			
			;-- store a list of callers (caller, calls count, ...)
			upd-callers [] 

			;-- increment calls count
			count: count + 1		

			;-- increase depth counter before the function call
			depth: depth + 1
			
			;-- push func name in call stack
			insert call-stack name*
			
			;-- mark start time, if not recursive call
			if depth = 1 [start: now/time/precise]
			
			;-- invoke the original function, passing all required arguments and refinements
			error? set/any 'res try [] ;<- empty block filled with invoked func
			
			;-- pop func name from call stack
			remove call-stack
			
			;-- if recursive call (depth > 1), don't add the time
			if depth = 1 [duration: duration + now/time/precise - start]

			;-- function call done so decrease depth counter
			depth: depth - 1
			
			;-- return invoked function last value
			get/any 'res
		]]
		insert select patch 'try second :fun
		clear insert second :fun patch
		:fun
	]
	
	set-active: func [
		"Enable or disable the patching of functions"
		mode [logic!]
	][
		active?: mode
	]
	
	make-profilable: func [
		"Make all functions in a given object usable for profiling"
		obj [object!]
		/all "Apply to nested objects too (use with caution)"
		/local
			value new
	][
		unless active? [return obj]
		
		foreach word next first obj [
			if function? value: get in obj word [
				unless find store :value [
					set in obj word new: proxify :value word	;-- install profiler proxy function			
					repend store [:value word obj second :new]
				]
			]
			if system/words/all [
				all
				object? :value
				not find obj-stack :value
			][
				append obj-stack :value
				make-profilable :value
				remove back tail obj-stack
			]
		]
		obj												;-- just a pass-thru
	]
	
	align: func [str [string!] cols [integer!] /right][
		head insert/dup either right [str][tail str] #" " cols - length? str
	]
	
	truncate: func [value [number!]][
		if integer? value [return value]
		value: mold value
		head clear skip find value #"." 3
	]
	
	form-time: func [time [time!]][
		case [
			zero? to integer! time [
				align/right join form to integer! 1000 * to decimal! time " ms " 11
			]
			zero? time/minute [
				align/right join truncate to decimal! time " sec" 11
			] 
			on [join form to time! to integer! time "    "]
		]
	]
	
	base: make block! 100
	cross: make block! 200 ;-- cross-references
	
	print-table: func [
		data [block!] root [function! none!] 
		/local ET line percent cnt-tot
	][
		ET: any [all [:root third second second :root ] data/3]
		ET: to decimal! ET
		percent: func [time][
			truncate (to decimal! time) / ET * 100
		]
		
		print [
			newline
			align "Function" 	 30
			align "Count" 		 10
			align "Elapsed Time" 20
			align "% of ET" 	 10
			newline
			line: head insert/dup make string! 72 #"-" 72
		]
		foreach [name cnt time caller] data [
			print [
				align mold name 30
				align mold cnt 10
				align mold time 20
				align/right percent time 5	#"%"
			]
			sort/reverse/compare/skip caller 2 2
			foreach [name cnt] caller [
				print [
					align join " < " mold name 31
					align mold cnt 10 
				]
			]
			foreach [callee cnt] any [select cross name []] [
				set [cnt-tot time] select/skip base callee 4
				print [
					align join "  > " mold callee 32
					align mold cnt 10
					""	;-- here, time and percent are average estimations
					align form-time time: time * (cnt / cnt-tot) 20
					align/right percent time 5	#"%"
				]
			]
		print ""
		]
		print [line newline]
	]
	
	report: func [
		"Print a full pretty-printed report in console"
		/only "Report only for selected object"
			object [object!]
		/all  "Print report for all functions"
		/with "Provide a root function for % of ET calculation"
			root [function!]
		/count "Sort report table by calls count"
		/per-unit "per-unit elapsed time (time / count)"
		/local cnt time callers _ data
	][
		unless active? [exit]
		
		clear base
		clear cross
		
		foreach [old name obj body] store [
			if any [not only obj = object][
				set [_ cnt time] reduce body/2
				callers: body/4
				repend base [
					name	 
					cnt									;-- call count 
					either per-unit [
						time / either cnt > 0 [cnt][1] 	;-- elapsed time per call unit
					][time]
					callers								;-- callers count block!
				]
				sort/skip/compare/reverse any [
					foreach [caller count] callers [
						repend any [
							select cross caller 
							pick insert tail cross reduce [caller make block! 2] -1
						][
							name count
						]	
					]
					[]
				] 2	2
			]
		]
		sort/skip/compare/reverse base 4 pick [2 3] to logic! count
		data: either all [base][copy/part base 4 * 20]		;-- top 20 only by default
		
		print-table data :root
	]
	
	export [make-profilable]
]

; profiler: make-profilable profiler					;-- include profiler's code in profiling