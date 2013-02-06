require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require "rindlets/bank_rindlet"

describe BankRindlet do
  let(:bank_request) { ["bank", "request"] }

  before(:each) do
    @bank = mock(Bank, :buy => nil, :sell => nil, :register => nil, :balance => 100000.0)
    Bank.stub!(:new).and_return(@bank)
    @rindlet = BankRindlet.new()
    @rinda_client = MockRindaClient.new
    @rinda_client.takes << [["stock", "AAPL"], ["stock", "AAPL", 500.00]]
    @rindlet.rinda_client = @rinda_client
  end
  
  it "takes a registration and passes it to the bank" do
    @bank.should_receive(:register).with("test")
    @rinda_client.takes << [bank_request, ["bank", "request", "register", "test"]]
    @rindlet.run
  end

  it "writes a confirmation for a registration" do
    tuple = ["bank", "request", "register", "test"]
    
    @rinda_client.takes << [bank_request, tuple]
    @rindlet.run
    @rinda_client.writes.should include(["bank", "response", "confirmation", "test", "register", 100000, tuple])
  end
  
  it "takes a buy request and passes it to the bank" do
    @bank.should_receive(:buy).with("test", "AAPL", 500.0,   20)
    @rinda_client.takes << [bank_request, ["bank", "request", "buy", "test", "AAPL", 20]]
    @rindlet.run
  end
  
  it "writes a confirmation for a buy" do
    tuple = ["bank", "request", "buy", "test", "AAPL", 50]

    @rinda_client.takes << [bank_request, tuple]
    @rindlet.run
    @rinda_client.writes.should include(["bank", "response", "confirmation", "test", "buy", 500.0, tuple])
  end
  
  it "writes a confirmation for a sell" do
    tuple = ["bank", "request", "sell", "test", "AAPL", 50]

    @rinda_client.takes << [bank_request, tuple]
    @rindlet.run
    @rinda_client.writes.should include(["bank", "response", "confirmation", "test", "sell", 500.0, tuple])
  end
  
  it "takes a sell request and passes it to the bank" do
    @bank.should_receive(:sell).with("test", "AAPL", 500.00, 25)
    @rinda_client.takes << [bank_request, ["bank", "request", "sell", "test", "AAPL", 25]]
    @rindlet.run
  end
  
  it "writes a failure message for InsufficientFunds error" do
    tuple = ["bank", "request", "buy", "test", "AAPL", 50]
    
    @bank.should_receive(:buy).and_raise(InsufficientFunds)
    @rinda_client.takes << [bank_request, tuple]
    @rindlet.run
    @rinda_client.writes.should include(["bank", "response", "failure", "test", "buy", nil, tuple])
  end
  
  it "writes a failure message for InsufficientAssets" do
    tuple = ["bank", "request", "sell", "test", "AAPL", 50]
    
    @bank.should_receive(:sell).and_raise(InsufficientAssets)
    @rinda_client.takes << [bank_request, tuple]
    @rindlet.run
    @rinda_client.writes.should include(["bank", "response", "failure", "test", "sell", nil, tuple])
  end
  
  it "should return a stock's current price" do
    @rindlet.current_price("AAPL").should == 500.0
  end
  
  it "should raise an error if the bank can't find a stock's current price" do
    expect{@rindlet.current_price("FOOBAR")}.to raise_error(StockPriceUnavailable)
  end
  
  it "writes a failure message if StockPriceUnavailable" do
    tuple = ["bank", "request", "buy", "test", "asdf", 50, 20]
    
    @rinda_client.takes << [bank_request, tuple]
    @rindlet.run
    @rinda_client.writes.should include(["bank", "response", "failure", "test", "buy", nil, tuple])
  end

  it "takes a balance request and passes it to the bank" do
    @bank.should_receive(:balance).with("test")
    @rinda_client.takes << [bank_request, ["bank", "request", "balance", "test"]]
    @rindlet.run
  end

  it "writes a confirmation message if balance is successfully retrieved" do
    tuple = ["bank", "request", "balance", "test"]

    @rinda_client.takes << [bank_request, tuple]
    @rindlet.run
    @rinda_client.writes.should include(["bank", "response", "confirmation", "test", "balance", 100000.0, tuple])
  end


  it "takes a print balance command and asks the bank to print the balances" do
    tuple = ["bank", "request", "print_balances"]

    @rinda_client.takes << [bank_request, tuple]
    @bank.should_receive(:print_balances)
    @rindlet.run
  end
  
end
