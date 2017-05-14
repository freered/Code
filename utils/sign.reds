	sign?*: func [
		check?  [logic!]
		return: [red-integer!]
		/local
			i   [red-integer!]
			f	[red-float!]
			res [red-logic!]
			ret [integer!]
	][
		#typecheck -sign?-								;-- `sign?` would be replaced by lexer
		res: as red-logic! stack/arguments
		ret: 0
		switch TYPE_OF(res) [							;@@ Add money! pair!
			TYPE_INTEGER [
				i: as red-integer! res
				case [
					i/value > 0 [ret:  1]
					i/value < 0 [ret: -1]
					i/value = 0 [ret:  0]
				]
			]
			TYPE_FLOAT [
				f: as red-float! res
				case [
					f/value > 0.0 [ret:  1]
					f/value < 0.0 [ret: -1]
					f/value = 0.0 [ret:  0]
				]
			]
			TYPE_TIME [
				f: as red-float! res
				case [
					f/value > 0.0 [ret:  1]
					f/value < 0.0 [ret: -1]
					f/value = 0.0 [ret:  0]
				]
			]
			default [ERR_EXPECT_ARGUMENT((TYPE_OF(res)) 1)]
		]
		integer/box ret
	]
