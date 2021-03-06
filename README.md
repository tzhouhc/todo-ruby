# todo-ruby
A very simple commandline todo utility.

Requires `trollop`, `colorize`, `chronic` and Ruby1.9.

## Usage
1. Put it anywhere you like, then alias it or link it to your /usr/local/bin.

2. The first time the command is run it would create a file `.todo` in your home folder, where it'll store the serialized todo data.

3. Modify the default for TIMEZONE inside `todo.rb`.

4. To add a task, use `todo -a 'some task'`.

5. To add a task with a due date, use `todo -a 'some task' -b 'some due time'`. The due time is rather flexible, you can use:
  - a date, like 09/14.
  - a weekday, like 'monday' or 'next monday'.
  - a period, like 'in four days'.
  - a period to a time point, like '10 days after next 15th'.
  - more details, like '3 days after the next monday morning'.

6. To mark a task as done, use `todo -d n' where n is the index listed for the task.
