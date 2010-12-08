require 'eventmachine'

module Machines
  module Sequences
    class WaitStep < Step
      attr_accessor :timeout

      def initialize(timeout, name = nil)
        super name
        @timeout = timeout
        t = EventMachine::Timer.new(timeout) { continue! }
        on_reset { t.cancel }
      end
    end
  end
end



