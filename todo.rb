#!/usr/bin/env ruby

require 'trollop'
require 'yaml'
require_relative 'parser.rb'

parser = TimeParse.new(TimeLex.new)

opts = Trollop.options do
  opt :add, 'Add an item to the to-do list.', default: nil, type: :string
  opt :done, 'Mark an item on the to-do list as done.', default: nil, type: :int
  opt :by, 'Designate a deadline for this todo.', default: nil, type: :string
end

todo_storage = ENV['HOME'] + '/.todo'
File.write(todo_storage, YAML.dump([])) unless File.file?(todo_storage)

if !opts.add && !opts.done
  # display mode'
  File.open(todo_storage, 'r') do |file|
    content = file.read
    tasklist = YAML.load(content)
    n = 0
    tasklist.each do |line|
      task = line[0]
      date = line[1]
      if date
        puts " #{n}\t| #{task}: due in #{(date - Date.today).to_i} days"
      else
        puts " #{n}\t| #{task}"
      end
      n += 1
    end
  end
elsif opts.add
  # add mode
  date = opts.by ? parser.parse(opts.by) : nil
  tasklist = [[opts.add, date]]
  File.open(todo_storage, 'r') do |file|
    content = file.read
    tasklist += YAML.load(content)
  end
  tasklist.sort_by! { |e| e[1].to_s }
  n = 0
  tasklist.each do |line|
    task = line[0]
    date = line[1]
    if date
      puts " #{n}\t| #{task}: due in #{(date - Date.today).to_i} days"
    else
      puts " #{n}\t| #{task}"
    end
    n += 1
  end
  data = YAML.dump(tasklist)
  File.write(todo_storage, data)
else
  # mark done mode
  tasklist = []
  File.open(todo_storage, 'r') do |file|
    content = file.read
    tasklist = YAML.load(content)
    tasklist.delete_at(opts.done)
    n = 0
    tasklist.each do |line|
      task = line[0]
      date = line[1]
      if date
        puts " #{n}\t| #{task}: due in #{(date - Date.today).to_i} days"
      else
        puts " #{n}\t| #{task}"
      end
      n += 1
    end
    data = YAML.dump(tasklist)
    File.write(todo_storage, data)
  end
end
