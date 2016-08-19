require 'logger'
require 'resque'
require 'resque-worker-killer'

class MyJob
  @queue = :resque_worker_killer

  extend Resque::Plugins::WorkerKiller
  @worker_killer_monitor_interval = 0.5 # sec
  @worker_killer_mem_limit = 10_000 # KB
  @worker_killer_max_term = 10
  @worker_killer_verbose = true
  @worker_killer_logger = ::Logger.new(STDOUT)

  def self.perform(params)
    puts 'started'
    sleep 3
    str = 'a' * 10 * 1024 * 1024
    sleep 7
    puts 'finished'
  rescue Resque::TermException => e # env TERM_CHILD=1
    puts 'terminated'
  end
end
