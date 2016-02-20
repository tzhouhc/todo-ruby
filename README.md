# todo-ruby
A very simple commandline todo utility.

Requires `trollop` and Ruby1.9.

## Usage
1. Put it anywhere you like, then alias it or link it to your /usr/local/bin.
2. To add a task, use `todo -a 'some task'`. 
3. To add a task with a due date, use `todo -a 'some task' -b 'some due time'`. The due time is rather flexible, you can use:
  - a date, like 09/14
  - a weekday, like 'monday' or 'next monday'
  - a period, like 'in four days'
  - a period to a time point, like '10 days after next 15th'.
4. To mark a task as done, use `todo -d n' where n is the index listed for the task.
