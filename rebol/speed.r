REBOL [
	Title: "REBOL Quick and Dirty Speed Test"
	Author: "Carl Sassenrath"
	Name: 'speed-test
	Version: 1.3.0
	Purpose: "For comparing machines running REBOL"
]

print "Running..."

;-- Time console writes:
recycle
t1: now/precise
loop 100 [
	loop 72 [prin #"."]
	loop 72 [prin #"^(back)"]
]
print newline
t2: now/precise
d: difference t2 t1
sp: to-integer 100 * 72 * 72 / d/3 / 1024
print ["Console:  " d "-" sp "KC/S"]

;-- Time CPU loop:
recycle
t1: now/precise
loop 1'000'000 [tail? next "x"]
t2: now/precise
d: difference t2 t1
sp: to-integer 1.44 / d/3 * 600
print ["Processor:" d "-" sp "RHz (REBOL-Hertz)"]

;-- Time memory access:
mem: make binary! 500'000
recycle
t1: now/precise
repeat n 100 [
    c: either system/version > 2.100.0 [n][to-char n]
	change/dup mem c 500'000
]
t2: now/precise
d: difference t2 t1
sp: to-integer 100 * 500'000 / d/3 / 1024 / 1024
print ["Memory:   " d "-" sp "MB/S"]

;-- Time disk/filesystem speed:
write %junk.txt "" ; force security request before timer
buf: head insert/dup "" "test^/" 32000
recycle
t1: now/precise
either system/version > 2.100.0 [
	loop 100 [
		write %junk.txt buf
		read %junk.txt
	]
][
	loop 100 [
		write/binary %junk.txt buf
		read/binary %junk.txt
	]
]
delete %junk.txt
t2: now/precise
d: difference t2 t1
sp: to-integer (100 * 2 * length? buf) / d/3 / 1024 / 1024
print ["Disk/File:" d "-" sp "MB/S"]

halt
