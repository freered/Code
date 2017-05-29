;; ============================================
;; Script: anamonitor.r
;; downloaded from: www.REBOL.org
;; on: 14-May-2017
;; at: 8:55:17.840662 UTC
;; owner: romano [script library member who can
;; update this script]
;; ============================================
;; ==================================================
;; email address(es) have been munged to protect them
;; from spam harvesters.
;; If you were logged on the email addresses would
;; not be munged
;; ==================================================
REBOL [
    Title: "AnaMonitor"
    Date: 26-sep-2003
    Version: 1.1.7
    File: %anamonitor.r
    Author: "Romano Paolo Tenca"
    library: [
        level: 'advanced
        platform: 'all
        type: 'tool
        domain: []
        tested-under: none
        support: none
        license: "see context/license below"
        see-also: none
    ]
    Purpose: {To visually examine nested objects/blocks.
Examples:
^-monitor
^-monitor system/words
^-monitor svv
}
    History: [
    [1.1.7 9-Nov-2001 {Moved some functions to fixed part, fixed sort block by type - uploaded rebsit}]
    [1.1.6 9-Nov-2001 {Added find, added none to sort, moved some code to fixed part- uploaded rebsite}]
    [1.1.5 8-Nov-2001 {Made the program self-contained and re-entering, added popup, added some unview/only, offset ly not more changed by preferences, choose in sort and intest, new go-to}]
    [1.1.3 4-Nov-2001 {Refresh false, added unset, added sortby, default cnname 21 - uploaded rebsite}]
    [1.1.2 4-Nov-2001 "Corrected a bug with resize - uploaded"]
    [1.1.1 3-Nov-2001 "Corrected some minor bugs - uploaded"]
    [1.1.0 2-Nov-2001 "First public release"]
]
    Email: %rotenca--libero--it
    Category: [2 vid view util]
    Copyright: {GNU General Public License - Copyright (C) Romano Paolo Tenca 2001}
]

context [
        header: context [
            Title: "AnaMonitor"
            File: %AnaMonitor.r
            Email: %rotenca--libero--it
            Author: "Romano Paolo Tenca"
            Copyright: "GNU General Public License - Copyright (C) Romano Paolo Tenca 2001"
            Version: 1.1.7
            Date: 09/11/01
            license:
{
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software Foundation
 Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
}
        ]
        view*: system/view
        rig: func [data num [integer!]][
            data: to-string data
            head insert/dup data " " max 0 num - length? data
        ]
        lef: func [data num [integer!]][
            data: to-string data
            head insert/dup tail data " " max 0 num - length? data
        ]
        ;extract-ob: func [bl [block!] word [word!] /local res] [res: copy [] foreach x bl [insert tail res get in x word] head res]
        my-throw-on-error: func [
            {Evaluates a block, which if it results in an error, throws that error.
            Patched for unset values}
            blk [block!]
        ][
            if error? set/any 'blk try blk [throw blk]
            get/any 'blk
        ]
        get-path: func [
            {Get the value of a path}
            [catch] path [path!] /anyv "Like /any in get/any" /ignore "Ignore functions refinements" /local b e get-in] [
            my-throw-on-error [
                get-in: func [p w [word! get-word! integer!]] [
                        if get-word? :w [
                            if error? try [w: get :w] [
                                make error! reduce ['script 'need-value :w]
                            ]
                        ]
                        any [
                            if all [integer? :w any-block? :p] [
                                if error? try [return pick :p :w]
                                    [make error! reduce ['script 'out-of-range :w]]
                                true
                            ]
                            if all [word? :w object? :p][
                                if error? try [return get/any in :p :w]
                                    [make error! reduce ['script 'not-defined :w]]
                                true
                            ]
                            if any-function? :p [
                                if ignore [return :p]
                                false
                            ]
                            make error! reduce ['script 'invalid-path :w]
                        ]
                ]
                b: first head insert/only [] :path
                if error? try [e: get first :b] [
                    make error! reduce ['script 'no-value first :b]
                ]
                while [b: next :b not tail? :b] [
                    set/any 'e get-in :e first :b
                ]
                if all [unset? get/any 'e not anyv] [
                    make error! reduce ['script 'no-value :path]
                ]
            ]
            get/any 'e
        ]
        my-styles: stylize [
            btn: button 44 navy
            btn50: button 50 navy
            h4n: h4 navy
        ]
        port2ob: func [port /local x x2 nuovalinea before err line][
            x: mold port
            while [error? err: try [load x]] [
                xl: parse/all x "^/"
                err: disarm err
                parse/all err/near ["(line " thru ") " copy line to end]
                parse line [copy before thru ": " copy value to end]
                nuovalinea: rejoin [before {"} "*** CHANGED WAS: " to-string value {"}]
                x2: find x line
                remove/part x2 length? line
                insert x2 nuovalinea
            ]
            parse/all x [
                any [
                    set-word! h: " unset" (h: change/part h "^"*** CHANGED WAS: unset^"" 6) :h
                    | h: "make object! [...]" (h: change/part h "self" 18) :h
                    | skip
                ]
            ]
            do x
        ]
        get-item: func [ob [block! object! list! hash!] name [string!]][
            either object? ob
                [get/any in ob to-word name]
                [pick ob to-integer name]
        ]
        pathstr: func [item][
            rejoin [item/pathto either item/pathto <> "" ["/"][""] item/nameob]
        ]
        intest: func [linea][linea: parse linea none rejoin [linea/1 " " linea/2]]
        clip: func [data /local ritorno] [
            ritorno: copy ""
            foreach item data [insert tail ritorno join item "^/"]
            write clipboard:// ritorno
        ]
        clipname: func [ctx /local value] [
            value: either string? ctx/f-lista/picked/1 [value: first parse ctx/f-lista/picked/1 none][""]
            value: rejoin [pathstr ctx/histem/1 "/" value]
            write clipboard:// value
        ]
        alerta: func [testo face][
            face/text: rejoin ["ATTENTION:  " testo "  !!"]
            show face
        ]
        where?: func [lista /local whe] [either whe: find lista/texts lista/picked/1 [index? whe][1]]
        redrag-txt: func [face sld][sld/redrag min 1 face/size/y / second size-text face]
        scroll-to: func [ar sld txt /local xy] [
            xy: (caret-to-offset ar txt) - ar/para/scroll
            ar/para/scroll: min 0x0 ar/size / 2 - xy
            sld/data: (second xy) / max 1 second size-text ar
            show [sld ar]
        ]
        change-sn: func [face whe /local len][
            len: length? face/texts
            if face/sn >= whe [face/sn: max 0 min len - face/lc whe - 1]
            if face/sn <= (whe - face/lc) [face/sn: max 0 (whe - face/lc)]
            face/sld/data: face/sn / max 1 (len - face/lc)
            face/sld/redrag face/lc / max 1 len
        ]
        find-text: func[ar sld s s-pos][
            if all [s not-equal? s ""][
                s-pos: any [s-pos head ar/text]
                focus ar
                if s-pos: find any [view*/caret s-pos] s [
                    view*/highlight-start: view*/caret: s-pos
                    view*/highlight-end: s-pos: find/tail any [view*/caret s-pos] s
                    scroll-to ar sld s-pos
                ]
            ]
            s-pos
        ]
        viewsubface: func [
                name [string!] text-data [string!] ctx [object!] /fixed /nowrap
                /local h s-pos s xf namef wrapf ar sld
        ][
            either fixed [namef: font-fixed] [namef: font-sans-serif]
            either nowrap [wrapf: 'no-wrap] [wrapf: 'wrap]
            ctx/subface: view/new/offset/title/options layout [
                origin 10x10 size ctx/sfsize backcolor pewter
                styles my-styles
                space 2
                across
                btn "Copy" [write clipboard:// ar/data]
                btn "Wrap" "^^W" #"^w" [
                    unfocus ar
                    ar/line-list: none
                    ar/para/wrap?: ar/para/wrap? xor true
                    redrag-txt ar sld
                    show [ar sld]
                ]
                btn "Font" "^^F" #"^f" [
                    unfocus ar
                    ar/line-list: none
                    ar/font/name: either ar/font/name = font-fixed [font-sans-serif][font-fixed]
                    redrag-txt ar sld
                    show [ar sld]
                ]
                btn "Find" "f3" keycode [f3 #"^s"] [
                    s: either all [
                        view*/highlight-start
                        view*/highlight-end
                    ][copy/part view*/highlight-start view*/highlight-end][""]
                    h: false
                    inform layout [
                        styles my-styles
                        backcolor pewter
                        xf: field s [s: value h: true hide-popup]
                        across
                        btn50 "OK" [s: xf/text h: true hide-popup]
                        btn50 navy "Cancel" [hide-popup]
                        do [focus xf]
                    ]
                    if h [s-pos: find-text ar sld s s-pos]
                ]
                btn "Next" "f4" keycode [f4 #"^n"] [
                    s-pos: find-text ar sld s s-pos
                ]
                return
                h: at
                space 0
                ar: area ctx/sfsize - 16x0 - h - 10x10 snow snow
                    font-size ctx/prefs/fontsize font-name namef wrapf text-data
                        #"^(esc)" [unview/only ctx/subface]
                sld: slider ctx/sfsize - h - 10x10 * 0x1 + 16x0 [scroll-para ar sld]
                do [
                    ar/para: make ar/para []
                    ar/font: make ar/font []
                    redrag-txt ar sld
                    ctx/ar: ar
                    ctx/sld: sld
                ]
            ] ctx/sf-off name [resize]
        ]
        viewhelp: func [ctx /local ar sld x][
            x: copy "" foreach l help-string [insert tail x join l "^/"]
            if ctx/helpface [
                unview/only ctx/helpface
            ]
            ctx/helpface: view/new/offset layout [
                origin 10x10 size 560x400 backcolor pewter
                across
                space 0
                ar: area 540x370 - 16x0 bold 203.204.205 203.204.205 font-name font-fixed feel [engage: none] x
                keycode [f1 #"^(esc)"] [unview/only ctx/helpface]
                sld: slider ar/size * 0x1 + 16x0 [scroll-para ar sld]
                space 2
                return
                button navy 100 "Help" [ar/text: x redrag-txt ar sld show ar]
                button navy 100 "Licence" [ar/text: header/license redrag-txt ar sld show ar]
                do [
                    redrag-txt ar sld
                ]
            ] ctx/ly/offset + 13x25
        ]
        preferences: func [ctx /local sv ly-old useprefs prefs][
            prefs: ctx/prefs
            if ctx/ly-pref [unview/only ctx/ly-pref]
            sv: make prefs []
            useprefs: does [
                ly-old: ctx/ly
                ctx/ly: layout ctx/lyb
                ctx/refresh
                view/new/options/offset/title ctx/ly [resize] ly-old/offset header/title
                unview/only ly-old
                unview/only ctx/ly-pref
            ]
            ly-pref-b: [
                styles my-styles
                backcolor pewter
                ;origin 15x15
                guide
                h4 "Double-click"
                h4 "Sort List"
                h4 "Hide unset value"
                h4 "List font size:"
                h4 "Sortby:"
                return
                space 10
                check prefs/dbcl [prefs/dbcl: value]
                check prefs/sort [prefs/sort: value]
                check prefs/nounset [prefs/nounset: value]
                space 7
                field 50 to-string prefs/fontsize [if value <> "" [prefs/fontsize: to-integer value]]
                h: at
                h4 50 navy pewter copy prefs/sortby [
                    choose/window/offset ["Name" "Type"]
                        func [face btn] [prefs/sortby: copy face/text]
                        ctx/ly-pref
                        h - 20x5
                    face/data: face/texts/1: face/text: copy prefs/sortby
                ]
                return
                across
                space 10
                btn50 navy "Save" [save ctx/fileprefs third prefs useprefs]
                btn50 navy "Use" [useprefs]
                btn50 navy "Cancel" #"^(esc)"[prefs: make sv [] unview/only ctx/ly-pref]
            ]
            view/new/title ctx/ly-pref: center-face/with layout ly-pref-b ctx/ly "Preferences"
        ]
        help-string: reduce [
        header/title
        join "by " header/author
        ""
{   help  = F1         = help
    back  = F2 = left  = go back in the history
    forw  = F3 = right = go forward in the history
    refr  = F5 = ^^R    = refresh the list
    probe = F6 = ^^P    = probe the block (only valid on block!)
    copy  = ^^C         = copy list to clipboard
    cpnm  = ^^X         = copy the path to clipboard
    exe   = ^^E         = execute a command (right click for new shell)
    prefs              = set some prefs
    sort               = sort the list (make a refresh)
   
    up down page-down page-up end home return browse the list
    click on an item to view (object/block/pair/tuple/function...)
    Attention: port are listed with a trick
}
        rejoin ["Version: " header/version " " header/date]
        join "Report bugs and wish to : " header/email
        header/copyright
        ]

    ;not shared part
    cb: [
        ly: ly-exe: f-lista: f-text: f-intest: f-sort: f-sort-lab: f-unset: f-unset-lab: f-console: f-console-sld: none
        ar: sld: f-console: h: ly-exeb: none
        cntype: cnname: linelen: cnblock: 0
        ly-pref: none
        sf-off: 40x40
        linelen: 200
        cntype: 9
        cnname: 21
        cnblock: 4
        helpface: subface: none
        histem: copy []
        fileprefs: system/script/path/anampref.r
        prefs: context [
            dbcl: false
            sort: false
            fontname: font-fixed
            fontsize: 12
            wsize: 630x435
            woffset: 50x50
            nounset: false
            sortby: "Name"
        ]
        wsize: prefs/wsize
        ly-exesize: sfsize: prefs/wsize - 25x25
        itemob: context [ob: nameob: pathto: type: sorted: sortby: nounset: refresh: listall: none whe: 1 listanomi: copy []]
        scan: [
            object!     'oblist
            port!       'portlist
            block!      'blklist
            hash!       'blklist
            list!       'blklist
        ]
        scanview: [
            function!  'funcview
            native!    'funcview
            action!    'funcview
            op!        'funcview
            string!    'stringview
            bitset!    'stringview
            image!     'imageview
            tuple!     'tupleview
            pair!      'pairview
            port!      'portview
        ]
        listall: func [item [object!] /local x] [
            if x: select scan type?/word get in item 'ob [
                item/listanomi: copy []
                item/sorted: item/nounset: false
                return do x item
            ]
            false
        ]
        portlist: func [item /local attrs tipo altro] [
            if error? try [item/ob: port2ob item/ob] [alerta "Can't list this port" f-intest return false]
            item/ob/self: item/ob
            attrs: next second item/ob
            foreach el next first item/ob [
                tipo: type? first attrs
                altro: to-string either unset? first attrs ["unset"] [blobval first attrs]
                insert tail item/listanomi rejoin [lef el cnname " " lef tipo cntype " : " altro]
                attrs: next attrs
            ]
            true
        ]
        oblist: func [item /local attrs tipo altro] [
            attrs: second item/ob
            foreach el first item/ob [
                tipo: type? first attrs
                altro: copy ""
                altro: either unset? first attrs ["unset"] [blobval first attrs]
                insert tail item/listanomi rejoin [lef el cnname " " lef tipo cntype " : " altro]
                attrs: next attrs
            ]
            true
        ]
        blklist: func [item /local tipo altro x] [
            if 0 = length? item/ob [return false]
            x: 0
            foreach el item/ob [
                tipo: type? :el
                altro: copy ""
                insert tail altro either unset? :el ["unset"][blobval :el]
                x: x + 1
                insert tail item/listanomi
                    rejoin [rig x cnblock "  " lef tipo cntype ": " altro]
            ]
            true
        ]
        viewall: func [el name [string!] /local x] [
            x: select scanview type?/word :el
            either found? x [
                if subface [
                    sf-off: subface/offset
                    if subface/show? [unview/only subface]
                    subface: none
                ]
                do x :el name
            ] [none]
        ]
        funcview: func [f name /local ritorno] [
            ritorno: copy ""
            insert tail ritorno mold to-set-path name
            insert tail ritorno "^/"
            if function? :f [insert tail ritorno " func"]
            insert tail ritorno mold third :f
            if function? :f [insert tail ritorno mold second :f]
            viewsubface/fixed name ritorno self
        ]
        stringview: func [el name] [
            viewsubface name mold/only :el self
        ]
        portview: func [el name] [
            viewsubface/fixed name mold/only :el self
        ]
        viewprobe: func [item] [
            if block? item/ob [
                if subface [
                    sf-off: subface/offset
                    if subface/show? [unview/only subface]
                ]
                viewsubface/fixed item/nameob mold item/ob self
            ]
        ]
        pairview: func [el name] [
            if not any [
                el/x <= 0 el/y <= 0
                el/x > view*/screen-face/size/x
                el/y > view*/screen-face/size/y
            ] [
                subface: view/new/offset/title layout [
                    origin 10x10 backcolor pewter
                    h4 font-size prefs/fontsize rejoin [name " : " :el]
                    box :el yellow
                    key #"^(esc)" [unview/only subface]
                ] sf-off "Pair"
            ]
        ]
        tupleview: func [el name] [
            if 3 = length? el [
                subface: view/new/offset/title layout [
                    origin 10x10 backcolor pewter
                    h4 font-size prefs/fontsize rejoin [name " : " :el]
                    box 90x90 edge [color: coal size: 2x2] :el
                    key #"^(esc)" [unview/only subface]
                ] sf-off "Tuple"
            ]
        ]
        imageview: func [el name] [
            subface: view/new/offset/title layout [
                origin 10x10 backcolor pewter
                h4 font-size prefs/fontsize name
                image :el
                key #"^(esc)" [unview/only subface]
            ] sf-off "Image"
        ]
        blobval: func [x /local x1 x2 x3] [
            x1: [rejoin ["[" length? :x " " index? :x "/" length? head :x "]"]]
            x2: [copy/part trim/lines mold third :x linelen]
            x3: [copy/part trim/lines mold :x linelen]
            switch/default type?/word :x [
                block!      x1
                hash!       x1
                list!       x1
                object!     [copy/part rejoin ["[" length? first :x "] " mold first :x] linelen]
                port!       ["(click me)"]
                function!   x2
                action!     x2
                native!     x2
                op!         x2
                word!       [copy/part join "'" mold :x linelen]
                string!     [copy/part rejoin [ do x1 "  " do x3] linelen]
            ] x3
        ]
        changelista: func [item /local temp] [
            if prefs/nounset <> item/nounset [
                either prefs/nounset [
                    item/listall: copy item/listanomi
                    while [not tail? item/listanomi] [
                        either equal? second parse first item/listanomi " " "unset" [
                            item/listanomi: remove item/listanomi
                        ] [
                            item/listanomi: next item/listanomi
                        ]
                    ]
                    item/listanomi: head item/listanomi
                ][
                    item/listanomi: item/listall
                    item/listall: none
                ]
                item/nounset: prefs/nounset
                item/whe: 1
            ]
            if any [prefs/sort <> item/sorted prefs/sortby <> item/sortby][
                offsort: either select reduce [block! hash! list!] item/type [
                    select reduce ["Name" 0 "Type" cnblock + 2 "Value" cnblock + 2 + cntype] prefs/sortby
                ][
                    select reduce ["Name" 0 "Type" cnname + 1 "Value" cnname + 1 + cntype] prefs/sortby
                ]
                if prefs/sort [
                    sort/compare item/listanomi func [a b][lesser? skip a offsort skip b offsort]
                ]
                item/sorted: prefs/sort
                item/sortby: prefs/sortby
            ]
            if all [item/refresh temp: find item/listanomi item/refresh][
                item/whe: index? temp
                item/refresh: false
            ]
            f-intest/text: rejoin [
                index? histem "/" length? head histem " -- " pathstr item " (" item/type ")"
            ]
            f-lista/texts: f-lista/lines: f-lista/data: item/listanomi
            f-lista/picked: reduce [pick f-lista/texts item/whe]
            change-sn f-lista item/whe
            show f-intest
            show f-lista
        ]
        selec: func [value /local new tipo x item] [
            item: first histem
            tipo: item/type
            new: first parse value none
            if all [
                not unset? set/any 'x get-item item/ob new
                not equal? :x item/ob
            ] [
                any [
                    if found? find scan type?/word :x [
                        newlist new :x item
                    ]
                    if found? find scanview type?/word :x [
                        viewall :x rejoin [pathstr item "/" new]
                    ]
                ]
            ]
        ]
        go-to: func [ind [integer!]] [
            if all [not tail? ind: skip head histem (ind - 1) ind <> histem][
                histem/1/whe: where? f-lista
                histem: ind
                changelista histem/1
            ]
        ]
        go-back: does [go-to -1 + index? histem]
        go-forward: does [go-to 1 + index? histem]
        refresh: has [item] [
            item: histem/1
            item/whe: where? f-lista
            item/refresh: pick item/listanomi item/whe
            listall item
            changelista item
            item/refresh: none
        ]
        newstart: func[value /local start][
            either all [
                value <> ""
                not error? try [
                    start: get-path to-path load value
                ]
            ]
            [if not restart value :start [alerta "Invalid Type!" f-intest]]
            [alerta "Invalid Value!" f-intest]
        ]
        engage-tl: func [face action event /local len whe] [
            if action = 'key [
                len: length? face/texts
                either not found? find face/texts face/picked/1 [
                    clear face/picked
                    whe: 1
                    insert/only tail face/picked pick face/texts whe
                ] [
                    whe: index? find face/texts face/picked/1
                    whe: switch/default event/key [
                        up [max 1 whe - 1]
                        down [min len whe + 1]
                        home [1]
                        end [len]
                        page-up [max 1 whe - face/lc + 1]
                        page-down [min len whe + face/lc - 1]
                        #"^M" [selec face/picked/1 -1]
                        #" " [selec face/picked/1 -1]
                        right [go-forward -1]
                        #"^(esc)" [go-back -1]
                        left [go-back -1]
                    ] [whe]
                    if whe <> -1 [
                        clear face/picked
                        face/picked: reduce [pick face/texts whe]
                    ]
                ]
                if whe <> -1 [change-sn face whe]
                show face
            ]
        ]
        engage-iter: func[f a e][
            if a = 'down [
                if cnt > length? head lines [exit]
                if not e/control [f/state: cnt clear picked]
                alter picked f/text
                if any [not prefs/dbcl e/double-click] [do :act slf f/text]
            ]
            if a = 'up [f/state: none]
            show pane
        ]
        newlist: func [name [string!] start parent /local newitem ][
            newitem: make itemob [
                nameob: copy name
                ob: :start
                pathto: either none? parent [copy ""][pathstr parent]
                type: type? :start
            ]
            either listall newitem [
                if not empty? histem [histem/1/whe: where? f-lista]
                clear next histem
                histem: back insert next histem newitem
                changelista newitem
                true
            ][
                newitem: none
                false
            ]
        ]
        hist-list: func [face /local hist hista][
            hist: copy []
            hista: back tail histem
            while [not 25 <= length? hist][insert hist rejoin [rig index? hista 3 " " pathstr first hista] if head? hista [break] hista: back hista]
            choose/window/offset/style hist
                func [face btn][go-to to-integer first parse face/text " "]
                ly
                f-intest/size * 0x1 + face/offset
                make-face/size/spec/clone 'button f-intest/size [font: make font [align: 'left]]
        ]
        restart: func [name [string!] start /local newitem] [
            if not found? find scan type?/word :start [return false]
            if newlist name :start none [return true]
            ;viewall :start name
            false
        ]
        lyb: [
            origin 10x10
            size wsize
            backcolor pewter
            styles my-styles
            across
            space 5x1
            f-intest: h4 navy pewter first wsize - 162 bold "" [hist-list face]
            f-unset-lab: h4 60 navy no-wrap "No Unset" feel [engage: none]
            f-unset: check prefs/nounset [prefs/nounset: f-unset/data refresh]
            f-sort-lab: h4 30 navy "Sort"  [
                choose/window/offset ["None" "Name" "Type"]
                    func [face btn] [
                        either face/text = "None"
                            [prefs/sort: f-sort/data: false]
                            [prefs/sortby: copy face/text prefs/sort: f-sort/data: true]
                    ]
                    ly
                    face/offset - 40x5
                refresh
                show f-sort
            ]
            f-sort: check prefs/sort [prefs/sort: f-sort/data refresh]
            return
            space 1
            btn "Back" "F2" [go-back] keycode [f2]
            btn "Forw" "F3" [go-forward] keycode [f3]
            btn "Refr" "^^R/F5" [refresh] keycode [f5 #"^r"]
            btn "Probe" "F6" [viewprobe histem/1] keycode [f6 #"^p"]
            btn "Copy" "^^C" [clip f-lista/data] keycode [#"^c"]
            btn "CpNm" "^^X" [clipname self] keycode [#"^x"]
            btn "Exe" "^^E" [exe] [launch ""] keycode [#"^e"]
            btn "Pref" [Preferences self]
            space 2
            btn "Help" "F1" [viewhelp self] keycode [f1]
            space 5
            h: at
            f-text: field wsize/x - h/x - 10 copy "Insert the name of object/block" [newstart value]
            return
            f-lista: text-list wsize - 20x56 black font-name font-fixed font-size prefs/fontsize no-wrap data "" [selec value]
            do [
                f-lista/feel: make f-lista/feel [engage: :engage-tl]
                bind second :engage-iter in f-lista 'self
                f-lista/iter/feel: make f-lista/iter/feel [engage: :engage-iter]
            ]
        ]
        Monitor: func ["Visual monitor of objects/blocks" 'start [any-type!]/local startname name ev] [
            if not value? 'start [start: 'system]
            name: form :start
            any [
                if path? :start [start: get-path :start true]
                if any-word? :start [start: get/any :start true]
            ]
            if any [
                unset? :start
                not found? find scan type?/word :start
            ] [
                print ["Invalid argument. Not one of:" extract scan 2]
                exit
            ]
            if exists? fileprefs [
                prefs: make prefs load/all fileprefs
            ]
            svv/vid-colors/body: reduce [navy 255.180.55]
            wsize: prefs/wsize
            ly-exesize: sfsize: prefs/wsize - 25x25
            ly: layout lyb
            if restart name :start [
                focus f-lista
                view/new/options/offset/title ly [resize] prefs/woffset header/title
                insert-event-func ev: func[face event] [
                    switch event/type [
                        resize [
                            switch event/face reduce [
                                subface [resizesf event/face]
                                ly [resize-ly event/face]
                                ly-exe [resize-ly-exe event/face]
                            ]
                            return none
                        ]
                        key [
                            if all [
                                ly = event/face
                                view*/focal-face <> f-lista
                            ][
                                either view*/focal-face = f-text [
                                    if event/key = #"^(esc)" [
                                        focus f-lista
                                        return none
                                    ]
                                ][
                                    focus f-lista
                                ]
                            ]
                        ]
                    ]
                event
                ]
            do-events
            remove-event-func :ev
            svv/vid-colors/body: reduce [40.100.130 255.180.55]
            none
            ]
        ]
        exe: has [value result command ly-exeoff ex err h] [
            ex: func [][
                command: f-console/text
                if all [not none? command command <> ""] [
                    either error? set/any 'err try [set/any 'result do command] [
                        err: disarm err
                        print ["** Error: " reduce bind to-block (get err/id) in err 'self]
                        print ["** Near: " err/near]
                    ][
                        print ["==" either value? 'result [:result]['unset]]
                    ]
                ]
                refresh
            ]
            command: copy ""
            if not empty? f-lista/picked [
                command: copy f-lista/picked/1
                if not none? command [
                    command: first parse command none
                    command: rejoin [pathstr histem/1 "/" command ]
                ]
            ]
            ly-exeoff: sf-off
            if not none? ly-exe [ly-exeoff: ly-exe/offset unview/only ly-exe]
            ly-exesize: 500x200
            ly-exe: layout ly-exeb: [
                origin 10x10
                size ly-exesize
                backcolor pewter
                across
                button navy "Exe" "^^E" #"^E" [ex]
                button navy "Close" "^^Q" keycode [#"^Q" #"^(esc)"] [unview/only ly-exe focus f-lista]
                return
                h: at
                space 0
                f-console: area ly-exesize - h - 16x0 - 10x10 snow white font-name font-fixed font-size prefs/fontsize command []
                f-console-sld: slider f-console/size * 0x1 + 16x0 [scroll-para f-console f-console-sld]
                do [
                    redrag-txt f-console f-console-sld
                    deflag-face f-console 'tabbed
                ]
            ]
            focus f-console
            view/new/offset/title/options ly-exe ly-exeoff "Insert a command to execute" [resize]
        ]
        resizesf: func [face /local minsize deltasize][
            minsize: 300x200
            face/size: max face/size minsize
            deltasize: face/size - sfsize
            sfsize: face/size
            ar/size: ar/size + deltasize
            ar/line-list: none
            sld/size/y: ar/size/y
            sld/offset/x: ar/offset/x + ar/size/x
            redrag-txt ar sld
            scroll-para ar sld
            show face
        ]
        resize-ly-exe: func [face /local minsize deltasize][
            minsize: 300x200
            face/size: max face/size minsize
            deltasize: face/size - ly-exesize
            ly-exesize: face/size
            f-console/size: f-console/size + deltasize
            f-console/line-list: none
            f-console-sld/size/y: f-console/size/y
            f-console-sld/offset/x: f-console/offset/x + f-console/size/x
            redrag-txt f-console f-console-sld
            ;scroll-para f-console f-console-sld
            show face
        ]
        resize-ly: func [face /local minsize ly-old][
            minsize: 600x430
            face/size: max face/size minsize
            cnname: to-integer cnname * face/size/x / wsize/x
            wsize: face/size
            ly-old: ly
            ly: layout lyb
            refresh
            view/new/options/offset/title ly [resize] face/offset header/title
            unview/only ly-old
        ]
    ]
    set 'Monitor func ["Visual monitor of objects/blocks" 'start [any-type!]] [
        either value? 'start [do in context cb 'monitor :start][do in context cb 'monitor]
    ]
]
;all what follow can be commented out or cancelled
if not value? 'my_local_user [
    monitor system
    ask "Return to Quit, Esc for Shell"
]
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       