#!/usr/bin/env ruby
# frozen_string_literal: true

require 'colorize'

def color_arrow(text, text_color, arrow_color, next_color)
  " #{text} ".colorize(color: text_color, background: arrow_color) \
  + "".colorize(color: arrow_color, background: next_color)
end

def long_arrow(strings, foregrounds, backgrounds)
  raise 'Parameters of unequal length' unless strings.size == foregrounds.size && strings.size == backgrounds.size
  result = ''
  (0...strings.size).each do |i|
    result += color_arrow(strings[i], foregrounds[i], backgrounds[i], backgrounds[i + 1])
  end
  result
end

def long_arrow_alt(tuples)
  result = ''
  (0...tuples.size).each do |i|
    result += color_arrow(tuples[i][0], tuples[i][1], tuples[i][2], tuples[i + 1] ? tuples[i + 1][2] : nil)
  end
  result
end
