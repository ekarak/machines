require 'rbtree'
require 'monitor'

module Machines
  module Timedomain
    
    # a Scheduler 
    class Scheduler
      class Entry
        attr_accessor :time, :tag, :callback
      end

      ZeroTime = Time.at(0)
      
      # singleton instance holder
      @@current = nil

      def initialize
        # a sorted Hash of scheduled events (key: event firing time, value: event to run)
        @scheduled = MultiRBTree.new
        @scheduled.extend(MonitorMixin)
        # create new ConditionVariable for this scheduler
        @wait_cond = @scheduled.new_cond
        # initial state: not running
        @running = false
        # array of work items
        @work_queue = []
        # set default wait policy
        @wait_policy = RealWaitPolicy.new
      end

      # create singleton instance (unless already instantiated) and return it
      def Scheduler.current
        @@current ||= Scheduler.new
      end

      # destroy singleton instance
      def Scheduler.dispose
        @@current.stop if @@current
        @@current = nil
      end

      # set this scheduler's wait policy to Skip
      # practically useful only for testing.
      def skip_waiting
        @wait_policy = SkipWaitPolicy.new
      end

      # add a new entry to the scheduler
      # time attr is absolute
      def wait_until(time, tag = nil, &block)
        throw RuntimeError.new('wait_until will only accept Time objects') unless time.is_a? Time
        entry = Entry.new
        entry.time, entry.tag, entry.callback = time, tag, block
        @scheduled.synchronize do
          # TODO Check whether tag is already in use
          @scheduled[time] = entry
          @wait_cond.signal
        end
      end

      # add a new entry to the scheduler
      # delay attr is relative to the current point in time
      def wait(delay, tag = nil, &block)
        wait_until(now + delay, tag) do
          yield
        end
      end

      # cancel an event by its tag
      def cancel(tag)
        @scheduled.synchronize do
          @scheduled.delete_if {|k,v| v.tag === tag }
          @wait_cond.signal
        end
      end

      # execute an event NOW
      def at_once(&block)
        wait_until(now, :now) { block.call }
      end

      # tell scheduler to enter running mode
      def run
        @running = true
        while @running 
          @scheduled.synchronize do
            timeout = nil
            if @scheduled.any?
              timeout = @scheduled.first.last.time - @wait_policy.now
              @wait_policy.wait_timeout @wait_cond, timeout
            else
              @wait_policy.wait @wait_cond
            end
          end
          work_if_busy
        end
      end

      #
      def run_for(timeout)
        wait(timeout) { stop }
        run
      end

      # stop scheduler
      def stop
        @running = false
        @scheduled.synchronize do
          @wait_cond.signal
        end
      end

      # return current wait policy notion of "now"
      # RealWaitPolicy (default) => Time.now (the point in time the method now() is invoked)
      # SkipWaitPolicy => @time (the point in time the scheduler was created)
      def now
        @wait_policy.now
      end

      #######
      private
      #######

      # Waiting policies:
      
      # RealWaitPolicy 
      # timing is real: 1 sec == 1 sec
      class RealWaitPolicy
        def wait_timeout(cond, timeout)
          cond.wait timeout if timeout > 0
        end

        def wait(cond)
          cond.wait
        end

        def now
          Time.now
        end
      end

      # SkipWaitPolicy
      # timing is phony: 1 sec == nada 
      class SkipWaitPolicy
        def initialize 
          @time = Time.now
        end

        def wait_timeout(cond, timeout)
          @time += timeout if timeout > 0
        end

        def wait
          throw RuntimeError.new('Waiting forever in skip wait policy')
        end

        def now
          @time
        end
      end
      
      # perform any work items stored in the @scheduled rbtree
      def work_if_busy
        @scheduled.synchronize do
          t = @wait_policy.now
          while !@scheduled.empty? && @scheduled.first.last.time <= t
            @work_queue << @scheduled.shift.last.callback
          end
        end
        @work_queue.each {|c| c.call }
        @work_queue.clear
      end
    end
  end
end
