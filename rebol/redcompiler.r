;; ===================================================
;; Script: redcompiler.r
;; downloaded from: www.REBOL.org
;; on: 14-May-2017
;; at: 9:09:49.630645 UTC
;; owner: arnold [script library member who can update
;; this script]
;; ===================================================
REBOL [
    Title: "Red compiler and Runner"
    File: %redcompiler.r
    Date: 05-Dec-2012
    Author: ["Arnold van Hofwegen"]
    Purpose: "GUI to help with compile and run your Red(/System) scripts."
    Comment: {
         29-Nov-2012 Mods and comments by Gregg Irwin.
         04-Dec-2012 Added check for red.r in the directory by Arnold
                     Added --red-only compile option by Arnold
                     Added Help screen by Arnold
         05-Dec-2012 Removed redundant comments by Arnold
                     Added preliminary support for CGI compile by Arnold
    }
]

;*******************************************************************************
; This script provides a GUI for compiling Red(/System) scripts.
; How to use this script?
; Select the map red-system for the directory
; Select your script (in the tests directory).
; Hit compile and hope for the best.
; When your script compiles run it as usual on your system. 
; if not, learn to type unview/all and reset your directory.
;*******************************************************************************
; Compilation information, how the commandline interface works.
;-------------------------------------------------------------------------------
; Normal compile
; Example:
; do/args %red.r "%tests/hello.red"
; do/args %rsc.r "%tests/hello.reds"
;------------------------------------------------------------------------------
; Cross compiling
;     Target ID	   Description
;     MSDOS        Windows, x86, console-only applications
;     Windows      Windows, x86, native applications
;     Linux        GNU/Linux, x86
;     Linux-ARM    GNU/Linux, ARMv5
;     Darwin       Mac OS X Intel, console-only applications
;     Syllable     Syllable OS, x86
;     Android      Android, ARMv5
; Examples:
; From Windows, to emit Linux executables:
; do/args %rsc.r "-t Linux %tests/hello.reds"
; From Linux, to emit Windows console executables:
; do/args %rsc.r "-t MSDOS %tests/hello.reds"
;------------------------------------------------------------------------------
; Verbose compiling
; The verbose level (1-3) will allow you to display the output of 
; Red code compilation with the following informations:
; -v 1 => Red global user code compilation result
; -v 2 => (1) + functions compilation result
; -v 3 => (2) + boot.red script compilation result
;             + symbol table loading code
;             + literal series construction code
; Example:
; do/args %rsc.r "-v 3 %tests/hello.reds"
;------------------------------------------------------------------------------
; Only first pass on Red source code (Granted wish #327)
; For running only the first pass on Red source code, 
; use --red-only option on command-line.
; Example:
; do/args %red.r "-v 1 --red-only %red/tests/demo.red"
;------------------------------------------------------------------------------
; Wishes: 
; - Produce a .cgi file after choosing compiling for CGI purposes.
; - Make platform choices check boxes, so you can build all easily.
;------------------------------------------------------------------------------

;-- Generic funcs
enclose: func [s vals][rejoin [(first vals) s (last vals)]]
;bracket: func [s][enclose s "[]"]
;parenthesize: func [s][enclose s "()"]
enquote: func [s][enclose s {"}]    ;-- "

;--
; Function
;--
compile-script: has [script compiler compile-string] [

    show-status "Compiling..."
 
    script: copy find/match selected-script selected-red-dir

    compiler: either %.reds = suffix? script [%rsc.r] [%red.r]
    if compiler = %rsc.r [
        replace script "red-system/" ""
    ]
    
    compile-string: reform [
        reform either compile-verbose? [["-v" verbosity-level]] [""]
        reform either cross-compile?   [["-t" cross-target-platform]] [""]
        reform either redonly-compile? ["--red-only"][""]
        script
    ]
    
    show-status reform ["Last Command:" mold compiler mold compile-string]
    
    either red-dir [
        do/args compiler compile-string
    ][
        alert "You didn't select a directory with the compile script %red.r in it. No compilation possible."
    ]
]

; Break the target platform value away from the UI element.
cross-target-platform: "Linux" ; Linux is the Default

set-target-platform: func [
    str [string!] "Command line platform name"
][
    cross-target-platform: str
]

; Helper funcs, show intent. 
compile-verbose?: does [get-face chk-verbose]

cross-compile?:   does [get-face chk-cross]

redonly-compile?: does [get-face chk-redonly]

selected-red-dir: does [get-face txt-red-dir]

selected-script:  does [get-face txt-red-script]

show-status: func [str] [set-face f-status str]

verbosity-level:  does [get-face chc-verbose]

;cgi-compile?:     does [get-face chk-cgi]

; Button actions
action-help: func [] [
    inform layout red-compiler-help-def
]

;**********************************************************
; Layout(s) application screens
;**********************************************************
; Help information screen
red-compiler-help-def: [
    origin 2x2
    ;size 400x100
    backdrop ivory
    ;backcolor white
    across
    H2 "Compilation information."
    return
    H3 "How the GUI interface works with the commandline."
    return
    H3 "Normal compile"
    return
    text as-is
{The GUI tests whether the compilation is for a Red script 
or a Red/System script by testing the extension.
Example:
    do/args %red.r "%tests/hello.red"
    do/args %rsc.r "%tests/hello.reds"}
    return
    H3 "Cross compile"
    return
    text as-is
{Table:
    Target ID    Description                                 
    MSDOS        Windows, x86, console-only applications     
    Windows      Windows, x86, native applications           
    Linux        GNU/Linux, x86                              
    Linux-ARM    GNU/Linux, ARMv5                            
    Darwin       Mac OS X Intel, console-only applications   
    Syllable     Syllable OS, x86                            
    Android      Android, ARMv5                              
}
    return
    text as-is
{Examples:
    From Windows, to emit Linux executables:
    do/args %rsc.r "-t Linux %tests/hello.reds"
    From Linux, to emit Windows console executables:
    do/args %rsc.r "-t MSDOS %tests/hello.reds"}
    return
    H3 "Verbose compile"
    return
    text as-is
{The verbose level (1-3) will allow you to display the output of 
Red code compilation with the following informations:
  -v 1 => Red global user code compilation result
  -v 2 => (1) + functions compilation result
  -v 3 => (2) + boot.red script compilation result
              + symbol table loading code
              + literal series construction code
Example:
    do/args %rsc.r "-v 3 %tests/hello.reds"}
    return
    H3 "First pass Red code only compile"
    return
    text as-is
{For running only the first pass on Red source code, 
the --red-only option is used.
Example:
    do/args %red.r "-v 1 --red-only %red/tests/demo.red"}
    return
    text as-is
{Compiling using this option disables cross compilation 
and vice versa.}
    return
    text " "
]

; The RADIO-LINE and CHECK-LINE group the glyph and text together, 
; instead of using RADIO/CHECK and TEXT separately.
stylize/master [
    platform-option: radio-line 125 'crosstype [set-target-platform face/user-data]
]

; Not using LAYOUT here, just defining the block.
cross-comp-panel-def: [
    origin 2x2
    size 400x100
    backcolor white
    across
    ;** Think about what the best layout is for platform selection.
    ;** TBD Save the platform for future builds of the same script.
    ;** TBD Make platform choices check boxes, so you can build all easily.
    ;**     That means changing set-target-platform and reading that value.
    platform-option "Windows"         user-data "Windows"
    platform-option "Windows Console" user-data "MSDOS"
    platform-option "Syllable"        user-data "Syllable"
    return
    platform-option "OS X"         user-data "Darwin"  ; Not in effect at this time
    platform-option "OS X Console" user-data "Darwin"
    platform-option "Android"      user-data "Android"
    return    
    platform-option "Linux"        user-data "Linux"      true ; default option
    platform-option "Linux-ARM"    user-data "Linux-Arm"
    ;platform-option "Linux/CGI"    user-data "Linux/CGI"
]
 
main: layout [
    origin 20x20
	below
	btn-request-dir: button 300 "Where is your Red directory?" [
	    set-face txt-red-dir request-dir "Select your Red directory" 
	    change-dir txt-red-dir/text 
	    red-dir: exists? to-file rejoin [txt-red-dir/text "red.r"]
	]
	txt-red-dir-here: text 300 " Your Red(/System) scripts are in:"
	txt-red-dir: text 500 " Please choose the directory " 
	btn-request-file: button 300 "Which Red(/System) script to compile?" [
	    set-face txt-red-script request-file/only "Select your Red script" 
	]
	txt-red-script: text 600 " Please give the script to compile " 
	across
    chk-redonly: check-line "Compile First pass Red source only (no cross compile)" [
        if  cross-compile? [chk-cross/data: false hide cross-comp-panel]
        show chk-cross
    ]
	return
    chk-verbose: check-line "Compile using verbose mode"
    chc-verbose: choice "1" "2" "3" ;"4" "5" "6" "7" "8" "9" "10"
	return
	chk-cross: check-line "Cross-compile" [
	    either cross-compile? [
	        show cross-comp-panel
	        chk-redonly/data: false
	        show chk-redonly
	    ][
	        hide cross-comp-panel
	    ]
    ]
	cross-comp-panel: panel cross-comp-panel-def with [show?: false]

	return
	;chk-cgi: check-line "Compile to use as CGI program"
	;return
	btn-compile: button "Compile" #"^e" [compile-script] 
	btn-help: button "Help" [action-help]
	;btn-quit: button "Halt" [halt]
	btn-restart: button "Restart" [change-dir save-dir unview/all do %redcompiler.r]
	btn-quit: button "Quit" #"^q" [change-dir save-dir unview/all]
	return
	f-status: text 600
] 

;**********************************************************
; The program
;**********************************************************
save-dir: what-dir
red-dir: false

view main

change-dir save-dir