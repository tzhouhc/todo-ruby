#!/usr/bin/env ruby

require 'trollop'
require 'yaml'
require 'colorize'
require_relative 'parser.rb'

parser = TimeParse.new(TimeLex.new)

opts = Trollop.options do
  opt :add, 'Add an item to the to-do list.', default: nil, type: :string
  opt :done, 'Mark an item on the to-do list as done.', default: nil, type: :ints
  opt :by, 'Designate a deadline for this todo.', default: nil, type: :string
end

todo_storage = ENV['HOME'] + '/.todo'
File.write(todo_storage, YAML.dump([])) unless File.file?(todo_storage)

def date_colorize(date)
  # urgency color-code the date
  date_diff = (date - Date.today).to_i
  if date_diff < 2
    date_diff.to_s.red
  elsif date_diff > 5
    date_diff.to_s.green
  else
    date_diff.to_s.yellow
  end
end

def print_task(n, line)
  # print the task by given info
  task, date = line
  if date
    date_s = date_colorize(date) # if there is a deadline
    puts " #{n.to_s.yellow}\t| #{task.blue}: due in #{date_s} days"
  else # if there is not 
    puts " #{n.to_s.yellow}\t| #{task.blue}"
  end
end

if !opts.add && !opts.done
  # display mode
  File.open(todo_storage, 'r') do |file|
    content = file.read
    tasklist = YAML.load(content)
    n = 0
    tasklist.each do |line|
      print_task(n, line) # print one line at a time
      n += 1
    end
  end
elsif opts.add
  # add mode
  date = opts.by ? parser.parse(opts.by) : nil
  tasklist = [[opts.add, date]]
  File.open(todo_storage, 'r') do |file|
    content = file.read
    tasklist += YAML.load(content) # read in the rest
  end
  tasklist.sort_by! do |e| # sort: by date, and put nil last
    if e[1]
      e[1].to_s # this would be a date, like '2016-02-01'
    else
      '9999-99-99' # this would probably be after that
    end
  end
  n = 0
  tasklist.each do |line|
    print_task(n, line) # also print out post-change
    n += 1
  end
  data = YAML.dump(tasklist) # then store the data
  File.write(todo_storage, data)
else
  # mark done mode
  tasklist = []
  File.open(todo_storage, 'r') do |file|
    content = file.read
    tasklist = YAML.load(content)
    tasklist.delete_if.with_index { |_, index| opts.done.include?(index) } # remove each after retrieve
    n = 0
    tasklist.each do |line| # also print out post-change
      print_task(n, line)
      n += 1
    end
    data = YAML.dump(tasklist) # then store the data
    File.write(todo_storage, data)
  end
end
