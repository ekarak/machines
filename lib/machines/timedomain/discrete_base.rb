require 'machines/timedomain/timer'
require 'machines/etc/notify'

module Machines
  module Timedomain
    
    # Base class to implement discrete (binary only?) components
    class DiscreteBase
      extend Notify

      attr_accessor :name, :description
      
      # valid notifications: re (rising edge), fe (falling edge), change (obvious)
      notify :re, :fe, :change

      # create new DiscreteBase instance
      def initialize
        @name, @description = nil
      end

      # declare on-delay. time is in seconds 
      def ton(time)
        timer = Timer.new time
        on_re { timer.start }
        if block_given?
          on_fe { timer.reset }
          timer.at_end { yield }
          self
        else
          result = Discrete.new
          on_fe do
            timer.reset
            result.v = false
          end
          timer.at_end { result.v = true }
          result
        end
      end

      # declare off-delay. time is in seconds
      def tof(time)
        timer = Timer.new time
        on_fe { timer.start }
        if block_given? 
          on_re { timer.reset }
          timer.at_end { yield }
          self
        else
          result = Discrete.new
          on_re do
            timer.reset 
            result.v = true 
          end
          timer.at_end { result.v = false }
          result
        end
      end

      # boolean operation: AND
      def &(other)
        BinaryOpDiscrete.new(self, other) {|a, b| a && b }
      end

      # boolean operation: OR
      def |(other)
        BinaryOpDiscrete.new(self, other) {|a, b| a || b }
      end

      # boolean operation: NOT
      def invert
        NegatedDiscrete.new(self)
      end

      alias :not :invert

      #######
      private 
      #######
      
      def to_discrete(disc)
        if disc.respond_to? :v
          disc.v
        else
          disc
        end
      end
      
    end
  end
end

# now we can require dependant classes
require 'machines/timedomain/binary_op_discrete'
require 'machines/timedomain/negated_discrete'