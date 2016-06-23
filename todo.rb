#!/usr/bin/env ruby

require 'trollop'
require 'colorize'
require 'chronic'

opts = Trollop.options do
  opt :add, 'Add an item to the to-do list.', default: nil, type: :string
  opt :done, 'Mark some items on the to-do list as done.', default: nil, type: :ints
  opt :by, 'Designate a deadline for this todo.', default: nil, type: :string
  opt :change, 'Modify the deadline for a todo', default: nil, type: :int
  opt :showall, 'Show more than the most urgent several tasks.', default: false
  opt :urgent, 'Count the number of urgent tasks', default: false
  opt :powerline, 'Display using Fancy powerline shit', default: false
end

DAY = 86_400
HOUR = 3600

todo_storage = ENV['HOME'] + '/.todo'
File.write(todo_storage, Marshal.dump([])) unless File.file?(todo_storage)

def diff_to_text(duration)
  # convert a duration time to due time in words
  days = (duration / DAY).to_i
  hours = ((duration - days * DAY) / HOUR).to_i
  minutes = ((duration % HOUR) / 60).to_i
  day_with_s = days > 1 ? 'days' : 'day'
  hour_with_s = hours > 1 ? 'hours' : 'hour'
  minute_with_s = minutes > 1 ? 'minutes' : 'minute'
  if days > 0
    if days >= 3
      "due in #{days} days"
    elsif hours > 0
      "due in #{days} #{day_with_s} #{hours} #{hour_with_s}"
    else
      "due in #{days} #{day_with_s}"
    end
  else
    if hours > 0
      "due in #{hours} #{hour_with_s} #{minutes} #{minute_with_s}"
    else
      duration > 0 ? "due in #{minutes} #{minute_with_s}" : "past due"
    end
  end
end

def date_colorize(date)
  date_diff = date - Time.now
  date_str = diff_to_text(date_diff)
  if date_diff < 3 * DAY
    date_str.red
  elsif date_diff > 7 * DAY
    date_str.green
  else
    date_str.yellow
  end
end

def color_arrow(text, text_color, arrow_color, next_color)
  " #{text} ".colorize(color: text_color, background: arrow_color) \
  + "".colorize(color: arrow_color, background: next_color)
end

def full_print_task(n, line, powerline)
  # print all tasks
  puts "powerline = #{powerline}!"
  if powerline
    task, date = line
    if date
      puts color_arrow(n, :red, :black, :light_green) + color_arrow(task, :black, :light_green, :nil) + ' ' + date_colorize(date)
    else
      puts color_arrow(n, :red, :black, :light_green) + color_arrow(task, :black, :light_green, :nil)
    end
  else
    task, date = line
    if date
      puts " #{n.to_s.yellow}\t| #{task.blue}: #{date_colorize(date)}"
    else
      puts " #{n.to_s.yellow}\t| #{task.blue}"
    end
  end
end

def print_task(n, line, powerline)
  # print the task by given info, and only up to things due soon
  task, date = line
  if powerline
    result = case
             when date && (date - Time.now < 5 * DAY || n < 5)
               puts color_arrow(n, :red, :black, :light_green) + color_arrow(task, :black, :light_green, :nil) + ' ' + date_colorize(date)
             when n < 5
               puts color_arrow(n, :red, :black, :light_green) + color_arrow(task, :black, :light_green, :nil)
             end
    puts result if result
  else
    result = case
             when date && (date - Time.now < 5 * DAY || n < 5)
               " #{n.to_s.yellow}\t| #{task.blue}: #{date_colorize(date)}"
             when n < 5
               " #{n.to_s.yellow}\t| #{task.blue}"
             end
    puts result if result
  end
end

def sort_tasklist(tasklist)
  tasklist.sort_by! do |e| # sort: by date, and put nil last
    if e[1]
      e[1] # this would be a date, like '2016-02-01'
    else
      Time.parse('2099-02-03T04:05:06+07:00') # this would probably be after that
    end
  end
end

def count_urgent(tasklist)
  sort_tasklist(tasklist)
  count = 0
  tasklist.each do |line|
    next unless line[1]
    count += 1 if (line[1] - Time.now) < 3 * DAY
  end
  count
end

if !opts.add && !opts.done && !opts.change && !opts.urgent
  # display mode
  File.open(todo_storage, 'r') do |file|
    content = file.read
    tasklist = Marshal.load(content)
    tasklist = sort_tasklist(tasklist)
    n = 0
    tasklist.each do |line|
      opts.showall ? full_print_task(n, line, opts.powerline) : print_task(n, line, opts.powerline) # print one line at a time
      n += 1
    end
  end
elsif opts.add
  # add mode
  date = opts.by ? Chronic.parse(opts.by) : nil
  tasklist = [[opts.add, date]]
  File.open(todo_storage, 'r') do |file|
    content = file.read
    tasklist += Marshal.load(content) # read in the rest
  end
  tasklist = sort_tasklist(tasklist)
  n = 0
  tasklist.each do |line|
    opts.showall ? full_print_task(n, line, opts.powerline) : print_task(n, line, opts.powerline) # also print out post-change
    n += 1
  end
  data = Marshal.dump(tasklist) # then store the data
  File.write(todo_storage, data)
elsif opts.change
  # modification mode
  new_date = opts.by ? Chronic.parse(opts.by) : nil
  tasklist = []
  File.open(todo_storage, 'r') do |file|
    content = file.read
    tasklist = Marshal.load(content)
    tasklist[opts.change][1] = new_date # change the due-date of one particular task
    n = 0
    tasklist.each do |line| # also print out post-change
      opts.showall ? full_print_task(n, line, opts.powerline) : print_task(n, line, opts.powerline)
      n += 1
    end
    tasklist = sort_tasklist(tasklist)
    data = Marshal.dump(tasklist) # then store the data
    File.write(todo_storage, data)
  end
elsif opts.done
  # mark done mode
  tasklist = []
  File.open(todo_storage, 'r') do |file|
    content = file.read
    tasklist = Marshal.load(content)
    tasklist.delete_if.with_index { |_, index| opts.done.include?(index) } # remove each after retrieve
    n = 0
    tasklist.each do |line| # also print out post-change
      opts.showall ? full_print_task(n, line, opts.powerline) : print_task(n, line, opts.powerline)
      n += 1
    end
    data = Marshal.dump(tasklist) # then store the data
    File.write(todo_storage, data)
  end
elsif opts.urgent
  tasklist = []
  File.open(todo_storage, 'r') do |file|
    content = file.read
    tasklist = Marshal.load(content)
    puts count_urgent(tasklist)
  end
end
