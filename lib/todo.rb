#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative './draw_arrow.rb'
require 'chronic'

DAY = 86_400
HOUR = 3600

URGENT_DAYS = 2 # number of days due in before considered as urgent
NORMAL_DAYS = 5 # likewise, but for tasks to be considered 'no rush'
URGENT_THRESHOLD = DAY * URGENT_DAYS # same thing, in seconds
NORMAL_THRESHOLD = DAY * NORMAL_DAYS # likewise

TASKLIST_LENGTH = 4 # how many tasks to display by default

TODO_STORAGE = ENV['HOME'] + '/.todo'
File.write(TODO_STORAGE, Marshal.dump([])) unless File.file?(TODO_STORAGE)

def sort_tasklist(tasklist)
  # in-place sort the tasklist
  tasklist.sort_by! do |e| # sort: by date, and put nil last
    if e[1]
      e[1] # this would be a date, like '2016-02-01'
    else
      Time.parse('2099-02-03T04:05:06+07:00')
      # a date so late that it probably is later than the others
    end
  end
end

def read_to_tasklist
  # obtain the tasklist from a file and sort it
  tasklist = []
  File.open(TODO_STORAGE, 'r') do |file|
    content = file.read
    tasklist += Marshal.load(content) # read in the rest
  end
  sort_tasklist(tasklist)
  tasklist
end

def write_to_file(tasklist)
  # sort a tasklist and store it
  sort_tasklist(tasklist)
  data = Marshal.dump(tasklist) # then store the data
  File.write(TODO_STORAGE, data)
end

def limit_to_show(tasklist, showall)
  if showall
    tasklist
  else
    shortlist = tasklist.select do |line|
      _task, date = line
      date && date - Time.now < NORMAL_THRESHOLD
    end
    shortlist.size < TASKLIST_LENGTH ? shortlist = tasklist[0..TASKLIST_LENGTH] : shortlist
    shortlist
  end
end

def diff_to_text(duration)
  # convert a duration time to due time in words
  days = (duration / DAY).to_i
  hours = ((duration - days * DAY) / HOUR).to_i
  minutes = ((duration % HOUR) / 60).to_i
  day_with_s = days > 1 ? 'days' : 'day'
  hour_with_s = hours > 1 ? 'hours' : 'hour'
  minute_with_s = minutes > 1 ? 'minutes' : 'minute'
  if days > 0
    if days >= URGENT_DAYS
      "due in #{days} days"
    elsif hours > 0
      "due in #{days} #{day_with_s} #{hours} #{hour_with_s}"
    else
      "due in #{days} #{day_with_s}"
    end
  elsif hours > 0
    "due in #{hours} #{hour_with_s} #{minutes} #{minute_with_s}"
  else
    duration > 0 ? "due in #{minutes} #{minute_with_s}" : 'past due'
  end
end

def choose_color_by_diff(duration)
  if duration > NORMAL_THRESHOLD
    :green
  elsif duration > URGENT_THRESHOLD
    :yellow
  else
    :red
  end
end

def print_task(index, line, powerline)
  task, due = line
  if due
    diff = due - Time.now
    due_time = diff_to_text(diff)
    color = choose_color_by_diff(diff)
    if powerline
      puts long_arrow_alt([[index, :red, :black], [task, :black, :blue], [due_time, :black, color]])
    else
      puts " #{index.to_s.yellow}\t| #{task.blue}: #{due_time.to_s.colorize(color)}"
    end
  elsif powerline
    puts long_arrow_alt([[index, :red, :black], [task, :black, :blue]])
  else
    puts " #{index.to_s.yellow}\t| #{task.blue}"
  end
end

def print_tasklist(tasklist, powerline)
  tasklist.each_with_index { |line, index| print_task(index, line, powerline) }
end

def display_tasklist(tasklist, showall, powerline)
  tasklist = limit_to_show(tasklist, showall)
  print_tasklist(tasklist, powerline)
end

def count_urgent(tasklist)
  tasklist.count { |line| line[1] && line[1] - Time.now <= URGENT_THRESHOLD }
end
