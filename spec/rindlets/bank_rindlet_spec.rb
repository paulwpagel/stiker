require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require "rindlets/bank_rindlet"

describe BankRindlet do

  before(:each) do
    @bank = mock(Bank, :buy => nil, :sell => nil)
    Bank.stub!(:new).and_return(@bank)
    @rindlet = BankRindlet.new()
    @rinda_client = MockRindaClient.new
    @rindlet.rinda_client = @rinda_client
  end
  
  it "takes a registration and passes it to the bank" do
    @bank.should_receive(:register).with("test")
    
    @rinda_client.takes << [["bank"], ["bank", "register", "test"]]
    
    @rindlet.run
  end
  
  it "takes a buy request and passes it to the bank" do
    @bank.should_receive(:buy).with("test", "AAPL", 20, 50)
    @rinda_client.takes << [["bank"], ["bank", "buy", "test", "AAPL", 20, 50]]
    @rindlet.run
  end
  
  it "writes a confirmation" do
    tuple = ["bank", "buy", "test", "AAPL", 20, 50]

    @rinda_client.takes << [["bank"], tuple]
    @rindlet.run
    @rinda_client.writes.should include(["bank", "confirmation", "test", tuple])
  end
  
  it "takes a sell request and passes it to the bank" do
    @bank.should_receive(:sell).with("test", "AAPL", 25, 50)
    @rinda_client.takes << [["bank"], ["bank", "sell", "test", "AAPL", 25, 50]]
    @rindlet.run
  end
  
  it "writes a failure message for InsufficientFunds error" do
    tuple = ["bank", "buy", "test", "AAPL", 20, 50]
    @bank.should_receive(:buy).and_raise(InsufficientFunds)
    @rinda_client.takes << [["bank"], tuple]
    @rindlet.run
    @rinda_client.writes.should include(["bank", "failure", "test", tuple])
  end
  
  it "writes a failure message for InsufficientAssets" do
    tuple = ["bank", "buy", "test", "AAPL", 20, 50]
    @bank.should_receive(:buy).and_raise(InsufficientAssets)
    @rinda_client.takes << [["bank"], tuple]
    @rindlet.run
    @rinda_client.writes.should include(["bank", "failure", "test", tuple])
  end
  
  
end
