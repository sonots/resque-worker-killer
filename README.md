# Resque::Worker::Killer

[Resque](https://github.com/resque/resque) is widely used Redis-backed Ruby library for creating background jobs. One thing we thought Resque missed, is killing a forked child of Resque worker based on consumed memories.

resque-worker-killer gem provides automatic kill of a forked child of Resque worker based on process memory size (RSS) not to exceed the maximum allowed memory size.

The name was inspired by [unicorn-worker-killer](https://github.com/kzk/unicorn-worker-killer) :-p

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'resque-worker-killer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install resque-worker-killer

## Usage

Use the plugin:

```ruby
require 'resque'
require 'resque-worker-killer'

class MyJob
  extend Resque::Plugins::WorkerKiller
  @queue = :example_queue

  extend Resque::Plugins::WorkerKiller
  @worker_killer_monitor_interval = 0.5 # sec
  @worker_killer_mem_limit = 300_000 # KB
  @worker_killer_max_term = 10 # try TERM 10 times, then KILL
  @worker_killer_verbose = false # verbose log
  @worker_killer_logger = Resque.logger

  def self.perform(*args)
    puts 'started'
    sleep 10
    puts 'finished'
  rescue Resque::TermException => e # env TERM_CHILD=1
    puts 'terminated'
  end
end
```

### TERM_CHILD=1

Resque requires to set `TERM_CHILD` environment variable to accept killing a forked child with SIGTERM.

```
$ TERM_CHILD=1 bundle exec rake resque:work
```
Thus,

* Without `TERM_CHILD=1`, set `@worker_killter_max_term = 0` to send SIGKILL immediately
* With `TERM_CHILD=1`, set `@worker_killer_max_term > 0` to try SIGTERM first, then SIGKILL

With `TERM_CHILD=1`, `Resque::TermException` is raised if a forked child is killed by SIGTERM.

## Options

Options are:

* `@worker_killer_monitor_interval`: Monotring interval to check RSS size (default: 1.0 sec)
* `@worker_killer_mem_limit`: RSS usage limit, in killobytes (default: 300MB)
* `@worker_killer_max_term`: Try kiling child process with SIGTERM in `max_term` times, then SIGKILL if it still does not die. 
  Please note that setting `TERM_CHILD` environment variable is required to accept killing the child with SIGTERM.
  The default is, 10 with `TERM_CHILD=1`, 0 without `TERM_CHILD=1`.
* `@worker_killer_verbose`: Verbose log
* `@worker_killer_logger`: Logger instance (default: Resque.logger)

## NOTE

It is known that this gem has somewhat poor compatibility with [resque-jobs-per-fork](https://github.com/samgranieri/resque-jobs-per-fork), which enables to have workers perform more than one job, before terminating 

Think of JOBS_PER_FORK=3, it usually works as follows:

```
10:00:00.40000 PID-14056 1st JOB: Started
10:00:00.60000 PID-14056 1st JOB: Finished
10:00:00.60000 PID-14056 2nd JOB: Started
10:00:01.30000 PID-14056 2nd JOB: Finished
10:00:01.30000 PID-14056 3rd JOB: Started
10:00:01.60000 PID-14056 3rd JOB: Finished
10:00:01.60000 PID-14057 4th JOB: Started
10:00:01.70000 PID-14057 4th JOB: Finished
```

Think of Resque::Worker::Killer with `@worker_killer_monitor_interval = 1.0`, it would work as follows:

```
10:00:00.40000 PID-14056 1st JOB: Started
10:00:00.60000 PID-14056 1st JOB: Finished
10:00:00.60000 PID-14056 2nd JOB: Started
10:00:01.30000 PID-14056 2nd JOB: Finished <= 2nd Job consumed lots of memory
10:00:01.30000 PID-14056 3rd JOB: Started
10:00:01.40000 PID-14056 WorkerKiller: Monitors memory size, and kill
```

The 2nd job consumed lots of memory, but 3rd job is killed.
To avoid such situation, just stop using resque-jobs-per-fork with this plugin.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sonots/resque-worker-killer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## ChangeLog

[CHANGELOG.md](./CHANGELOG.md)
