# require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
# require "rindlets/bank"
# 
# describe BankRindlet do
# 
#   before(:each) do
#     @rindlet = BankRindlet.new(1)
#     @rindlet.pulse = 0
#     @rinda_client = MockRindaClient.new
#     @rindlet.rinda_client = @rinda_client
#   end
#   
#   it "" do
#     
#   end
# 
#   # it "should re-post the tuple when a recoverable exceptions" do
#   #   @rindlet.recover_from(Timeout::Error)
#   #   @rindlet.should_receive(:do_nothing).and_raise(Timeout::Error.new("blah"))
#   #   @rinda_client.takes << [["test_context", "request", "test"], ["test_context", "request", "test"]]
#   # 
#   #   @rindlet.run
#   # 
#   #   @rinda_client.writes.length.should eql(0)
#   #   @rinda_client.delayed_writes[0].should eql([3600, ["test_context", "request", "test"]])
#   # end
# 
# end
