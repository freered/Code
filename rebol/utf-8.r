;; ==============================
;; Script: utf-8.r
;; downloaded from: www.REBOL.org
;; on: 14-May-2017
;; at: 8:51:05.639944 UTC
;; 
;; ==============================
;; ===============================================
;; email address(es) have been munged to protect
;; them from spam harvesters.
;; If you were logged on the email addresses would
;; not be munged
;; ===============================================
REBOL [
    Title: "UTF-8"
    Date: 2-Dec-2002
    Name: "UTF-8"
    Version: 1.0.2
    File: %utf-8.r
    Author: "Jan Skibinski"
    Needs: [%hof.r]
    Purpose: {Encoding and decoding of UCS strings
to and from UTF-8 strings.
}
    History: {
    Version 1.0.2: Added a simulation of a Unicode support.
    Version 1.0.1:
        A full range of optimizations has been applied,
        resulting in much improved speed. The entire scheme
        has been redesigned and the algorithms simplified.
        Most of the data tables have been removed.
        There are fewer functions but they are more generic.

    Version 1.0.0:
        Basic UTF-8 encoding and decoding functions.
        Limitations: Does not handle a big/little endian
        signatures yet. Needs thorough testing and algorithms
        optimalizations.
    }
        library: [
        level: 'intermediate
        platform: 'all
        type: 'Tool
        domain: 'text
        tested-under: none
        support: none
        license: none
        see-also: none
    ]
    Email: %jan--skibinski--sympatico--ca
    Category: [crypt 4]
    Acknowledments: {
        Inspired by the script 'utf8-encode.r of RebOldes
        and Romano Paulo Tenca, which encodes Latin-1 strings.

        I'd like to thank RebOldes for his suggestions for improvements
        regarding the version 1.0.0. However the completely redesigned
        version 1.0.1 was already under way so his changes did not
        make it here.

        My thanks go also to Romano Paulo Tenca for converting
        my 'while loop to a 'parse loop and for a bunch of other
        optimization tricks, such as inlining and "precompilation"
        of fetch functions.
    }
]
comment {

    UCS means: Universal Character Set (or Unicode)
    UCS-2 means: 2-byte representation of a character in UCS.
    UCS-4 means: 4-byte representation of a character in UCS.
    UTF-8 means: UCS Transformation Format using 8-bit octets.


    The following excerpt from:
        UTF-8 and Unicode FAQ for Unix/Linux, by Markus Kuhn
        http://www.cl.cam.ac.uk/~mgk25/unicode.html
    provides motivations for using UTF-8.

    <<Using UCS-2 (or UCS-4) under Unix would lead to very severe
    problems. Strings with these encodings can contain as parts
    of many wide characters bytes like '\0' or '/' which have a
    special meaning in filenames and other C library function
    parameters. In addition, the majority of UNIX tools expects
    ASCII files and can't read 16-bit words as characters without
    major modifications. For these reasons, UCS-2 is not a suitable
    external encoding of Unicode in filenames, text files,
    environment variables, etc.

    The UTF-8 encoding defined in ISO 10646-1:2000 Annex D
    and also described in RFC 2279 as well as section 3.8
    of the Unicode 3.0 standard does not have these problems.
    It is clearly the way to go for using Unicode under Unix-style
    operating systems.>>

    The copy of forementioned Annex D can be found on Markus site:
    http://www.cl.cam.ac.uk/~mgk25/ucs/ISO-10646-UTF-8.html.
    Encoding and decoding functions implemented here are
    based on the descriptions of algorithms found in the Annex D.

    Testing: The page http://www.cl.cam.ac.uk/~mgk25/unicode.html
    has many pointers to variety of test data. One of them
    is a UTF-8 sampler from Kermit pages of Columbia University
    http://www.columbia.edu/kermit/utf8.html, where the
    phrase "I can eat glass and it doesn't hurt me." is
    produced in dozens of world languages.

}

comment {
------------------------------------------------------------
SUMMARY of script UTF-8.R
------------------------------------------------------------
encode      (integer -> string -> string)
decode      (integer -> string -> string)
to-ucs      (integer -> string -> string)

}
; do %/e/rebol/view/public/www.reboltech.com/library/scripts/hof.r
; do %/e/rebol/view/public/www.reboltech.com/library/scripts/utf-8.r
; x: "chars: ��������"
; y: encode 1 x
; t0: now/time/precise loop 1000 [decode 1 y] to decimal! now/time/precise - t0

    comment
    {
        A table of the three fetch functions for cases k = 1, 2, 4,
        where k is a number of octets to fetch.
        Each function reads k octets and attempts to convert
        them to a single character if possible, otherwise
        it computes an integer represented by those characters.
        Case 3 is just a dummy placeholder.
    }
    fetch: reduce [
        func[u][first u]
        func[u][
            either 0 < first u [
                0 + (second u) + (256 * first u)][second u]]
        3
        func[u /local z][
            z: 16777216 * first u
                 + (65536 * second u)
                 + (256 * third u)
            either 0 < z [z + fourth u][fourth u]
        ]
    ]

    comment
    {
        Data used by both 'encode and 'decode functions.
        Every non-zero element here has this property
        that its index within the block is equal to a total
        count of its consecutive most-significant 1-bits.
        The counter signals to the decoder a number of octets
        to use when decoding a character.
    }
    udata: [0 192 224 240 248 252]


    encode: func [
        {
        Encode string of k-wide characters into UTF-8 string,
        where k: 1, 2 or 4.
            (integer -> string -> string)
        }
        k [integer!]
        ucs [string!]
        /local c f x result [string!]
    ][
        result: make string! length? ucs
        f: pick fetch k
        parse/all ucs [any [c: k skip (
            either 128 > x: f c [
                insert tail result x
            ][
                either x < 256 [
                    insert insert tail result x / 64 or 192 x and 63 or 128
                ][
                    result: tail result
                    until [
                        insert result to char! x and 63 or 128
                        128 > x: x and -64 / 64
                    ]
                    insert result to char! x or pick udata 1 + length? result
                ]
            ]
        )]]
        head result
    ]


    decode: func [
        {
        Decode a UTF-8 encoded string into UCS-k string,
        where k = 1, 2, 4.
        Encoded strings which originated from Latin-1
        can be decoded with k = 1, 2, or 4.
        Other encoded Latin-m (m > 1) strings can be
        decoded either with k = 2 or k = 4,
        but not with k = 1.
        }
        k [integer!]
        xs [string!]
        /local m x c result [string!]
    ][
        result: make string! (length? xs) * k
        while [not tail? xs][
            x: first xs
            either x < 128 [
                insert insert/dup tail result #"^@" k - 1 x
            ][
                m: 8 - length? find enbase/base to binary! x 2 #"0"
                x: x xor pick udata m
                loop m - 1 [x: 64 * x + (63 and first xs: next xs)]
                result: tail result
                loop k - 1 [
                    insert result to char! x and 255
                    x: x and -256 / 256
                ]
                insert result to char! x
            ]
            xs: next xs
        ]
        head result
    ]


    to-ucs: func [
        {
        Convert 'ansi string to a string
        of wide characters: 1, 2, or 4 octets per
        character.
        This is an auxiliary function, just for testing.

        Note that when a UTF-encoded string is already
        available this function is no longer needed because
        such a string can be converted to a UCS-k string
        by simply invoking
            decode k utf-8-string .

        The condition is: k >= k-minimum. Hence
        any Latin-1 encoded string can be decoded to UCS-1,
        UCS-2 or UCS-4. Similarly, any Latin-2 encoded
        string can be decoded either to UCS-2 or UCS-4
        but not to UCS-1.
        }
        k [integer!]
        ansi [string!]
        /local c result [string!]
    ][
        either k > 1 [
            result: make string! (length? ansi) * k
            parse/all ansi [any [c:  skip (
                insert insert/dup tail result #"^@" (k - 1) first c
            )]]
        ][
            result: copy ansi
        ]
        result
    ]



    unicode-dir: %/e/rebol/unicode/

    comment {
        Some Microsoft Windows codepages:
    }
    charset-windows: map (func[u][rejoin [unicode-dir u]]) [
        %CP1252.TXT     ; Western Europe
        %CP1250.TXT     ; Central Europe
        ;%CP1257.TXT     ; Baltic
        %CP1251.TXT     ; Cyrillic
        ;%CP1253.TXT     ; Greek
        ;%CP1254.TXT     ; Turkish
        ;%CP1255.TXT     ; Hebrew
        ;%CP1256.TXT     ; Arabic
        ;%CP1258.TXT     ; Viat Nam
        ]

    comment {
        ISO-8859 character sets
    }
    charset-iso: map (func[u][rejoin [unicode-dir u]]) [
        %8859-1.TXT %8859-2.TXT %8859-3.TXT %8859-4.TXT %8859-5.TXT
        %8859-6.TXT %8859-7.TXT %8859-8.TXT %8859-9.TXT %8859-10.TXT
        %8859-11.TXT %8859-13.TXT %8859-14.TXT %8859-15.TXT %8859-16.TXT]


    comment {
        If standard 'debase does not work or crashes
        use this replacement.
    debase-16: func[
        x
    ][
        head insert tail insert x "16#{" "}"
    ]
    }


    cross-maps: func [
        {
        A sorted union of all cross-maps 'xs,
        such as 'charset-windows or 'charset-iso.
        }
        xs
        /local zs result
    ][
        zs: sort foldl1 :union (map :cross-map xs)
        result: make block! 2 * (length? zs)
        while [not tail? zs][
            insert tail result first zs
            zs: next zs
        ]
        to-hash result
    ]


    cross-map: func [
        {
        A block of pairs of codes read from
        a mapping 'file that maps an iso or a proprietary
        (MS, APPLE, ..) character set to a subset of unicode.

        All comments, empty lines and undefined elements
        have been removed. The 'file must be one of the
        cross mapping files published at
        http://www.unicode.org/Public/MAPPINGS/ .
        }
        file
        /local z u xs result
    ][
        xs: read/lines file
        result: copy []
        while [not tail? xs][
            x: first xs
            if (length? x) >= 11 [
                if (first x) <> #"#" [
                    z: make block! 2
                    u: debase/base copy/part skip x 7 4 16
                    if (length? u) > 0 [
                        insert z to-integer u
                        insert tail z to-integer debase/base copy/part skip x 2 2 16
                        insert/only tail result z
                    ]
                ]
            ]
            xs: next xs
        ]
        head result
    ]


    to-alias-string: func [
        {
        String of "narrow" characters mapped from a 'ucs
        string of k-wide characters to currently
        selected charset, where 'xs is a unicode-to-charset
        mapping hashtable.
        Unmatched unicode codes are substituted
        by a character corresponding to integer 'subst.
        }
        k [integer!]
        xs [hash!]
        str [string!]
        subst [integer!]
        /local x result [string!]
    ][
        f: pick fetch k
        result: make string! (length? str)
        while [not tail? str][
            x: to integer! f str
            insert tail result to-alias-char xs x subst
            str: skip str k
        ]
        result
    ]


    to-alias-char: func [
        {
        Character mapped from a unicode integer 'x
        to one of the characters from currently
        selected charset, where 'xs is a unicode-to-charset
        mapping hashtable.
        If no match is found return a substitute
        character corresponding to integer 'subst.
        }
        xs [hash!]
        x [integer!]
        subst [integer!]
        /local result [char!]
    ][
        result: select/skip xs x 2
        either not none? result [
            to char! first result
        ][
            to char! subst
        ]
    ]

    comment {
    ----------------------------------------------------------
    Everything below this is just for testing. Comment it
    out or remove if you wish.
    ----------------------------------------------------------
    }


    comment
        {
        A short sentence translated to a bunch of languages,
        from Latin-1,-2,-4,-5. For every keyword, such as 'Spanish
        there is a corresponding UTF-8 string.
        }
    glass:  [
        English {I can eat glass and it doesn't hurt me.}
            ; -- Latin-1 --
        French {Je peux manger du verre, cela ne me fait pas mal.}
        Quebecois {J'peux manger d'la vitre, ça m'fa pas mal.}
        Spanish {Puedo comer vidrio, no me hace daño.}
        Portuguese {Posso comer vidro, não me faz mal.}
        Irish {Is féidir liom gloinne a ithe. N� dhéanann s� dochar ar bith dom}
        Norwegian {Eg kan etas utan å skada meg.}
        Swedish {Jag kan äta glas, det skadar mig inte.}
        Danish {Jeg kan spise glas, det gør ikke ondt på mig.}
        Dutch {Ik kan glas eten. Het doet me geen pijn.}
        Finnish {Pystyn syömään lasia. Seei koske yhtään.}
            ; -- Latin-2 --
        Hungarian {Meg tudom enni az üveget, nem lesz tőle bajom}
        Polish {Mogę jeść szkło i mi nie szkodzi.}
        Czech {Mohu j�st sklo, neubl�ž�mi.}
        Slovak {Môžem jesť sklo. Nezran� ma.}
        Belarusian-Lacinka {Ja mahu jeści škło, jano mne ne škodzić.}
            ; -- Latin-4 --
        Estonian {Ma võin klaasi süüa, see ei tee mulle midagi.}
        Latvian {Es varu ēst stiklu, tas man nekaitē.}
        Lithuanian {Aš galiu valgyti stiklą ir jis manęs nežeidžia.}
            ; -- Latin-5 --
        Russian {Я могу е�?ть �?текло, оно мне не вредит.}
        Belarusian-Cyrillic {Я магу е�?ці шкло, �?но мне не шкодзіць.}
        Ukrainian {Я можу ї�?ти шкло, й воно мені не пошкодить. }
        Bulgarian {Мога да �?м �?тъкло и не ме боли. }
    ]


                                                                                                                                                                                                                                                                                                                                                                                                                                     