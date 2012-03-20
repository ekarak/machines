require 'machines/timedomain/discrete_base'

module Machines
  module Timedomain
    
    # Discrete (binary) component
    class Discrete < DiscreteBase
      
      attr_reader :v
      
      # initialize discrete component with initial boolean 
      def initialize(vv = false)
        raise "Discrete.initialize must be supplied with a boolean!" unless [TrueClass, FalseClass].include?(vv.class) 
        @v = vv
        yield self if block_given?
      end

      # handles value writes, by firing data_change callback
      def v=(new_val)
        old_v = @v
        # map new_val => boolean by Ruby's idiom
        if new_val
          @v = true
          data_change @v unless old_v
        else
          @v = false
          data_change @v if old_v
        end
      end
      
      #######
      private
      #######
      
      def data_change(value)
        notify_re if value
        notify_fe unless value
        notify_change
      end
      
    end
  end
end
