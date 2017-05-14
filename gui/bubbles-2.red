Red [
	Title:   "Bubbles 2: The Sequel"
	Author:  [REBOL version "Gabriele Santilli" Red port "Gregg Irwin"]
	File: 	 %bubbles-2.red
	Tabs:	 4
	Needs:	 View
]

system/view/auto-sync?: no			; We'll call SHOW when we want to update the UI

win-size: 400x400					; This will change if the window is resized
max-bubble-size: 30					; bubble radius
num-bubbles: 100

prolog: compose [					; This is the background for the canvas
	pen 80.80.255.175
	fill-pen linear 0x0 0 (win-size/y) 90 1 1 10.10.255 0.0.100
	box 0x0 (win-size)
]
bubbles: copy []					; Where we'll keep our list of bubble drawing commands
draw-blk: reduce [prolog bubbles]

t: now/time/precise
random/seed to integer! t/second

rnd-pair: does [as-pair random win-size/x random win-size/y]

move-bubble: function [bubble] [	; Move 1 bubble toward the surface, and wiggle it a little
	pos: bubble/:IDX_B_OFFSET
	pos/y: pos/y - 3 - random 3
	pos/x: pos/x - 3 + random 5
	if pos/y < 0 [pos/y: win-size/y + max-bubble-size]
	bubble/:IDX_B_OFFSET: pos
	bubble/:IDX_B_FILL_OFFSET: pos - (bubble/:IDX_B_RADIUS / 3)
]

IDX_P_FILL_END: 7		; Prolog
IDX_P_SIZE: 15
IDX_B_FILL_OFFSET: 3	; Bubble
IDX_B_OFFSET: 13
IDX_B_RADIUS: 14

gen-bubbles: has [bubble size radius] [
	clear bubbles
	loop num-bubbles [
		size: rnd-pair
		radius: 4 + random (max-bubble-size - 4)
		bubble: compose [
			; It seems that the gradient fill size affects performance. Using
			; 'radius, as in R2 doesn't fill the bubble, but has a hard edge
			; in the middle. Using radius*2 fills it, but is slower and more
			; opaque overall.
			;fill-pen radial (size - (radius / 3)) (to integer! radius * 0.2) (radius) 0 1 1 128.128.255.105 90.90.255.165 80.80.255.175
			fill-pen radial (size - (radius / 3)) (to integer! radius * 0.2) (radius * 2) 0 1 1 128.128.255.105 90.90.255.165 80.80.255.175
			circle (size) (radius)
		] 
		append/only bubbles bubble
	]
	repend clear draw-blk [prolog bubbles]
]

win-resize: func [face /with draw-block][
	set 'win-size face/size
	canvas/size: face/size
	prolog/:IDX_P_FILL_END: face/size/y
	prolog/:IDX_P_SIZE: face/size
	if with [
		canvas/draw: draw-block
		show canvas
	]
]

; Make a standard ON-* handler func (ON_FUNC?)
ACTOR: func [body [block!]][func [face [object!] evt [event!]] body]

win: layout/tight [
	size win-size
	origin 0x0
	canvas: base win-size 10.10.255 draw draw-blk
]
win/actors: context [
	on-close:    ACTOR [quit?: yes]
	on-resize:   ACTOR [win-resize/with face gen-bubbles]
	on-resizing: ACTOR [win-resize/with face prolog]
]
view/flags/no-wait win [resize]

quit?: no

until [
	foreach bubble bubbles [move-bubble bubble]
	show canvas
	do-events/no-wait
	quit?
]
