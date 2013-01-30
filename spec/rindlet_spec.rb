require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require "rindlet"
require 'rindlet_context'
include Rinda

TEST_RINDLET_TEMPLATE = ["test_context", "request", "test"]


describe Rinda::Rindlet do

  class TestRindlet < Rinda::Rindlet
    def initialize(number, pulse = 5)
      super(number, pulse)
    end

    def run
      with_standard_tuple(TEST_RINDLET_TEMPLATE[0], TEST_RINDLET_TEMPLATE[2]) do |tuple|
        do_nothing
      end
    end

    def do_nothing
      DoNothingConfirmation.called
    end

    def do_standard_preparation
    end

    def enter_loop
      check_for_ping
      run
    end
  end

  # used to test if do_nothing was called (in Thread-per-request model do_nothing will be called on another instance of TestRindlet)
  class DoNothingConfirmation
    def self.called
      puts "\n\ncalled!"
      # use a matcher like DoNothingConfirmation.should_receive(:called)
    end
  end

  class Test2Rindlet < Rindlet

    def initialize(number, pulse = 5)
      super(number, pulse)
    end

    def run
      with_tuple(TEST_RINDLET_TEMPLATE) do |tuple|
        do_nothing
      end
    end

    def do_nothing
    end

    def do_standard_preparation
    end

    def enter_loop
      check_for_ping
      run
    end

    def standard_error_response(context, task, e, tuple, app_id, timeout=nil)
      @rinda_client.write([context, "response", task, "error", e.to_s, tuple, nil], timeout)
      $logger.pb_error e.to_s
      $logger.pb_error e.backtrace.join("\n")
    end
  end

  class MockContext
    def kill_last_instance; end;
    def invoke_new_instance; end;
    def method_missing(*args); return 1; end;
  end

  before(:each) do
    $rindlet_context = MockContext.new

    @rindlet = TestRindlet.new(1)
    @rindlet.pulse = 0
    @rinda_client = MockRindaClient.new
    @rindlet.rinda_client = @rinda_client
  end

  it "should get the pong timeout from the config" do
    CONFIG[:rindlet_monitor_pong_timeout] = 600
    rindlet = TestRindlet.new(1)
    rindlet.pong_timeout.should == 600
  end

  it "should set a default pong timeout of 120 secs if not set in config" do
    CONFIG[:rindlet_monitor_pong_timeout] = nil
    rindlet = TestRindlet.new(1)
    rindlet.pong_timeout.should == 120
  end

  it "should use the configured pong timeout when creating pong tuple" do
    @rindlet.pong_timeout = 1234
    @rinda_client.takes << [[@rindlet.name, "ping"], [@rindlet.name, "ping"]]
    @rinda_client.stub!(:write)

    @rinda_client.should_receive(:write).with(["monitor", "pong", @rindlet.name], 1234)

    @rindlet.start
  end

  it "should handle ping requests" do
    @rinda_client.takes << [[@rindlet.name, "ping"], [@rindlet.name, "ping"]]

    @rindlet.start

    @rinda_client.writes[1].should eql(["monitor", "pong",  @rindlet.name])
  end

  it "should register with the monitor service on start up" do
    @rindlet.start
    @rinda_client.writes[0].should eql(["monitor", "subscribe", "TestRindlet_1"])
    @rinda_client.timeouts[0].should == 120

    @rindlet.send(:subscribe_to_monitor)
    @rinda_client.writes[1].should eql(["monitor", "subscribe", "TestRindlet_1"])
    @rinda_client.timeouts[1].should == 120
  end

  it "should only respond to monitor commands for the correct target/instance" do
    @rinda_client.takes << [[@rindlet.name, "ping"], [@rindlet.name, "ping"]]
    new_rindlet = TestRindlet.new(2)
    new_rindlet.rinda_client = @rinda_client

    new_rindlet.start
   @rinda_client.takes.size.should eql(1)
  end

  it "should unsubscribe when shutting down" do
    @rindlet.stop
    @rinda_client.writes[0].should eql(["monitor", "unsubscribe", "TestRindlet_1"])
    @rinda_client.timeouts[0].should == 2
  end

  it "should re-post the tuple when a recoverable exceptions" do
    @rindlet.recover_from(Timeout::Error)
    @rindlet.should_receive(:do_nothing).and_raise(Timeout::Error.new("blah"))
    @rinda_client.takes << [["test_context", "request", "test"], ["test_context", "request", "test"]]

    @rindlet.run

    @rinda_client.writes.length.should eql(0)
    @rinda_client.delayed_writes[0].should eql([3600, ["test_context", "request", "test"]])
  end

  it "should not re-post the tuple when the exception is not recoverable in with_standard_tuple" do
    @rindlet.recover_from(Timeout::Error, NoMethodError)
    @rindlet.should_receive(:do_nothing).and_raise(SystemExit)
    @rinda_client.takes << [TEST_RINDLET_TEMPLATE, TEST_RINDLET_TEMPLATE]

    @rindlet.run

    @rinda_client.delayed_writes.length.should eql(0)
    @rinda_client.writes[0].should eql(["test_context", "response", "test", "error", "SystemExit", TEST_RINDLET_TEMPLATE, nil])
  end

  it "should not re-post the tuple when the exception is not recoverable in with_tuple" do
    rindlet = Test2Rindlet.new(1)
    rindlet.pulse = 0
    rinda_client = MockRindaClient.new
    rindlet.rinda_client = rinda_client

    rindlet.recover_from(Timeout::Error, NoMethodError)
    rindlet.should_receive(:do_nothing).and_raise(SystemExit)
    rinda_client.takes << [["test_context", "request", "test"], ["test_context", "request", "test"]]

    rindlet.run

    rinda_client.delayed_writes.length.should eql(0)
    rinda_client.writes[0].should eql(["test_context", "response", "test", "error", "SystemExit", TEST_RINDLET_TEMPLATE, nil])
  end

  it "should store standard network errors" do
    Rindlet::NetworkErrors.should include(Timeout::Error)
    Rindlet::NetworkErrors.should include(Errno::EPIPE)
    Rindlet::NetworkErrors.should include(SocketError)
    Rindlet::NetworkErrors.should include(Errno::ECONNREFUSED)
  end

  it "should set the app id" do
    @rindlet.recover_from(Timeout::Error, NoMethodError)
    @rindlet.should_receive(:do_nothing).and_raise(SystemExit)
    @rinda_client.takes << [TEST_RINDLET_TEMPLATE, TEST_RINDLET_TEMPLATE + ["app_id"]]

    @rindlet.run

    @rinda_client.delayed_writes.length.should eql(0)
    @rinda_client.writes[0].should eql(["test_context", "response", "test", "error", "SystemExit", TEST_RINDLET_TEMPLATE + ["app_id"], "app_id"])
  end

  it "should set the app id to nil if empty" do
    @rindlet.recover_from(Timeout::Error, NoMethodError)
    @rindlet.should_receive(:do_nothing).and_raise(SystemExit)
    @rinda_client.takes << [["test_context", "request", "test"], ["test_context", "request", "test"]]

    @rindlet.run

    @rinda_client.delayed_writes.length.should eql(0)
    @rinda_client.writes[0].should eql(["test_context", "response", "test", "error", "SystemExit", TEST_RINDLET_TEMPLATE, nil])
  end

  it "should use the already set app_id" do
    @rindlet.app_id = "123"
    @rindlet.recover_from(Timeout::Error, NoMethodError)
    @rindlet.should_receive(:do_nothing).and_raise(SystemExit)
    @rinda_client.takes << [["test_context", "request", "test"], ["test_context", "request", "test"]]

    @rindlet.run

    @rinda_client.delayed_writes.length.should eql(0)
    @rinda_client.writes[0].should eql(["test_context", "response", "test", "error", "SystemExit", TEST_RINDLET_TEMPLATE, "123"])
  end

  it "should use the error topic" do
    @rindlet.error_topic = "test_error_topic"
    @rindlet.should_receive(:do_nothing).and_raise(SystemExit)
    @rinda_client.takes << [["test_context", "request", "test"], ["test_context", "request", "test"]]

    @rindlet.run

    @rinda_client.writes[0].should == ["test_context", "response", "test", "test_error_topic", "SystemExit", TEST_RINDLET_TEMPLATE, nil]
  end

  module Fiddle
    module Faddle
      class FfRindlet < Rindlet
      end
    end
  end

  it "should not include the module in the Rindlet's name" do
    rindlet = Fiddle::Faddle::FfRindlet.new(1, 5)
    rindlet.name.should eql("FfRindlet_1")
  end

  it "should have load_factor of zero when nothing happens" do
    @rindlet = Rindlet.new(1, 0)
    @rindlet.rinda_client = @rinda_client
    @rindlet.load_calculator.load_factor.should == 0

    Thread.start { @rindlet.start }
    sleep(0.01)
    @rindlet.stop

    @rindlet.load_calculator.cycles.should > 10
    @rindlet.load_calculator.load_factor.should == 0.0
  end

  class TestRindlet3 < Rinda::Rindlet

    def initialize(number, pulse = 5)
      super(number, pulse)
    end

    def run
      with_tuple([nil]) { |tuple| "do_nothing" }
    end
  end

  it "should have a load_factor of 100 when every cycle leads to task" do
    @rindlet = TestRindlet3.new(1, 0)
    @rindlet.rinda_client = @rinda_client
    @rinda_client.stub!(:take).and_return(["blah"])
    @rindlet.load_calculator.load_factor.should == 0

    Thread.start { @rindlet.start }
    sleep(0.01)
    @rindlet.stop

    @rindlet.load_calculator.cycles.should > 10
    @rindlet.load_calculator.load_factor.should == (@rindlet.load_calculator.sample.size * 10)
  end


  it "should start as single-thread where the same instance takes each tuple when no options are passed" do
    @rinda_client.takes << [TEST_RINDLET_TEMPLATE, ["first_tuple"]]
    @rinda_client.takes << [TEST_RINDLET_TEMPLATE, ["second_tuple"]]

    @rindlet.should_receive(:do_nothing).twice

    @rindlet.start_thread
    sleep(0.01)
    @rindlet.stop_asap

  end


  it "should do thread_per_request where a new instance takes each tuple, when thread_per_request option is passed" do
    @rinda_client.takes << [TEST_RINDLET_TEMPLATE, TEST_RINDLET_TEMPLATE + ["first_tuple"]]
    @rinda_client.takes << [TEST_RINDLET_TEMPLATE, TEST_RINDLET_TEMPLATE + ["second_tuple"]]

    DoNothingConfirmation.should_receive(:called).twice

    @rindlet.start_thread(:thread_per_request => true)

    sleep(0.3)
    @rindlet.stop_asap
  end

  it "take catches thread error" do
    @rinda_client.should_receive(:take).and_raise(ThreadError)

    tuple = @rindlet.send(:take_with_timeout, ['thread_error'], 0)
    tuple.should be_nil
  end

end
