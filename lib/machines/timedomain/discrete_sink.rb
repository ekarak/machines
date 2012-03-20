require 'machines/timedomain/discrete_base'

module Machines
  module Timedomain
    
    # transparent discrete component, routes notifications from source component
    class DiscreteSink < DiscreteBase
      attr_reader :source

      def initialize(source = nil)
        sink source
        yield self if block_given?
      end

      def v
        @source && to_discrete(@source)
      end
      
      # sink events from another DiscreteSink upstream to ourselves. 
      def sink(source)
        unless @source.nil?
          throw RuntimeError.new('DiscreteSink may only be assigned to a source once')
        end
        @source = source
        if source.is_a? DiscreteBase
          source.on_change { notify_change }
          source.on_re { notify_re }
          source.on_fe { notify_fe }
        end
      end
    end
  end
end
