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

`TERM_CHILD` environment variable must be set on starting resque worker:

```
$ TERM_CHILD=1 bundle exec rake resque:work
```

Options are:

* `@worker_killer_monitor_interval`: Monotring interval to check RSS size (default: 1.0 sec)
* `@worker_killer_mem_limit`: RSS usage limit, in killobytes (default: 300MB)
* `@worker_killer_max_term`: Try kiling child process with SIGTERM in `@worker_killer_max_term` times (default: 10), then SIGKILL if it still does not die. Please note that resque worker must be started `TERM_CHILD=1` environment variable.
* `@worker_killer_verbose`: Verbose log
* `@worker_killer_logger`: Logger instance (default: Resque.logger)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sonots/resque-worker-killer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## ChangeLog

[CHANGELOG.md](./CHANGELOG.md)
