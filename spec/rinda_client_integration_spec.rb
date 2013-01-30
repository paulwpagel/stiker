# MDM 1/4/08 upgrades - This spec goes haywire and spawns many other spec processes.  A bug in rspec???

require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'rinda_client'
require 'rinda/tuplespace'
require 'drb/drb'

describe Rinda::RindaClient, "RindaClient connecting to a live server" do
  # 
  # before(:each) do
  #   CONFIG[:rinda_host] = "localhost"
  #   CONFIG[:rinda_port] = 9123
  #   start_server
  #   @client = Rinda::RindaClient.new
  # end
  # 
  # after(:each) do
  #   kill_server
  # end
  # 
  # def start_server
  #   @pid = Process.fork do
  #     tuplespace = Rinda::TupleSpace.new(0.1)
  #     server = DRb.start_service("druby://:9123", tuplespace)
  #     Signal.trap("TERM") { server.stop_service }
  #     server.thread.join(5)
  #   end
  #   sleep(0.2)
  # end
  # 
  # def kill_server
  #   begin
  #     Process.kill("TERM", @pid)
  #     Process.wait(@pid)
  #   rescue Errno::ESRCH
  #   end
  # end
  
  # after(:all) do
  #   ActiveRecord::Base.connection.reconnect!
  #   Admin::Base.connection.reconnect!
  # end
  
  # it "should not connect until needed" do
  #   @client = Rinda::RindaClient.new
  #   
  #   @client.write [1, 2, 3]
  #   Rinda::RindaClient.instance_variable_get("@tuplespace").should_not eql(nil)
  #   DRb.current_server.should_not be(nil)
  # end
  # 
  # it "should recover from disconnect" do
  #   @client = Rinda::RindaClient.new
  #   @client.write [1, 2, 3]
  #   first_tuplespace = Rinda::RindaClient.instance_variable_get("@tuplespace")
  #   DRb.stop_service
  #   Rinda::RindaClient.close
  #   
  #   @client.write [3, 2, 1]
  #   DRb.current_server.should_not be(nil)
  #   Rinda::RindaClient.instance_variable_get("@tuplespace").should_not be(first_tuplespace)
  # end
  
  # it "should convert all write into arrays of size 10" do
  #   take = nil
  #   thread = Thread.new { take = @client.take [nil] }
  #   @client.write [1, 2, 3]
  #   
  #   thread.join(1)
  #   thread.kill if thread
  #   take.should eql([1, 2, 3, nil, nil, nil, nil, nil, nil, nil])
  # end
  # 
  # it "should handle reads" do
  #   read = nil
  #   thread = Thread.new { read = @client.read [nil] }
  #   @client.write [1, 2, 3]
  #   
  #   thread.join(1)
  #   thread.kill if thread
  #   read.should eql([1, 2, 3, nil, nil, nil, nil, nil, nil, nil])
  # end
  # 
  # it "should handle notifies" do
  #   notifier = @client.notify("write", [nil])
  #   @client.write([1, 2, 3])
  #   notifier.notify("close")
  #   
  #   notifier.pop[1].should eql([1, 2, 3, nil, nil, nil, nil, nil, nil, nil])
  # end
  # 
  # # it "should handle delayed write" do
  # #   take = nil
  # #   thread = Thread.new { take = Core::RindaClient.tuplespace.take ["delay", nil] }
  # #   @client.delayed_write(123, [1, 2, 3])
  # #   
  # #   thread.join(1)
  # #   thread.kill if thread
  # #   take.should eql(["delay", [1, 2, 3, nil, nil, nil, nil, nil, nil, nil]])
  # # end
  # 
  # it "should return nil when a request times out" do
  #   result = @client.take([1, 2, 3], 0)
  #   result.should eql(nil)
  #       
  #   result = @client.read([1, 2, 3], 0)
  #   result.should eql(nil)
  # end
  # 
  # it "should used the delay in the delayed write" do
  #   mock_tuplespace = make_mock("tuplespace")
  #   RindaClient.should_receive(:tuplespace).and_return(mock_tuplespace)
  #   mock_tuplespace.should_receive(:write).with(["delay", [1, 2, 3, nil, nil, nil, nil, nil, nil, nil]], 123)
  #   
  #   @client.delayed_write(123, [1, 2, 3])
  # end
  # 
  # it "should wait when server is down" do
  #   kill_server
  #   $write_status = "pending"
  #   thread = Thread.new do
  #     begin
  #       @client.write([1, 2, 3])
  #       $write_status = "success"
  #     rescue Exception => e
  #       $write_status = "failed"
  #     end
  #   end 
  #   sleep(0.1)
  #   $write_status.should eql("pending")
  #   start_server
  #   thread.join(10)
  #   $write_status.should eql("success")
  #   @client.take([1, 2, 3], 0).should eql([1, 2, 3, nil, nil, nil, nil, nil, nil, nil])
  # end
  # 
  # it "should respect timeouts on takes and reads if connection is down" do
  #   sleep(0.5)
  #   kill_server
  #   $take_result = "pending"
  #   $read_result = "pending"
  #   take_thread = Thread.new { $take_result = @client.take([1, 2, 3], 0.1) }
  #   read_thread = Thread.new { $read_result = @client.read([1, 2, 3], 0.1) }
  #   take_thread.join(5.0)
  #   read_thread.join(5.0)
  #   $take_result.should eql(nil)
  #   $read_result.should eql(nil)
  # end
  # 
  # it "should survive mid-connection network cutoffs" do
  #   $take1 = "pending"
  #   $take2 = "pending"
  #   
  #   take1_thread = Thread.new { $take1 = @client.take([1, 2, 3], 0.1) }
  #   take2_thread = Thread.new { $take2 = @client.take([1, 2, 3]) }
  #   Thread.pass
  #   take1_thread.alive?.should eql(true)
  #   take2_thread.alive?.should eql(true)
  #   
  #   kill_server
  #   sleep(0.1)
  #   start_server
  #   
  #   @client.write([1, 2, 3])
  #   take1_thread.join(3)
  #   take2_thread.join(3)
  #   
  #   $take1.should eql(nil)
  #   $take2.should eql([1, 2, 3, nil, nil, nil, nil, nil, nil, nil])
  # end
  # 
end
