#!/usr/bin/env ruby
# frozen_string_literal: true

require 'trollop'
require_relative 'lib/todo.rb'

# options: this shit is optional
opts = Trollop.options do
  version 'todo-ruby 1.0 - Ting Zhou'
  banner <<-EOS
Todo-ruby is a small ruby script that keeps track of things to be done and their deadlines.

Usage:
       todo [command] <arg> [options]
where <command> can be:
  add: add a task.
  complete: mark a task as complete.
  change: modify a task.
  urgent: show the count of urgent tasks.
  <nil>: displays current tasks.
where [options] are:
EOS

  opt :by, 'Designate a deadline for this todo.', default: nil, type: :string
  opt :showall, 'Show more than the most urgent several tasks.', default: false
  opt :powerline, 'Use fancy powerilne display', default: false
end

# arguments: this shit is required
cmd = ARGV.shift

tasklist = read_to_tasklist
due_date = Chronic.parse(opts.by) if opts.by

# === BEGINS MAIN LOGIC === #
case cmd
when /^((add)|a)$/
  task = ARGV.shift
  tasklist += [[task, due_date]]
  sort_tasklist(tasklist)
  display_tasklist(tasklist, opts.showall, opts.powerline)
  write_to_file(tasklist)
when /^((complete)|(done)|(did)|d)$/
  mark_done = ARGV.shift.to_i
  tasklist.delete_at(mark_done)
  display_tasklist(tasklist, opts.showall, opts.powerline)
  write_to_file(tasklist)
when /^((change)|(ch)|c)$/
  index = ARGV.shift.to_i
  tasklist[index][1] = due_date
  sort_tasklist(tasklist)
  display_tasklist(tasklist, opts.showall, opts.powerline)
  write_to_file(tasklist)
when /^((urgent)|(urg)|u)$/
  puts count_urgent(tasklist)
else
  display_tasklist(tasklist, opts.showall, opts.powerline)
end
