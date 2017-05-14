;; ============================================
;; Script: enlist.r
;; downloaded from: www.REBOL.org
;; on: 14-May-2017
;; at: 9:10:22.607549 UTC
;; owner: greggirwin [script library member who
;; can update this script]
;; ============================================
;; ===============================================
;; email address(es) have been munged to protect
;; them from spam harvesters.
;; If you were logged on the email addresses would
;; not be munged
;; ===============================================
REBOL [
    Title: "EnList"
    Purpose: "Simple GUI for encap tools"
    File: %enlist.r
    Date: 20-jul-2003
    Author: "Gregg Irwin"
    EMail: %gregg--pointillistic--com
     Library: [
        level: 'intermediate
        platform: 'all
        type: [script tool]
        domain: [file-handling]
        tested-under: none
        support: none
        license: none
        see-also: none
    ]
    Version: 0.0.3
    History: [
        0.0.1 [05-mar-2003 "First whack" GSI]
        0.0.2 [06-mar-2003 "Added default target name generation" GSI]
        0.0.3 [08-mar-2003 "Fixed Save crash if source or target not set." GSI]
    ]
    Comment: {
        Put this file in the same directory as the encap tools you want it
        to use, or update things to use qualified path references to them.
    }
]


debug: false

data-file: %enlist.dat

record: make object! [
    id:
    source:
    target:
    tool:
    last-built:
    notes:
        none
]

; These are the Encap/SDK tools you want to launch to build things.
tools: [
;   display-name file
    enbase  %enbase.exe
    enface  %enface.exe
    enpro   %enpro.exe
    command %rebolce.exe
    command-view %rebolcve.exe
    view      %rebolve.exe
    view-beta %rebolv11003.exe
]


items: reduce either exists? data-file [
    load data-file
][
    ; %test.r comes with the SDK.
    [   ; Default data
        "test-face" make record [
            id: "test-face" source: %test.r target: %test--face.exe tool: 'enface
        ]
        "test-base" make record [
            id: "test-base" source: %test.r target: %test--base.exe tool: 'enbase
        ]
        "test-pro" make record [
            id: "test-pro"  source: %test.r target: %test--pro.exe  tool: 'enpro
        ]
    ]
]


;----------------------------------------------------------------

std-background: compose [gradient 0x1 (sky - 60) (water)]
cur-item: none
cur-id: none

;----------------------------------------------------------------
;-- Non app-specific functions

justify: func [
    {Justify the given string to the specified width.}
    s  [string!]  "The string to justify"
    wd [integer!] "The target width, in characters"
    /left"Left justify the string (default)"
    /center {Center justify the string. If the total length of the padding
        is an odd number of characters, the extra character will be on
        the right.}
    /right"Right justify the string"
    /with {Allows you to specify filler other than space. If you specify a
        string more than 1 character in length, it will be repeated as
        many times as necessary.}
        filler [string! char!] "The character, or string, to use as filler"
    /local pad-len result
][
    if 0 >= pad-len: wd - length? s [return s]
    filler: form any [filler " "]
    result: head insert/dup make string! wd filler wd / length? filler
    ; If they gave us a multi-char filler, and it isn't evenly multiplied
    ; into the desired width, we have to add some extra chars at the end
    ; to make up for the difference.
    if wd > length? result [
        append result copy/part filler wd - length? result
    ]
    pos: either center [
        add 1 to integer! divide pad-len 2
    ][
        either right [add 1 pad-len][1]
    ]
    head change/part at result pos s length? s
]

change-suffix: func [
    {Changes the suffix of the string and returns the updated string.}
string [any-string!] "The file, url, string, etc. to change."
suffix [any-string!] "The new suffix."
/local s
][
    if #"." <> first suffix [suffix: join %. suffix]
    append either s: find string suffix? string [clear s][string] suffix
]

backup-file-name: func [
{Generates a new backup file name by incrementing a numeric value
     and appending it after the suffix.}
/local i num-suffix result
][
i: 0
num-suffix: does [join "." justify/right/with form i 3 "0"]
while [exists? result: append copy data-file num-suffix][
i: i + 1
]
result
]


;----------------------------------------------------------------
;-- App-specific functions

evt-func: func [face event][
;print [event/type event/offset event/key]
switch event/type [
key [kb-handler face event]
]
event
]

shutdown: does [
    if find system/view/screen-face/feel/event-funcs :evt-func [
    remove-event-func :evt-func
    ]
quit
]

kb-handler: func [face event][
;if face = main-lay [
switch event/key [
up  []
down  []
right []
left  []
home  []
]
;]
event
]

pick-file: func [face /local f][
    either f: request-file [
        face/text: first f
        show face
        true
    ][false]
]

create-default-target: does [
    if all [
        not empty? f-source/text
        any [none? f-target/text empty? f-target/text]
    ] [
        f-target/text: change-suffix copy f-source/text "exe"
        show f-target
    ]
]


item-ids: does [sort extract head items 2]


add-new-item: func [
/local item last-id next-id
][
cur-item: item: make record [id: copy "" tool: first tools]
cur-id: item/id
append items reduce [item/id item]
display-item item
id-list/lines: item-ids
show id-list
focus f-id
item
]

delete-item: func [
id
][
if error? try [
remove/part find items id 2
id-list/lines: item-ids
show id-list
][alert "Error deleting item!"]
cur-id:
cur-item:
        none
clear-display
show main-lay
]


collect-data: func [
{Collects the data from the fields and updates the currently displayed
item. Returns true on success; false otherwise.}
/local ip-addr old-id
][
    if all [cur-item cur-id] [
        old-id: cur-id
        cur-item/id: copy f-id/text
        cur-item/source: attempt [to-rebol-file f-source/text]
        cur-item/target: attempt [to-rebol-file f-target/text]
        cur-item/tool:   ch-tool/text
        ;cur-item/last-built:
cur-item/notes:  f-notes/text

;if old-id <> cur-id [
if old-id <> cur-item/id [
change find items old-id cur-item/id
]

        id-list/lines: item-ids
        show id-list
    ]
    true
]

clear-display: does [
clear-fields main-lay
f-id/text: f-source/text: f-target/text: none
ch-tool/text: first tools
f-notes/text: none
;chk-X/data: chk-Y/data: false
]

save-data: func [
{Saves all data to disk.}
/backup {Write data to the backup file instead of the main file.}
/local out-data
][
    save either backup [backup-file-name][data-file] items
]

load-item: func [
{Make the specified item the current item. Returns the specified item.}
id
][
if cur-item [collect-data]
cur-item: select items cur-id: id
]

display-item: func [
{Load the screen with the data from the given item.}
item
/load {Load the item as the current item before displaying it.
   If this refinement is used, the item parameter should be an
   item ID, not an item object.}
/local lst
][
    f-id/text: item/id
    f-source/text: item/source
    f-target/text: item/target
    ch-tool/text: item/tool
    f-notes/text: item/notes
    i-last-built/text: item/last-built
show main-lay
]

build: func [
    "Build one or more projects"
    ids [block!]   "IDs of items to build"
;     /local orig-dir
][
    foreach id ids [
        items/:id/last-built: now
        if error? set/any 'err try [
            orig-dir: what-dir
            call s: reduce [
                select tools items/:id/tool
                " -p " items/:id/source " -o " items/:id/target
            ]
;             change-dir first split-path items/:id/source
;             call s: reduce [
;                 select tools join orig-dir items/:id/tool
;                 " -p " items/:id/source " -o " items/:id/target
;             ]
;             change-dir orig-dir
        ][
            alert mold disarm err
        ]
        if debug [print s]
    ]
    save-data
]


help-lay: layout [
    backdrop effect std-background
    across
    ;area 450x280
    ; trim rejoin [
    text-list 450x280 data
        parse/all trim rejoin [
            {===Adding New Items} newline newline
            {Press New and then enter the item data in the fields. You don't
            have to save the data right away, though you can if you want to.
            As you move from item to item, all changes are stored in memory.}
            newline newline
            {===Deleting Items} newline newline
            {Make sure the item you want to delete is selected (i.e. currently
            displayed) and press Delete (ctrl+d). That's it.} newline newline
            {===Saving Data} newline newline
            {As you are working, the changes you make are stored in memory, but
            are not saved to disk. Pressing Save (ctrl+s) saves the data to
            disk. Data is also automatically saved when you press the Quit button (ctrl+q)
            (but not if you click on the x(close) button in the upper corner of
            the window, which gives you a way to avoid the auto-save).} newline newline
        ] "^/"
    button "OK" #"^o" [unview/only help-lay]
]

main-lay: layout [
backdrop water effect std-background

style text-list text-list
with [
update-slider: does [
sld/data: 0 ; reset slider to top
sn: 0; force text to re-display correctly
sld/redrag lc / max 1 length? head lines
show sld
]
]
    style lbl text black 50
    style menu text
    style field field 400
    style browse-btn button 25 bold "..." with [edge/size: 1x1]

    across
    origin 5x5
menu black "New"    #"^n" [add-new-item]
menu black "Delete" #"^d" [if cur-id [delete-item cur-id]]
menu black "Save"   #"^s" [collect-data save-data]
; Defining #"^h" causes backspace to trigger it also. So it's out for now.
menu black "Help" [view/new/title help-lay "Item Information Help"]
menu black "Quit" #"^q" [collect-data save-data save-data/backup shutdown]

return
guide
    pad 0x10

    space 0x8

lbl "ID"   f-id: field
col-3: at
return

    ;lbl "Name"   f-name:   field return
    lbl "Source" f-source: field [create-default-target]
        browse-btn [if pick-file f-source [create-default-target]] return
    lbl "Target" f-target: field
        browse-btn [pick-file f-target] return
    lbl "Tool"   ch-tool:  choice 175 data extract tools 2 return
    lbl "Built"  i-last-built: info 175 center return

lbl "Notes" f-notes: area 400x100 return
status: text 400 ""
at col-3 + 40x0
box water 2x265
pad 15x0
guide
id-list: text-list 160 data item-IDs [
; removed setting cur-id: in line here
display-item load-item last face/picked
] return
pad 0x-5
button 160 "Build Selected Projects" [
        either empty? id-list/picked [
            alert "Select one or more items to build."
        ][
            build id-list/picked
        ]
    ] return

]



if not find system/view/screen-face/feel/event-funcs :evt-func [
insert-event-func :evt-func
]

view main-lay