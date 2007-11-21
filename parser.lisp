(in-package :periods)

;;;_ * Simple numerics

;;;_  + Coded

(defprod p/ws () (+ (/ #\Space #\Tab #\Newline)))

(defchartype p/digit '(satisfies digit-char-p))

(defprod p/digits () (+ p/digit))

(defprod p/number ()
  (^ p/digits (parse-integer p/digits)))

;;;_  + English units

(defprod p/cardinal ()
  (/
   (^ p/number p/number)
   (^ "one" 1)
   (^ "two" 2)
   (^ "three" 3)
   (^ "four" 4)
   (^ "five" 5)
   (^ "six" 6)
   (^ "seven" 7)
   (^ "eight" 8)
   (^ "nine" 9)
   (^ "ten" 10)))

(defprod p/ordinal ()
  (/ 
   (^ (/ "1st" "first") (list :ordinal 1))
   (^ "other" (list :other))
   (^ (/ "2nd" "second") (list :ordinal 2))
   (^ (/ "3rd" "third") (list :ordinal 3))
   (^ (/ "4th" "fourth") (list :ordinal 4))
   (^ (/ "5th" "fifth") (list :ordinal 5))
   (^ (/ "6th" "sixth") (list :ordinal 6))
   (^ (/ "7th" "seventh") (list :ordinal 7))
   (^ (/ "8th" "eighth") (list :ordinal 8))
   (^ (/ "9th" "ninth") (list :ordinal 9))
   (^ (/ "10th" "tenth") (list :ordinal 10))))

(defprod p/days-of-week ()
  (/
   (^ "sunday" :sun)
   (^ "monday" :mon)
   (^ "tuesday" :tue)
   (^ "wednesday" :wed)
   (^ "thursday" :thu)
   (^ "friday" :fri)
   (^ "saturday" :sat)))

(defprod p/months-of-year ()
  (/
   (^ (/ "January" "january" "Jan" "jan") 1)
   (^ (/ "February" "january" "Jan" "jan") 2)
   (^ (/ "March" "march" "Mar" "mar") 3)
   (^ (/ "April" "april" "Apr" "apr") 4)
   (^ (/ "May" "may") 5)
   (^ (/ "June" "june" "Jun" "jun") 6)
   (^ (/ "July" "july" "Jul" "jul") 7)
   (^ (/ "August" "august" "Aug" "aug") 8)
   (^ (/ "September" "september" "Sep" "sep") 9)
   (^ (/ "October" "october" "Oct" "oct") 10)
   (^ (/ "November" "november" "Nov" "nov") 11)
   (^ (/ "December" "december" "Dec" "dec") 12)))

(defprod p/time-unit ()
  (/
   (^ "millisecond" :millisecond)
   (^ "second" :second)
   (^ "minute" :minute)
   (^ "hour" :hour)
   (^ "day" :day)
   (^ "week" :day-of-week)
   (^ "month" :month)
   (^ "year" :year)))

(defprod p/period-unit ()
  (/
   (^ "per-millisecond"  :per-millisecond)
   (^ "per-second"       :per-second)
   (^ "per-minute"       :per-minute)
   (^ "hourly"           :hourly)
   (^ "daily"            :daily)
   (^ "weekly"           :weekly)
   (^ "monthly"          :monthly)
   (^ (/ "yearly" "annually") :yearly)))

;;;_ * A fixed point in time

(defprod p/fixed-time (year month day)
  (/
   (^ "now" (list :fixed :now))
   (^ "today" (list :rel :today))
   (^ "tomorrow" (list :rel :tomorrow))
   (^ "yesterday" (list :rel :yesterday))

   (^ ((^ p/number (setf year p/number)) "/"
       (^ p/number (setf month p/number))
       (? ("/" (^ p/number (setf day p/number)))))
      (if day
	  (list :fixed :year year :month month :day day)
	  (list :fixed :year year :month month :day day)))

   (^ (p/months-of-year (? p/ws (/ p/ordinal p/cardinal)))
      (let ((number (or p/ordinal p/cardinal)))
	(if number
	    (list :rel :month p/months-of-year
		  (if (> number 40) :year :day) number)
	    (list :rel :month p/months-of-year))))))

;;;_ * A duration of time

(defprod p/time-duration (duration)
  (^ ((^ p/duration-spec (setf duration p/duration-spec))
      (? (+
	  ((/ ("," (? p/ws))
	      (p/ws "and" p/ws)
	      ("," (? p/ws) "and" p/ws))
	   (^ p/duration-spec
	      (nconc duration p/duration-spec))))))
     (cons :duration duration)))

(defprod p/duration-spec (reverse moment)
  (^ ((? (/ "a" "the" p/cardinal) p/ws) p/time-unit (? #\s))
     (list p/time-unit (or p/cardinal 1))))

;;;_ * A relative point in time

(defprod p/relative-time ()
  (/
   (^ ("this" (? p/ws p/time-reference))
      (list :rel :this p/time-reference))

   (^ ((? "the") (/ "next" "this next" "the following")
       (? p/ws p/time-reference))
      (list :rel :next p/time-reference))

   (^ ((? "the") (/ "last" "this last" "this past" "the preceding")
       (? p/ws p/time-reference))
      (list :rel :last p/time-reference))

   (^ ((/ p/cardinal ((? "the" p/ws) p/ordinal))
       p/ws p/time-reference (? #\s))
      (list (or p/cardinal p/ordinal) p/time-reference))

   (^ ((/ "before" "prior to" "prior") p/ws p/time-reference)
      (list :rel :before p/time-reference))

   (^ ("after" p/ws p/time-reference)
      (list :rel :after p/time-reference))

   (^ ((/ "beginning"
	  ("the" p/ws "beginning" p/ws "of"))
       p/ws p/time-reference)
      (list :rel :begin p/time-reference))

   (^ ((/ "beginning"
	  ("the" p/ws "beginning" p/ws "of")
	  "starting"
	  ("the" p/ws "start" p/ws "of")
	  "from"
	  "since")
       p/ws p/time-reference)
      (list :rel :from p/time-reference))

   (^ ((/ "in" "during")
       p/ws p/time-reference)
      (list :rel :in p/time-reference))
   
   (^ ((/ "ending"
	  ("the" p/ws "end" p/ws "of")
	  "stopping"
	  "finishing"
	  "to"
	  "until")
       (p/ws p/time-reference))
      (list :rel :to p/time-reference))

   (^ ("of" p/ws p/time-reference)
      (list :rel :of p/time-reference))
   
   (^ ((/ "ending"
	  ("the" p/ws "end" p/ws "of"))
       (p/ws p/time-reference))
      (list :rel :end p/time-reference))))

;;;_ * The high-level entry point

(defprod p/time-reference ()
  (/
   (^ p/fixed-time     p/fixed-time)
   (^ p/days-of-week   p/days-of-week)
   (^ p/period-unit    p/period-unit)
   (^ p/time-duration  p/time-duration)
   (^ p/relative-time  p/relative-time)))

(defprod p/qualified-time (quantity everyp)
  (^ ((^ ((? (^ "every"
		(setf everyp t)) p/ws) p/time-reference)
	 (setf quantity
	       (if everyp
		   (list :every p/time-reference)
		   p/time-reference)))
      (? (+ p/ws
	    (^ p/qualified-time
	       (setf quantity (list quantity p/qualified-time))))))
     quantity))

(defprod p/time (quantity)
  (^ ((^ p/qualified-time (setf quantity p/qualified-time))
      (? p/ws (^ "ago"
		 (setf quantity (list :ago quantity)))))
     quantity))

;;;_ * A recurring period of time

(defprod p/time-period ()
  (/
   ;; monthly [from now until when]
   (^ (p/time-step (? (p/ws p/time-range)))
      (time-period :range p/time-range :step p/time-step :skip nil))

   ;; every 2 weeks for a year ...
   (^ (p/time-step "for" p/time-duration (? (p/ws p/time-range)))
      (time-period :range p/time-range :step p/time-step :skip nil))

   ;; (for) 2 hours weekly ...
   (^ ((? "for") p/time-duration p/time-step (? (p/ws p/time-range)))
      (time-period :range p/time-range :step p/time-step :skip nil))))

(defprod p/time-step ()
  (/
   (^ ("every" p/ws p/time-duration) p/time-duration)
   (^ p/period-unit p/period-unit)))

;;;_ * These are the top level entry points, which return real objects

;;(defparser fixed-time-parser
;;    (^ p/time-range
;;       (calculate-anchor p/time-range)))
;;
;;(defun parse-fixed-time (string)
;;  (multiple-value-bind (ok value) (fixed-time-parser string)
;;    (if ok value nil)))
;;
;;(defparser duration-parser
;;    (^ p/time-duration
;;       (progn
;;	 ;; for side effects...
;;	 (calculate-anchor p/time-duration)
;;	 (time-quantity-duration p/time-duration))))
;;
;;(defun parse-duration (string)
;;  (multiple-value-bind (ok value) (duration-parser string)
;;    (if ok value nil)))
;;
;;(defparser time-range-parser
;;    (^ p/time-range
;;       (progn
;;	 ;; for side effects...
;;	 (calculate-anchor p/time-range)
;;	 (time-range :begin (time-quantity-anchor p/time-range)
;;		     :end (time-quantity-terminus p/time-range)
;;		     :duration (time-quantity-duration p/time-range)))))
;;
;;(defun parse-time-range (string)
;;  (multiple-value-bind (ok value) (time-range-parser string)
;;    (if ok value nil)))
;;
;;(defparser time-period-parser (^ p/time-period))
;;
;;(defun parse-time-period (string)
;;  (multiple-value-bind (ok value) (time-period-parser string)
;;    (if ok value nil)))

(defparser time-parser (^ p/time))

(defun parse-time (string)
  (multiple-value-bind (ok value) (time-parser string)
    (if ok value nil)))

(defmacro tdp (production input)
  `((lambda (x)
      (parselet ((foo (^ ,production)))
        (foo x))) ,input))

(defun time-parser-tests ()
  (dolist
      (expr '("this year"
	      "next year"
	      "last year"
	      "the year before last"
	      "jan 8"
	      "jan 2008"
	      "2008/01/01"
	      "2 months"
	      "2 months since jan 8"
	      "january of last year"
	      "three months ago"
	      "1 months, 2 days ago"
	      "every friday starting tomorrow"
	      "every day this week"
	      "every day of this week"
	      "every ten days"
	      "the day after tuesday"
	      "monthly"
	      "monthly from the beginning of this year"
	      "monthly from now until the end of the year"
	      "the last week of last year"
	      ))
    (format t "EXPR <  ~A~%     >= ~S~%" expr
	    (parse-time expr))))
