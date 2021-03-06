require 'machines/timedomain/scheduler'
require 'machines/etc/notify'

module Machines
  module Timedomain
    
    # a Timer is .. well .. a timer!
    class Timer
      extend Notify

      notify :finish
      alias :at_end :on_finish

      # instantiate a new timer, with supplied time-to-wait
      def initialize(time)
        @time = time
        @start_time = nil
        @listeners = []
        on_finish { yield } if block_given?
      end

      # reset the timer by reapplying new time-to-wait
      def time=(t)
        # todo support analog signals
        @time = t
        if @start_time
          Scheduler.current.cancel self
          do_wait
        end
      end

      # return time-to-wait
      def time
        @time
      end

      # return elapsed time since timer was started
      def elapsed
        if @start_time
          Scheduler.current.now - @start_time
        else
          nil
        end
      end

      # start the timer
      def start
        @start_time = Scheduler.current.now
        do_wait
      end

      # stop(reset) the timer
      def reset
        @start_time = nil
        Scheduler.current.cancel self
      end

      # is the timer running?
      def active?
        not idle?
      end

      # is the timer stopped?
      def idle?
        @start_time == nil
      end

      #######
      private 
      #######
      
      # add this timer to the Scheduler singleton instance 
      def do_wait
        Scheduler.current.wait_until @start_time + @time, self do
          @start_time = nil
          notify_finish
        end
      end
      
    end
  end
end




