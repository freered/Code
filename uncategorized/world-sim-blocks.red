Red [
	author: "Gregg Irwin"
]

comment {
	From Gitter, @this-gavagai asked about modeling in Red compared to modeling
	in traditional OOP languages. Here's the concrete example given:

	"
	Imagine you wanted to simulate economic dynamics in a third world village. You
	might begin with 30-50 households, each with 2-12 people. Most of these people
	would own a couple of different kinds of fields, and some of them might also own
	cows. Cows produce milk, which is a good source of cash, but this production is
	dependent on a number of factors including an animal's general health and well
	being. Any model of animal health would almost certainly be influenced by (among
	other things) what its owners choose to feed it, which in turn is going to be
	influenced by both the costs of fodder in the village generally and specific
	agricultural outputs of the household that owns it.

	In other words, what I need to describe are templates for entities that can be
	instantiated in relatively large numbers to behave quasi-autonomously in a time-
	series simulation. The goal would be able to "experiment", testing for example
	how the arrival of a veterinary clinic in town (or a new breed of cow with
	different health functions, or a drop in fertilizer prices, or a sudden decrease
	in rain) would influence the system's overall dynamics.

	In an OOP paradigm, I would start by defining classes and their public
	interfaces, and then I would arrange them into hierarchical graphs. Some of
	these classes would be relatively self-contained (i.e., weather), some would
	depend on a parent many-to-one (i.e., people in a household), and still others
	would exist one-to-one as an extension of a parent (i.e., a particular cow's
	health, which might be complex enough to benefit from encapsulation as an object
	in its own right). That all works fine enough, but I'm not sure classic OOP is
	actually the right model for any of it. The hard distinction most languages
	expect between code and data, for example, is very limiting, and Rebol/Red's
	approach seems to promise a much more elegant way of thinking about entities in
	a simulation. The possibility that a vet might show up and re-write a particular
	cow's food consumption behaviors at runtime, for example, is just way too cool
	to ignore. It opens the door for unprecedented new kinds of elegance and
	expressiveness in this kind of scientific modeling.

	Right now, what I'm trying to figure out as I get more familiar with Red is just
	general principles. For example, as in my past few posts, how should I think
	about the choice between hierarchies of objects and complex blocks? I get how
	both syntaxes work, but without a deeper intuition of why red programmers do
	things the way they do I know I'm just going to fall back on whatever I do in
	python.
	"

	The hard part about answering questions like this is that there is not one
	"right way" in Red. Red is about letting you express the solution to your
	problem however it is clearest to you and others working with it. This sketch
	is me streaming out ideas. The approach here is very block based. It would be
	instructive to do a comparable object based version, and also a hybrid approach.
	Each has strengths and weaknesses. The best solution depends on the details.
	Do you want to be able to persist simulations? How might you analyze the data?
	Is there the risk of using untrusted data? What is the easiest way for end 
	users to create their own models? Do they have to understand the code, or are
	files in a format they can edit easily? What comes to mind naturally in how
	you *want* to express the solution?
}

;-------------------------------------------------------------------------------

e.g.: :comment

;-------------------------------------------------------------------------------
; First, what are we talking about, and how do we want to talk about it?

e.g. [
	[
		house   ; 30-50
		people	; 2-12
		cows
		fields
	]

	[
		[Bob buys 2 cows [bessie and flossie]  from Carol]
		[Alice moves to house #5]
		[Dan buys field #37N...] ; (It's a UTM coordinate system, right? ;^)
	]

	; Can we have items with the same name, and so need namespaces?
	world [
		cows [
			bessie []
			flossie []
		]
		fields [
			flanders []
			flossie []
		]
	]

	; How do you define the starting point?
	make-world [
		50  houses	; no spec means random mix
		250 people	; no spec means random mix
		500 fields [
			half small  half large
			30% oats 30% wheat 40% alfalfa
		]
		1000 cows [80% healthy]
	]
]

;-------------------------------------------------------------------------------

; In our data model, we can embed relationships in the records themselves,
; or use "join tables". Each has pros and cons. We also have the option to
; key the blocks with an ID for each item, making selection easy, or making
; the ID for items a value in the block, making them self-contained; or both.
; A functional approach might embed the IDs, and use HOFs to traverse blocks.
; An imperative approach, or random selection of data by key, often makes
; for very "obvious" code.

; I'm Using all blocks here, rather than objects, just for this example. I
; did that because many new Reducers (Red-users) are familiar with OOP, but 
; may not have seen this approach in other languages.
;
; A key point is that you `make` objects from prototypes, but objects are 
; not automatically deep-copied (cloned) in Red. When using blocks, you can
; `copy` a block, which is similar to `make` on objects. To copy all nested
; series values you use `copy/deep`.
;
; You'll notice the _ values in the blocks below. They have no special 
; meaning to Red. They are just a placeholder for a value. In many cases
; you'll use `none` in your Red code. The reason I didn't here, is because
; I expect to load and save simulation data, and (this is the important bit)
; you have to remember that everything in Red is data *until it is evaluated*.
; Why is this an issue for `none`? It just a matter of what's clear and easy
; to write, if you want a true `none!` value. 
;
;	red>> type? second [a none]
;	== word!
;	red>> type? second [a #[none]]
;	== none!
;	red>> type? second reduce ['a none]
;	== none!
;	red>> type? second load "a none"
;	== word!
;
; I'll leave it as an exercise for the reader to `load` data from a file
; and experiment with evaluation. Sufficed to say that `_` in the blocks
; is just like `none` as far as Red is concered, *until it is evaluated*.
; Both are `word!` values, which you can think of as symbols in some other
; languages.

prototypes: [
	world   [
		weather []
		houses  []
		people  []
		fields  []
		cows    []
	]
	house   [id _ size _ occupants []]
	person  [id _ house _ fields [] cows []]
	field   [id _ location _ size _ crop _ health _]
	cow     [id _ health _ weight _ age _]

	; Relationships. These could be used instead of the 'occupants, 
	; 'fields, and 'cows sub-blocks in 'house and 'person respectively.
	housing []		; house-person pairs
	ownership []	; person-[cow | field] pairs
]

; What kind of helpers might we want?

crop-value: func [type][
	; We don't have a money! type in Red yet, so use ints for now.
	select [oats 45 wheat 35 alfalfa 25] type
]

field-value: func [field][
	field/size * (field/health * 100) * crop-value field/crop
]

cow-value: func [cow][100 * cow/health]

house-max-occupancy: func [house][select [small 2 medium 6 large 12] house/size]

;-------------------------------------------------------------------------------

__WORLD: none	; Working target for making a world from a spec
; Note that we could use also COLLECT while parsing, to build up
; our world. More below.

; This little dialect isn't smart, but it implements an example world
; definition in the most basic way. This lets us play with the dialect
; from the user's side, very quickly; without being too strict in the 
; definition (yet) to ensure things aren't redefined, or that values
; fall within constraints.
world=: [
	some [
		(set [count type spec] none)
		set count integer!
		set type ['houses | 'people | 'fields | 'cows]
		opt [set spec block!]
		(make-items count type spec)
	]    
]

make-world: func [spec [block!]][
	__WORLD: copy/deep prototypes/world
	; If the world spec was valid, `parse` will return `true`, and we
	; will return the world we built from the spec. If the parse fails,
	; `if` returns `none`. Remember, Red functions return the result of
	; the last expression evaluated, you don't have to use `return` at
	; the end of funcs, only for early exits.
	if parse spec world= [
		__WORLD
	]
]

; This function deserves a little explanation, because someone will 
; surely comment on it. Yes, it has side effects against a global data
; structure. If I were building this out, I might change that. On the
; other hand, it would depend on how big I thought the solution would
; ultimately be. Where a functional approach would either just build
; up the list of items and return it, for the caller to consume and add
; to the __WORLD, or it would take an accumulator (which I did on my 
; first pass with this function), and add the results to that.
; Accumulators are a fine model, and I like them a lot, but eventually
; the results all need to go somewhere, right? And we sometimes just 
; push the complexity around, or even add to it, by planning beyond our
; needs. It's a form of premature optimization, targeted at scope rather
; than performance. As an exercise, do it without side effects, and 
; without an accumulator. If this function can be ignorant of how the
; world uses the result, that's good. e.g., it should return *just* a
; block of items, because it doesn't know if the rest of the system is
; going to use their ID as a key. Now our function is simple and likely
; idempotent. But what effects ripple out from that into the rest of
; the app? What else might you need to do? With no knowledge of the 
; global structure, it can't safely generate IDs, right? Do we need to
; make it possible to call `make-items` multiple times for the same
; type? People will disagree with me on this, but I don't believe there
; is a one-size-fits-all paradigm in languages, any more than there is
; a single methodology that will work equally well for all teams and
; projects.
; It's absolutely true that our data structures and algorithms affect each
; other, but it does *not* mean ; that binding them tightly together, as 
; in OOP, s always best.
make-items: function [
	count [integer!]     "Should be > 0"
	type  [word!]        "[houses people fields cows]" 
	spec  [block! none!] "Not required, so may be none"
][
	key: map-type type				; convert plural to singular
	proto: prototypes/:key			; find the prototype spec for this type
	blk: __WORLD/:type				; find where items are in the world data
	
	;TBD: This is where we would apply the spec as well, if one
	;     was given, passing information down to specific make*
	;     funcs for items, changing values based on percentages,
	;     etc. And each would have their own sub-dialects.
	repeat i count [
		rec: copy/deep proto		; deep copy so records don't share sub-blocks
		rec/id: make-id key i		; use singluar typename (key) for the id
		repend blk [rec/id rec]		; add the ID as a key and the record as a sub-block
	]
	new-line/all blk on				; so each item is on its own line when molded
]

; I wrote the above, then needed to write the support funcs. As you
; might guess, what you see here is the result of a few refactoring
; passes.

make-id: func [type [word!] n][to word! append form type n]

plural-to-single: [houses house people person fields field cows cow]
single-to-plural: [house houses person people field fields cow cows]

plural?:   func [type][make logic! find/skip plural-to-single type 2]
singular?: func [type][not plural? type]

map-type: function [type][
	; Clearer as two lines?
	;map: either plural? type [plural-to-single][single-to-plural]
	;map/:type
	; Or one?
	select either plural? type [plural-to-single][single-to-plural] type
]

;-------------------------------------------------------------------------------

; BIG CAPS for important global data structures, to make them
; stand out while drafting ideas.

STARTING_WORLD: make-world [
	50  houses	; no spec means random mix
	250 people	; no spec means random mix
	500 fields [
		half small  half large
		30% oats 30% wheat 40% alfalfa
	]
	1000 cows [80% healthy]
]

; At this point we have generated a world as a starting point. We can
; save that off, pre-generate lots of them, and apply different criteria
; for a simulation run against them. When we start a sim, the first
; thing we do is copy our starting world, then we can log each action
; and change that occurs, which is a running log that could be independently
; applied to different worlds. Obviously any named resources need to exist
; in the world, but you could, for example, start with cows or fields in
; varying states of health or have vets and horticulurists take different
; actions.
WORLD: copy/deep STARTING_WORLD

; Events that occur in the sim go here.
WORLD_CHANGES: copy []

; Did it work? Do we have a world that matches our spec?
print mold world

;-------------------------------------------------------------------------------

; Note that by using keys for records, we can't seamlessly also use
; indexes into those blocks. You can still use `foreach [id rec] ...`
; to iterate, but if you want to say houses/1, or cows/5, eliminate 
; the keys from the blocks. What I would probably do, though is write
; helper funcs to select items. (see below)
world/cows/cow1/health: 90%
print cow-value world/cows/cow1

; Should we allow multi-select?
get-entity: function [type [word!] key [word! integer!]][
	if singular? type [type: map-type type]		; pluralize
	; Double the index, if an integer, to account for keys in blocks
    either word? key [world/:type/:key][pick world/:type (key * 2)]
]
;get-entity: function [type [word!] spec [word! block! integer!]][
;	if singular? type [type: map-type type]		; pluralize
;	res: collect [
;	    foreach key compose [(spec)][
;	    	; Double the index, if an integer, to account for keys in blocks
;	        keep/only either word? key [world/:type/:key][pick world/:type (key * 2)]
;	    ]
;	]
;	either 1 = length? res [first res][new-line/all res on]
;]

probe get-entity 'cow 1
probe get-entity 'houses 'house2
probe get-entity 'person 5
probe get-entity 'field 'field3
;probe get-entity 'people [person3 5]			; requires multi-select version above

; We can use lit-word! params in the function def, so we
; don't have to use lit-word! args in the call.
cow: func ['id][get-entity 'cows id]

probe cow cow3

; From here we could write a top-level simulator dialect, wrapping all the
; commands and querys we need. 

;-------------------------------------------------------------------------------

; I'll stop here for now. This was a fun project to think about, and I've 
; given you a lot of information and open-ended questions and experiments
; to do on your own. 
;
; Remember that this isn't a finished, planned design. This essay is a
; first step in exploring the problem space and discussing alternatives
; with you. It's not an attempt at literate programming, but an example
; of how I use Red as an "interactive" design tool. A language for thinking
; about problems and their solutions. Being able to express and *see* what
; we're talking about is a big part of Red's power. 

; Happy Reducing!

halt

; P.S. Yes, you can paste this whole thing into the Red console.

; P.P.S. The shell console has a paste issue right now, so you can only
;		paste this into the GUI console and have it work. Otherwise,
;		run as a regular script.