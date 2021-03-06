require 'machines/timedomain/discrete_base'

module Machines
  module Timedomain

    # maybe we do not need a separate class for negation!
    class NegatedDiscrete < DiscreteBase
      def initialize(a)
        @a = a
        if a.is_a? DiscreteBase
          a.on_change { notify_change }
          a.on_re { notify_fe }
          a.on_fe { notify_re }
        end
      end

      def v
        !@a.v
      end 
    end
    
    
  end
end


