require File.dirname(__FILE__) + '/spec_helper.rb'
require 'machines/timedomain/scheduler.rb'
require 'benchmark'
require 'timeout'

include Machines::Timedomain

describe Scheduler do
  before(:each) do
  end

  after(:each) do
    Scheduler.dispose
  end

  it 'should wait for approximately correct time' do
    Timeout::timeout(2) do
      #Benchmark.measure { Scheduler.current.run_for 0.050 }.real.should be_close(0.050, 0.010)
      Benchmark.measure { Scheduler.current.run_for 0.050 }.real.should be_within(0.01).of(0.05)      
    end
  end
end

