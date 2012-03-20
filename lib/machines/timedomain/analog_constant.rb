include 'machines/timedomain/analog'

module Machines
  module Physical
    
    # an analog value that cannot change
    class AnalogConstant < Analog
      attr_reader :v

      def initialize()
        @name, @description = nil
        @v = value
      end

      def on_change
        raise "AnalogConstant cannot change value!"
      end
    end
    
  end
end







