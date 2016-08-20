require "resque/plugins/worker_killer/version"
require 'get_process_mem'

module Resque
  module Plugins
    module WorkerKiller
      def worker_killer_monitor_interval
        @worker_killer_monitor_interval ||= 1.0 # sec
      end

      def worker_killer_mem_limit
        @worker_killer_mem_limit ||= 300 * 1024 # killo bytes
      end

      def worker_killer_max_term
        @worker_killer_max_term ||= (ENV['TERM_CHILD'] ? 10 : 0)
      end

      def worker_killer_verbose
        @worker_killer_verbose = false if @worker_killer_verbose.nil?
        @worker_killer_verbose
      end

      def worker_killer_logger
        @worker_killer_logger ||= ::Resque.logger
      end

      def self.extended(klass)
        Resque.after_fork do |job|
          # this is ran in the forked child process
          # we do not let the monitor thread die since the process itself dies
          Thread.start { PrivateMethods.new(klass).monitor_oom }
        end
      end

      class PrivateMethods
        def initialize(obj)
          @obj = obj
        end

        # delegate attr_reader
        %i[
          monitor_interval
          mem_limit
          max_term
          verbose
          logger
        ].each do |method|
          define_method(method) do
            @obj.send("worker_killer_#{method}")
          end
        end

        def plugin_name
          "Resque::Plugins::WorkerKiller"
        end

        def monitor_oom
          start_time = Time.now
          loop do
            one_shot_monitor_oom(start_time)
            sleep monitor_interval
          end
        end

        def one_shot_monitor_oom(start_time)
          rss = GetProcessMem.new.kb
          logger.info "#{plugin_name}: worker (pid: #{Process.pid}) using #{rss} KB." if verbose
          if rss > mem_limit
            logger.warn "#{plugin_name}: worker (pid: #{Process.pid}) exceeds memory limit (#{rss} KB > #{mem_limit} KB)"
            kill_self(logger, start_time)
          end
        end

        # Kill the current process by telling it to send signals to itself If
        # the process isn't killed after `@max_term` TERM signals,
        # send a KILL signal.
        def kill_self(logger, start_time)
          alive_sec = (Time.now - start_time).round

          @@kill_attempts ||= 0
          @@kill_attempts += 1

          sig = :TERM
          sig = :KILL if @@kill_attempts > max_term

          logger.warn "#{plugin_name}: send SIG#{sig} (pid: #{Process.pid}) alive: #{alive_sec} sec (trial #{@@kill_attempts})"
          Process.kill(sig, Process.pid)
        end
      end
    end
  end
end
