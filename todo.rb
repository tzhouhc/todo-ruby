#!/usr/bin/env ruby

require 'trollop'
require 'colorize'
require_relative 'parser.rb'

parser = TimeParse.new(TimeLex.new)

opts = Trollop.options do
  opt :add, 'Add an item to the to-do list.', default: nil, type: :string
  opt :done, 'Mark some items on the to-do list as done.', default: nil, type: :ints
  opt :by, 'Designate a deadline for this todo.', default: nil, type: :string
  opt :showall, 'Show more than the most urgent several tasks.', default: false
  opt :timezone, 'Modify the time based on time zones.', default: -5
end

# modify this for a different time zone.
# e.g. -5 for EST.
TIMEZONE = -5 

todo_storage = ENV['HOME'] + '/.todo'
File.write(todo_storage, Marshal.dump([])) unless File.file?(todo_storage)

def r_to_date(duration)
  # convert a rational number to a duration
  days = duration.to_i
  hours = (24 * (duration - days)).to_i
  use_and = days.abs >= 1 && hours.abs >= 1 && duration < 3 ? ' ' : ''
  days_str = days.abs >= 1 ? "#{days} days" : ''
  hours_str = hours.abs >= 1 && duration < 3 ? "#{hours} hours" : ''
  days_str + use_and + hours_str
end

def date_colorize(date)
  date_diff = date - DateTime.now - TIMEZONE / 24.to_r # adjusting EST
  date_str = r_to_date(date_diff)
  if date_diff < 3
    date_str.red
  elsif date_diff > 7
    date_str.green
  else
    date_str.yellow
  end
end

def full_print_task(n, line)
  # print all tasks
  task, date = line
  if date
    puts " #{n.to_s.yellow}\t| #{task.blue}: due in #{date_colorize(date)}"
  else
    puts " #{n.to_s.yellow}\t| #{task.blue}"
  end
end

def print_task(n, line)
  # print the task by given info, and only up to things due soon
  task, date = line
  result = case
           when date && (date - Date.today < 5 || n < 5)
             " #{n.to_s.yellow}\t| #{task.blue}: due in #{date_colorize(date)}"
           when n < 5
             " #{n.to_s.yellow}\t| #{task.blue}"
           end
  puts result if result
end

if !opts.add && !opts.done
  # display mode
  File.open(todo_storage, 'r') do |file|
    content = file.read
    tasklist = Marshal.load(content)
    n = 0
    tasklist.each do |line|
      opts.showall ? full_print_task(n, line) : print_task(n, line) # print one line at a time
      n += 1
    end
  end
elsif opts.add
  # add mode
  date = opts.by ? parser.parse(opts.by) : nil
  tasklist = [[opts.add, date]]
  File.open(todo_storage, 'r') do |file|
    content = file.read
    tasklist += Marshal.load(content) # read in the rest
  end
  tasklist.sort_by! do |e| # sort: by date, and put nil last
    if e[1]
      e[1] # this would be a date, like '2016-02-01'
    else
      DateTime.parse('2099-02-03T04:05:06+07:00') # this would probably be after that
    end
  end
  n = 0
  tasklist.each do |line|
    opts.showall ? full_print_task(n, line) : print_task(n, line) # also print out post-change
    n += 1
  end
  data = Marshal.dump(tasklist) # then store the data
  File.write(todo_storage, data)
else
  # mark done mode
  tasklist = []
  File.open(todo_storage, 'r') do |file|
    content = file.read
    tasklist = Marshal.load(content)
    tasklist.delete_if.with_index { |_, index| opts.done.include?(index) } # remove each after retrieve
    n = 0
    tasklist.each do |line| # also print out post-change
      opts.showall ? full_print_task(n, line) : print_task(n, line)
      n += 1
    end
    data = Marshal.dump(tasklist) # then store the data
    File.write(todo_storage, data)
  end
end
