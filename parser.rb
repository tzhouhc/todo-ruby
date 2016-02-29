#!/usr/bin/env ruby
require 'rly'
require 'time'
# Contains Lexer and Parser definitions.

# Lexer class.
class TimeLex < Rly::Lex
  ignore " \t\n"

  token :TIMEOFDAY, /(morning)|(afternoon)|(noon)|(evening)|((mid)?night)/i do |t|
    t.value = case t.value
              when /morning/i # 9AM
                3 / 8.to_r
              when /afternoon/i # 2PM
                7 / 12.to_r
              when /noon/i # 12PM
                1 / 2.to_r
              when /evening/i # 6PM
                3 / 4.to_r
              when /midnight/i # 11:59PM
                1439 / 1440.to_r
              when /night/i # 9PM
                7 / 8.to_r
              end
    t
  end

  token :TIMEINDAY, /\d\d?\:(\d\d?)?/i do |t|
    t.value = (Time.parse(t.to_s) - Date.today.to_time).to_i / 86_400.to_r
    t
  end

  token :TIMEINDAY12, /\d\d?(\:\d\d?)? ?(am|pm)/i do |t|
    t.value = (Time.parse(t.to_s) - Date.today.to_time).to_i / 86_400.to_r
    t
  end

  # time units: are time intervals
  token :DAY, /days?/i do |t|
    t.value = 1
    t
  end
  token :WEEK, /weeks?/i do |t|
    t.value = 7
    t
  end
  token :MONTH, /months?/i do |t|
    t.value = 30
    t
  end
  token :HOUR, /h(our)?s?/i do |t|
    t.value = 1 / 24.to_r
    t
  end
  token :MINUTE, /m|(min)|(minute)s?/i do |t|
    t.value = 1 / 1440.to_r
    t
  end

  # absolutes: are dates
  token :DATE, %r{\d\d?[\/-]\d\d?([\/-]\d\d(\d\d)?)?} do |t|
    t.value = Date.parse(t.value)
    t
  end

  # var modifier
  token :NEXT, /next/i

  # variables
  token :MONTHDAY, /(\d\d?th)|(\d\d?nd)|(\d\d?st)/i do |t|
    t.value = Date.parse(t.value)
    t
  end

  token :YESTERDAY, /yesterday/i do |t|
    t.value = Date.today - 1
    t
  end
  token :TODAY, /today/i do |t|
    t.value = Date.today
    t
  end
  token :TOMORROW, /tomorrow/i do |t|
    t.value = Date.today + 1
    t
  end

  token :WEEKDAY, /\w+day/i do |t|
    date = Date.parse(t.value)
    t.value = date
    t
  end

  # numbers
  token :NUMBER, /\d+/ do |t|
    t.value = t.value.to_i
    t
  end

  # prepositions
  token :IN, /in/i
  token :FROM, /from/i
  token :TO, /to(?!d)/i
  token :AFTER, /after/i
  token :UNTIL, /until/i
  token :LATER, /later/i
  token :AND, /and/i
  token :COMMA, /,/i

  # English numberal
  token :ENUMBER, /(the)|a|(one)|(two)|(three)|(four)|(five)|(six)|(seven)|(eight)|(nine)|(ten)/i do |t|
    t.value = case t.value
              when /the/i
                1
              when /a|(one)/i
                1
              when /two/i
                2
              when /two/i
                2
              when /three/i
                3
              when /four/i
                4
              when /five/i
                5
              when /six/i
                6
              when /seven/i
                7
              when /eight/i
                8
              when /nine/i
                9
              when /ten/i
                10
              end
    t
  end
end

# Parser class.
# PENDING MODIFICATION.
class TimeParse < Rly::Yacc
  # a time can be a timepoint
  rule 'time : timepoint' do |st, e|
    st.value = e.value
  end

  rule 'time : timeperiod FROM timepoint | timeperiod AFTER timepoint' do |st, e1, _, e2|
    st.value = e2.value + e1.value
  end

  rule 'time : timeperiod TO timepoint | timeperiod UNTIL timepoint' do |st, e1, _, e2|
    st.value = e2.value - e1.value
  end

  rule 'time : IN timeperiod' do |st, _, e|
    st.value = Date.today + e.value
  end

  rule 'time : timeperiod LATER' do |st, e, _|
    st.value = Date.today + e.value
  end

  rule 'timepoint : daypoint' do |st, e|
    st.value = e.value
  end

  rule 'daypoint : DATE' do |st, e|
    st.value = e.value
  end

  rule 'daypoint : TODAY | YESTERDAY | TOMORROW | WEEKDAY | MONTHDAY' do |st, e|
    st.value = e.value
  end

  rule 'daypoint : NEXT WEEKDAY' do |st, _, e|
    st.value = e.value + 7
  end

  rule 'daypoint : NEXT MONTHDAY' do |st, _, e|
    st.value = e.value.next_month
  end

  rule 'timepoint : daypoint TIMEOFDAY | daypoint TIMEINDAY | daypoint TIMEINDAY12' do |st, e1, e2|
    st.value = e1.value + e2.value
  end

  rule 'timeunit : DAY | WEEK | MONTH | HOUR | MINUTE' do |st, e|
    st.value = e.value
  end

  rule 'timeperiod : timeunit' do |st, e|
    st.value = e.value
  end

  rule 'timeperiod : NUMBER timeunit | ENUMBER timeunit' do |st, n, e|
    st.value = n.value * e.value
  end

  rule 'timeperiod : timeperiod AND timeperiod | timeperiod COMMA timeperiod' do |st, e1, _, e2|
    st.value = e1.value + e2.value
  end
end

# text = '2 hours after tomorrow 2pm'
# lex = TimeLex.new(text)
# while (t = lex.next)
#   p t
# end

# parser = TimeParse.new(TimeLex.new)
# p parser.parse(text)
