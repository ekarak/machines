require File.dirname(__FILE__) + '/spec_helper.rb'
require 'machines/sequences/step_base'
require 'machines/sequences/step'

include Machines::Sequences
include Machines::Timedomain

describe StepBase do
  before(:each) do
    @dummy = Step.new
    @s = Step.new
    @fail_a = Step.new do |s|
      s.on_enter { fail }
    end
    @fail_b = Step.new do |s|
      s.on_enter { fail }
    end
    Scheduler.current.skip_waiting
    @t0 = Scheduler.current.now
    # pulses at 1, 2, 3, 4 seconds
    @puls = {}
    (1..4).each do |i|
      p = Discrete.new
      @puls[i] = p
      at(i) { p.v = true }
    end
    @p1, @p2, @p3, @p4 = @puls.values_at(1, 2, 3, 4)
  end

  after(:each) do
    Scheduler.dispose
  end

  def at(time, &block)
    Scheduler.current.wait(time, &block)
  end

  def now
    Scheduler.current.now - @t0
  end

  def expect_now(t)
      now.should be_within(0.010).of(t)
  end

  def run
    Scheduler.current.run_for 5
  end

  it 'should have an active signal' do
    @s.continue_if @p2, @dummy
    act = @s.active_signal
    act.should be_a(DiscreteBase)
    act.v.should be_false
    at(1.0) { @s.start }
    at(1.5) { act.v.should be_true }
    at(2.5) { act.c.should be_false }
  end

  it 'should report when finished? as well as active?' do
    @s.continue_if @p1, @dummy
    at(0.1){ @s.should_not be_active; @s.should be_finished }
    at(0.2){ @s.start }
    at(0.3){ @s.should be_active; @s.should_not be_finished }
    at(1.1){ @s.should_not be_active; @s.should be_finished }
    run
  end

  it 'should callback on enter, exit' do
    count = 0
    @s.continue_if @p2, @dummy
    at(1.0){ @s.start }
    @s.on_enter { expect_now 1.0; count += 1 }
    @s.on_exit { expect_now 2.0; count += 1 }
    @s.on_exit_reset { expect_now 2.0; count += 1 }
    run
    count.should == 3
  end

  it 'should callback on enter, regardless of whether it continues to next step' do
    count = 0
    @s.continue_to @dummy
    at(1.0){ @s.start }
    @s.on_enter { expect_now 1.0; count += 1 }
    @s.on_exit { expect_now 1.0; count += 1 }
    @s.on_exit_reset { expect_now 1.0; count += 1 }
    run
    count.should == 3
  end

  it 'should callback on exit, but not before active signal is off' do
    @s.continue_if @p1, @dummy
    at(1.0){ @s.start }
    @s.on_exit { @s.should be_active }
    run
  end

  it 'should continue immediately if no conditions are defined' do
    ok = nil
    @s.continue_to @dummy
    at(1.0){ @s.start }
    @s.on_exit { expect_now 1.0; ok = :ok }
    run
    ok.should == :ok
  end

  it 'should not continue before exit contitions are true' do
    @s.continue_if @p2, @dummy
    at(1.0){ @s.start }
    at(1.5){ @s.should be_active }
    at(2.5){ @s.should be_finished }
    run
  end

  it 'should continue to next step on otherwise condition' do
    @s.continue_if @p2, @fail_a
    @s.continue_if false, @fail_b
    @s.otherwise_to @dummy
    at(1.0){ @s.start }
    at(2.5){ @s.should be_finished }
    run
  end

  it 'should continue to next step in precense of otherwise condition' do
    @s.continue_if @p2.invert, @dummy
    @s.continue_if false, @fail_b
    @s.otherwise_to @fail_a
    at(1.0){ @s.start }
    at(1.5){ @dummy.should be_active }
    run
  end

  it 'should continue to correct step if continue_to has been assigned' do
    @s.continue_to @dummy
    @s.default_next_step = @fail_a
    at(1.0){ @s.start }
    at(1.5){ @dummy.should be_active }
    run
  end

  it 'should continue to correct step if continue_from has been assigned' do
    @dummy.continue_from @s
    @s.default_next_step = @fail_a
    at(1.0){ @s.start }
    at(1.5){ @dummy.should be_active }
    run
  end

  it 'should not continue if there are no otherwise conditions among conditions' do
    @s.default_next_step = @dummy
    @s.continue_if false, @fail_a
    @s.continue_if @p1.invert, @fail_b
    at(2.0){ @s.start }
    run
    @s.should be_active
  end

  it 'should report the correct duration' do
    at(1.0){ @s.start }
    at(1.1){ @s.duration.should be_within(0.010).of(0.1) }
    at(4.0){ @s.duration.should be_within(0.010).of(3.0) }
    run
  end

  it 'should reset' do
    at(1.0){ @s.start }
    at(2.0){ @s.reset }
    at(2.1){ @s.should be_finished }
    run
  end

  it 'should report correct startup time' do
    at(1.0){ @s.start }
    at(2.0){ @s.start_time.to_f.should be_within(0.010).of(@t0.to_f + 1.0) }
    run
  end

  it 'should continue immediately if exit condition is already true' do
    @s.continue_if @p1, @dummy
    at(2.0){ @s.start }
    at(2.1){ @s.should be_finished }
    at(2.1){ @dummy.should be_active }
    run
  end

  it 'should only continue on method call when continue_on_callback is used' do
    @s.default_next_step = @dummy
    @s.continue_on_callback
    at(1.0){ @s.start }
    at(1.5){ @s.should be_active }
    at(2.0){ @s.continue }
    at(2.5){ @dummy.should be_active }
    at(2.5){ @s.should be_finished }
    run
  end

  it 'should continue to default next step on continue_if without step parameter' do
    @s.continue_if @p2
    @s.default_next_step = @dummy
    at(1.0){ @s.start }
    at(1.5){ @s.should be_active }
    at(1.5){ @dummy.should be_finished }
    at(2.5){ @dummy.should be_active }
    at(2.5){ @s.should be_finished }
    run
  end

  def one_state_should_be_active
    @s.should be_active unless @dummy.active?
    @dummy.should be_active unless @s.active?
    (@s || @dummy).should be_true
  end

  it 'should overlap the active signal of two consequitive states' do
    @s.continue_if @p2, @dummy
    [@s, @dummy].each do |state|
      state.on_enter { one_state_should_be_active }
      state.on_exit { one_state_should_be_active }
    end
    @s.start
    one_state_should_be_active
    current = Scheduler.current
    Scheduler.class_eval do
      alias :work_if_busy_orig :work_if_busy
    end

    current.stub!(:work_if_busy).and_return do
      Scheduler.current.send(:work_if_busy_orig)
      one_state_should_be_active
    end
    run
  end
end

