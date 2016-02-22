#!/usr/bin/env ruby
require 'rly'
require 'time'
# Contains Lexer and Parser definitions.

# Lexer class.
class TimeLex < Rly::Lex
  ignore " \t\n"

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

  # English numberal
  token :ENUMBER, /(the)|a(?= )|(one)|(two)|(three)|(four)|(five)|(six)|(seven)|(eight)|(nine)|(ten)/i do |t|
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
class TimeParse < Rly::Yacc
  rule 'time : timepoint' do |st, e|
    st.value = e.value
  end

  rule 'time : timeperiod FROM timepoint | timeperiod AFTER timepoint' do |st, e1, _f, e2|
    st.value = e2.value + e1.value
  end

  rule 'time : timeperiod TO timepoint' do |st, e1, _f, e2|
    st.value = e2.value - e1.value
  end

  rule 'time : IN timeperiod' do |st, _f, e|
    st.value = Date.today + e.value
  end

  rule 'timepoint : DATE' do |st, e|
    st.value = e.value
  end

  rule 'timepoint : TODAY | YESTERDAY | TOMORROW | WEEKDAY | MONTHDAY' do |st, e|
    st.value = e.value
  end

  rule 'timepoint : NEXT WEEKDAY' do |st, _f, e|
    st.value = e.value + 7
  end

  rule 'timepoint : NEXT MONTHDAY' do |st, _f, e|
    st.value = e.value.next_month
  end

  rule 'timeunit : DAY | WEEK | MONTH' do |st, e|
    st.value = e.value
  end

  rule 'timeperiod : timeunit' do |st, e|
    st.value = e.value
  end

  rule 'timeperiod : NUMBER timeunit | ENUMBER timeunit' do |st, n, e|
    st.value = n.value * e.value
  end
end

# parser = TimeParse.new(TimeLex.new)
# p parser.parse('next 15th').to_s
