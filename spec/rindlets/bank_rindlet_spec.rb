require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require "rindlets/bank_rindlet"

describe BankRindlet do

  before(:each) do
    @bank = mock(Bank, :buy => nil, :sell => nil, :register => nil)
    Bank.stub!(:new).and_return(@bank)
    @rindlet = BankRindlet.new()
    @rinda_client = MockRindaClient.new
    @rinda_client.takes << [["stock", "AAPL"], ["stock", "AAPL", 500.00]]
    @rindlet.rinda_client = @rinda_client
  end
  
  it "takes a registration and passes it to the bank" do
    @bank.should_receive(:register).with("test")
    @rinda_client.takes << [["bank"], ["bank", "register", "test"]]
    @rindlet.run
  end

  it "writes a confirmation for a registration" do
    tuple = ["bank", "register", "test"]
    
    @rinda_client.takes << [["bank"], tuple]
    @rindlet.run
    @rinda_client.writes.should include(["bank", "confirmation", "test", "register", 100000, tuple])
  end
  
  it "takes a buy request and passes it to the bank" do
    @bank.should_receive(:buy).with("test", "AAPL", 500.0,   20)
    @rinda_client.takes << [["bank"], ["bank", "buy", "test", "AAPL", 20]]
    @rindlet.run
  end
  
  it "writes a confirmation for a buy" do
    tuple = ["bank", "buy", "test", "AAPL", 50]

    @rinda_client.takes << [["bank"], tuple]
    @rindlet.run
    @rinda_client.writes.should include(["bank", "confirmation", "test", "buy", 500.0, tuple])
  end
  
  it "writes a confirmation for a sell" do
    tuple = ["bank", "sell", "test", "AAPL", 50]

    @rinda_client.takes << [["bank"], tuple]
    @rindlet.run
    @rinda_client.writes.should include(["bank", "confirmation", "test", "sell", 500.0, tuple])
  end
  
  it "takes a sell request and passes it to the bank" do
    @bank.should_receive(:sell).with("test", "AAPL", 500.00, 25)
    @rinda_client.takes << [["bank"], ["bank", "sell", "test", "AAPL", 25]]
    @rindlet.run
  end
  
  it "writes a failure message for InsufficientFunds error" do
    tuple = ["bank", "buy", "test", "AAPL", 50]
    
    @bank.should_receive(:buy).and_raise(InsufficientFunds)
    @rinda_client.takes << [["bank"], tuple]
    @rindlet.run
    @rinda_client.writes.should include(["bank", "failure", "test", "buy", nil, tuple])
  end
  
  it "writes a failure message for InsufficientAssets" do
    tuple = ["bank", "sell", "test", "AAPL", 50]
    
    @bank.should_receive(:sell).and_raise(InsufficientAssets)
    @rinda_client.takes << [["bank"], tuple]
    @rindlet.run
    @rinda_client.writes.should include(["bank", "failure", "test", "sell", nil, tuple])
  end
  
  it "should return a stock's current price" do
    @rindlet.current_price("AAPL").should == 500.0
  end
  
  it "should raise an error if the bank can't find a stock's current price" do
    expect{@rindlet.current_price("FOOBAR")}.to raise_error(StockPriceUnavailable)
  end
  
  it "writes a failure message if StockPriceUnavailable" do
    tuple = ["bank", "buy", "test", "asdf", 50, 20]
    
    @rinda_client.takes << [["bank"], tuple]
    @rindlet.run
    @rinda_client.writes.should include(["bank", "failure", "test", "buy", nil, tuple])
  end
  
end