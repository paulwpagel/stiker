require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require "rindlet"
include Rinda

TEST_RINDLET_TEMPLATE = ["test_context", "request", "test"]


describe Rinda::Rindlet do

  class TestRindlet < Rinda::Rindlet
    def initialize(number, pulse = 5)
      super(number, pulse)
    end

    def run
      with_tuple(TEST_RINDLET_TEMPLATE[0], TEST_RINDLET_TEMPLATE[2]) do |tuple|
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

  before(:each) do

    @rindlet = TestRindlet.new(1)
    @rindlet.pulse = 0
    @rinda_client = MockRindaClient.new
    @rindlet.rinda_client = @rinda_client
  end

  # it "should re-post the tuple when a recoverable exceptions" do
  #   @rindlet.recover_from(Timeout::Error)
  #   @rindlet.should_receive(:do_nothing).and_raise(Timeout::Error.new("blah"))
  #   @rinda_client.takes << [["test_context", "request", "test"], ["test_context", "request", "test"]]
  # 
  #   @rindlet.run
  # 
  #   @rinda_client.writes.length.should eql(0)
  #   @rinda_client.delayed_writes[0].should eql([3600, ["test_context", "request", "test"]])
  # end
  # 
  # it "should not re-post the tuple when the exception is not recoverable in with_standard_tuple" do
  #   @rindlet.recover_from(Timeout::Error, NoMethodError)
  #   @rindlet.should_receive(:do_nothing).and_raise(SystemExit)
  #   @rinda_client.takes << [TEST_RINDLET_TEMPLATE, TEST_RINDLET_TEMPLATE]
  # 
  #   @rindlet.run
  # 
  #   @rinda_client.delayed_writes.length.should eql(0)
  #   @rinda_client.writes[0].should eql(["test_context", "response", "test", "error", "SystemExit", TEST_RINDLET_TEMPLATE])
  # end
  # 
  # it "should not re-post the tuple when the exception is not recoverable in with_tuple" do
  #   rindlet = Test2Rindlet.new(1)
  #   rindlet.pulse = 0
  #   rinda_client = MockRindaClient.new
  #   rindlet.rinda_client = rinda_client
  # 
  #   rindlet.recover_from(Timeout::Error, NoMethodError)
  #   rindlet.should_receive(:do_nothing).and_raise(SystemExit)
  #   rinda_client.takes << [["test_context", "request", "test"], ["test_context", "request", "test"]]
  # 
  #   rindlet.run
  # 
  #   rinda_client.delayed_writes.length.should eql(0)
  #   rinda_client.writes[0].should eql(["test_context", "response", "test", "error", "SystemExit", TEST_RINDLET_TEMPLATE])
  # end

  # it "should set the app id" do
  #   @rindlet.recover_from(Timeout::Error, NoMethodError)
  #   @rindlet.should_receive(:do_nothing).and_raise(SystemExit)
  #   @rinda_client.takes << [TEST_RINDLET_TEMPLATE, TEST_RINDLET_TEMPLATE + ["app_id"]]
  # 
  #   @rindlet.run
  # 
  #   @rinda_client.delayed_writes.length.should eql(0)
  #   @rinda_client.writes[0].should eql(["test_context", "response", "test", "error", "SystemExit", TEST_RINDLET_TEMPLATE + ["app_id"],])
  # end
  # 
  # it "should set the app id to nil if empty" do
  #   @rindlet.should_receive(:do_nothing).and_raise(SystemExit)
  #   @rinda_client.takes << [["test_context", "request", "test"], ["test_context", "request", "test"]]
  # 
  #   @rindlet.run
  # 
  #   @rinda_client.delayed_writes.length.should eql(0)
  #   @rinda_client.writes[0].should eql(["test_context", "response", "test", "error", "SystemExit", TEST_RINDLET_TEMPLATE])
  # end
  # 
  # it "should use the already set app_id" do
  #   @rindlet.app_id = "123"
  #   @rindlet.recover_from(Timeout::Error, NoMethodError)
  #   @rindlet.should_receive(:do_nothing).and_raise(SystemExit)
  #   @rinda_client.takes << [["test_context", "request", "test"], ["test_context", "request", "test"]]
  # 
  #   @rindlet.run
  # 
  #   @rinda_client.delayed_writes.length.should eql(0)
  #   @rinda_client.writes[0].should eql(["test_context", "response", "test", "error", "SystemExit", TEST_RINDLET_TEMPLATE])
  # end
  # 
  # it "should use the error topic" do
  #   @rindlet.error_topic = "test_error_topic"
  #   @rindlet.should_receive(:do_nothing).and_raise(SystemExit)
  #   @rinda_client.takes << [["test_context", "request", "test"], ["test_context", "request", "test"]]
  # 
  #   @rindlet.run
  # 
  #   @rinda_client.writes[0].should == ["test_context", "response", "test", "test_error_topic", "SystemExit", TEST_RINDLET_TEMPLATE]
  # end


end
