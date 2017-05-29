;; ==========================================
;; Script: date-time.r
;; downloaded from: www.REBOL.org
;; on: 14-May-2017
;; at: 8:21:19.889817 UTC
;; owner: fvzv [script library member who can
;; update this script]
;; ==========================================
;; ==================================================
;; email address(es) have been munged to protect them
;; from spam harvesters.
;; If you were logged on the email addresses
;; would not be munged
;; ==================================================
REBOL [
	file: %date-time.r
	title: "Date and time functions"
	date: 24-Feb-2011
	version: 1.1
	home: http://rebol.x10.mx
	author: "Francois Vanzeveren"
	email: %brainois--rebol--x10--mx
	purpose: {
		This script contains the Rebol implementation of some date and time functions provided in 
		the glibc library and the gnumeric (and therefore Microsoft Excel) software.
		While the use and handling of date and time data are in most cases straightforward 
		with Rebol, some of the advanced date and times functionalities found in glibc and 
		gnumeric are still missing in Rebol.
		This script is therefore an attempt to fill the gap.
	}
	language: "English"
	history: [
		1.1 24-Feb-2011 "Francois Vanzeveren" {
			BUG: the function 'week-of-year was not correctly implemented, sometimes 
				returning 0 as week number for the first week of the year.
			CLEANSING: iso-week-num removed (redundant with week-of-year/iso)
		}
		1.0 05-Jan-2003 "Francois Vanzeveren" "First public release"
	]
	library: [
		level: 'intermediate
		platform: 'all
		type: [function tool]
		domain: [extension financial]
		tested-under: [linux windows]
		support: none
		license: 'lgpl
		see-also: none
	]
]
;					M T W T F S S
;_base-monday: copy [1 2 3 4 5 6 7]
_base-sunday: copy [2 3 4 5 6 7 1]

end-of-month: function [
{
	Returns the last day of the month which is @months from the @start-date.
}
	start-date [date!]
	months [integer!]
] [
	last-day [integer!]
	new-month [integer!]
	new-year [integer!]
] [
	either greater-or-equal? months 0 [
		new-year: add start-date/year to-integer divide add start-date/month months 12
		new-month: remainder add start-date/month months 12
	] [
		either greater? start-date/month absolute months [
			new-year: start-date/year
			new-month: add start-date/month months
		] [
			new-year: add start-date/year subtract to-integer divide add start-date/month months 12 1
			new-month: add 12 remainder add start-date/month months 12
		]
	]
	last-day: multiply 31 to-integer found? find [0 1 3 5 7 8 10 12] new-month
	if all [not to-logic last-day found? find [4 6 9 11] new-month ] [
		last-day: 30
	]
	if not to-logic last-day [
		last-day: add 28 to-integer leap-year? make date! reduce [1 1 new-year]
	]
	make date! reduce [last-day new-month new-year]
]

end-of-month?: function [
{
	Returns true if @a-date is the last day of its month.
}
	a-date [date!]
] [] [
	equal? a-date end-of-month a-date 0
]

leap-year?: function [
{
	Returns true for a leap year.
}
	date [date!] "The date to check."
] [year [integer!]] [
	 year: date/year
	 any [
		 all [
			 equal? 0 remainder year 4
			 not-equal? 0 remainder year 100
		 ]
		 equal? 0 remainder year 400
	 ]
]
	 
date-dif: function [
{
	Returns the difference between two dates.
}
	date1 [date!]
	date2 [date!]
	/y	{Returns the number of complete years between @date1 and @date2.}
	/m	{Returns the number of complete months between @date1 and @date2.}
	/d	{Returns the number of complete days between @date1 and @date2.}
	/ym	{Returns the number of full months between @date1 and @date2, 
		not including the difference in years.}
	/md	{Returns the number of full days between @date1 and @date2,
		not including the difference in months.}
	/yd	{Returns the number of full days between @date1 and @date2, 
		not including the difference in years.}
] [] [
	if y [
		return 
		subtract
		subtract date2/year date1/year 
		to-integer	any [ 	lesser? date2/month date1/month 
							all [	equal? date2/month date1/month
									lesser? date2/day date1/day
							]
					]
	]
	if m [
		return 
		subtract
		subtract
		add 
		multiply
		subtract date2/year date1/year
		12
		date2/month
		date1/month
		to-integer lesser? date2/day date1/day
	]
	if ym [
		return 
		either any [lesser? date1/month date2/month
					all [ equal? date1/month date2/month
						lesser-or-equal? date1/day date2/day
					]
		] [
			subtract
			subtract date2/month date1/month
			to-integer greater? date1/day date2/day
		] [
			subtract
			add
			subtract 12 date1/month
			date2/month
			to-integer greater? date1/day date2/day
		]
	]
	if md [
		return 
		subtract
		add date2/day
		multiply get-refinement end-of-month date2 -1 'day to-integer greater? date1/day date2/day
		date1/day
	]
	if yd [
		if all [equal? date1/day date2/day
				equal? date1/month date2/month
		] [ return 0 ]
		return
		either any [
			greater? date2/month date1/month
			all [
				equal? date2/month date1/month
				greater? date2/day date1/day
			]
		] [
			use [ start-date [date!]] [
				start-date: make date! reduce [date1/day date1/month date2/year]
				subtract date2 start-date
			]
		] [
			use [ start-date [date!]] [
				start-date: make date! reduce [date1/day date1/month subtract date2/year 1 ]
				subtract date2 start-date
			]
		]
	]
	
	return subtract date2 date1
]

days360: function [
{
	Returns the number of days from @date1 to @date2 
	following a 360-day calendar in which all months 
	are assumed to have 30 days. By default, the US method is used.
}
	date1 [date!] "Starting date"
	date2 [date!] "Ending date"
	/euro {The European method will be used. In this case, if the day of 
		the month is 31 it will be considered as 30.}
	/us {U.S. (NASD) method. If the starting date is the 31st of a month, 
		it becomes equal to the 30th of the same month. If the ending 
		date is the 31st of a month and the starting date is earlier 
		than the 30th of a month, the ending date becomes equal to 
		the 1st of the next month, otherwise the ending date becomes 
		equal to the 30th of the same month.
		This is the default behaviour.}
] [] [
	either euro [
		;euro
		date1: subtract date1 to-integer equal? date1/day 31
		date2: subtract date2 to-integer equal? date2/day 31
	] [
		;US or default
		either all [
			end-of-month? date1
			end-of-month? date2
		] [
			date1/day: min date1/day date2/day
			date2/day: min date1/day date2/day
		] [
			date1: subtract date1 to-integer all [
				equal? date1/day 31
				any [ not-equal? date1/month date2/month
					not-equal? date1/year date2/year
					equal? date2/day 30
				]
			]
			if all [ equal? date1/month 2 ; February
				equal? date1/day 29 ; End of february for leap year...
				greater-or-equal? date2 subtract end-of-month date1 0 1
				any [ not-equal? date1/month date2/month
					not-equal? date1/year date2/year
				]
			] [
				date2: subtract date2 1
			]
			if equal? date2/day 31 [
				either lesser? date1/day 30 [
					date2: add date2 1
				][
					date2: subtract date2 1
				]
			]
		]
	]
	return
		add
		add
		multiply date-dif/m date1 date2 30
		multiply 30 to-integer lesser? date2/day date1/day
		subtract date2/day date1/day
]

edate: function [
{
	Returns the date that is the specified number of months 
	before or after a given date.
}
	initial-date [date!] "The initial date."
	months [integer!] {The number of months before (negative number) or 
		after (positive number) the initial date.}
] [
	new-day [integer!]
	new-month [integer!]
	new-year [integer!]
	new-date [integer!]
] [
	new-day: initial-date/day
	new-month: remainder add initial-date/month months 12
	new-year: add initial-date/year to-integer divide add initial-date/month months 12
	new-date: end-of-month make date! reduce [1 new-month new-year] 0
	if lesser? new-day new-date/day [
		new-date/day: new-day
	]
	return new-date
]

day-of-year: function [
{
	Returns the day number within @the-date/year.
	The first day of the year has value 1.
}
	the-date [date!]
] [] [
	add 1 subtract the-date make date! reduce [the-date/year 1 1]
]

week-of-year: function [
{
	Return the week of the year.
	The first week of the year has value 1.
}
	the-date [date!]
	/monday "Weeks are understood to start on Monday"
	/sunday "Weeks are understood to start on Sunday."
	/iso {Returns the ISO 8601 week number of @the-date.
		An ISO 8601 week starts on Monday. Weeks are numbered from 1.
		Week 01 of a year is per definition the first week that 
		has the Thursday in this year, which is equivalent to 
		the week that contains the fourth day of January. In other 
		words, the first week of a new year is the week that has 
		the majority of its days in the new year. Week 01 might also 
		contain days from the previous year and the week before week 
		01 of a year is the last week (52 or 53) of the previous year 
		even if it contains days from the new year.
		See http://www.techno-science.net/?onglet=glossaire&definition=3075
	}
] [
	week [integer!]
	wd [integer!]
	day [integer!]
	jan1date [date!]
	mon [date!]
	thur [date!]
] [	
	either iso [
		thur: add the-date 
				subtract 4 the-date/weekday
		mon: make date! reduce [thur/year 1 4]
		mon: add mon 
				subtract 1 mon/weekday
		week: round/ceiling divide subtract thur mon 7
	] [
		jan1date: make date! reduce [the-date/year 1 1]
		wd: jan1date/weekday ; Weeks are understood to start on Monday
		if sunday [
			; Weeks are understood to start on Sunday 
			wd: pick _base-sunday wd
		]
		wd: subtract wd 1
		day: subtract day-of-year the-date 1
		week: add 1 to-integer divide add day wd 7
	]
	
	week ; return value
]

net-work-days: function [
{
	Returns the number of whole working days, beginning with 
	@start_date and ending with @end_date, excluding days in 
	@dates and weekends.
}
	start-date [date!]
	end-date [date!]
	/holidays dates [block!]
] [
	nb-of-holidays [integer!]
	diff-in-weeks [integer!]
	first-week-nwd [integer!] ; first week non weekend days
	last-week-nwd [integer!] ; last week non weekend days
	non-weekend-days [integer!]
	first-monday [date!] ; the first monday of the period, first week not included.
	last-friday [date!] ; the last friday of the period, last week not included.
] [
	if greater? start-date end-date [
		use [tmp-date [date!]] [
			tmp-date: end-date
			end-date: start-date
			start-date: tmp-date
		]
	]
	
	nb-of-holidays: 0
	if holidays [
		; Computes the number of holidays within the period
		foreach item dates [
			if all [
				date? item
				lesser-or-equal? item/weekday 5 ; saturday and sunday are not holidays, but weekend days
				greater-or-equal? item start-date
				lesser-or-equal? item end-date
			][
				nb-of-holidays: add nb-of-holidays 1
			]
		]
	]
	
	; number of non weekend days during the first week of the period
	first-week-nwd: multiply 
		to-integer lesser-or-equal? start-date/weekday 5
		add 1 subtract 5 start-date/weekday
	; number of non weekend days during the last week of the period
	last-week-nwd: either lesser-or-equal? end-date/weekday 5 [ end-date/weekday ] [5]
	
	; the first monday of the period, first week not included.
	first-monday: add start-date add 1 subtract 7 start-date/weekday
	; the last friday of the period, last week not included.
	last-friday: subtract end-date add 2 end-date/weekday
	
	non-weekend-days: either greater? last-friday first-monday [
		diff-in-weeks: to-integer divide add 1 subtract last-friday first-monday 7
		add first-week-nwd
		add last-week-nwd
		add 5 multiply 5 diff-in-weeks
	] [
		subtract
			add first-week-nwd last-week-nwd
			multiply 5 to-integer equal? 
				subtract end-date/weekday start-date/weekday 
				subtract end-date start-date ; start-date and end-date are in the same week!
	]
	; return value
	subtract non-weekend-days nb-of-holidays
]

work-day: function [
{
	Returns the day which is @days working days from the @start-date. 
	Weekends and holidays optionally supplied in @dates are respected.
}
	start-date [date!]
	days [integer!]
	/holidays dates [block!]
] [
	weekend-days [integer!]
	end-date [date!]
	days-gap [integer!]
] [
	if not holidays [
		dates: make block! []
	]
	weekend-days: multiply 2
		subtract
			to-integer divide days 5
			to-integer equal? remainder days 5 0
			
	end-date: add start-date add days weekend-days
	days-gap: add 1 subtract absolute days net-work-days/holidays start-date end-date dates
	while [ not-equal? days-gap 0 ] [
		end-date: either positive? days [add end-date days-gap] [subtract end-date days-gap]
		days-gap: add 1 subtract absolute days net-work-days/holidays start-date end-date dates
	]
	if negative? days [
		while [found? find dates end-date] [
			end-date: add end-date 1
		]
	]
	; return value
	end-date
]
