require "spec_helper"
require "bank"
require "simple_logger"
require "mock_logger"

describe Bank do
  
  it "registers a new account" do
    @bank = Bank.new($logger)
    @bank.register("Paul")
    
    @bank.accounts.size.should == 1
  end
  
  it "registers an account with a default amount" do
    @bank = Bank.new($logger)
    @bank.register("Paul")
    
    @bank.accounts["Paul"].amount.should == 100000
  end
  
  it "buys a stock" do
    @bank = Bank.new($logger)
    @bank.register("Paul")
    @bank.buy("Paul", "AAPL", 1000, 100)

    @bank.accounts["Paul"].amount.should == 0    
    @bank.accounts["Paul"].assets["AAPL"].should == 100
  end
  
  it "doesn't let you buy more than money you have" do
    @bank = Bank.new($logger)
    @bank.register("Paul")
    
    expect {@bank.buy("Paul", "AAPL", 1000, 1000)}.to raise_error(InsufficientFunds)

    @bank.accounts["Paul"].amount.should == 100000    
    @bank.accounts["Paul"].assets["AAPL"].should be_nil
  end

  it "sells a stock" do
    @bank = Bank.new($logger)
    @bank.register("Paul")
    @bank.buy("Paul", "AAPL", 1000, 100)

    @bank.accounts["Paul"].amount.should == 0  
    @bank.accounts["Paul"].assets["AAPL"].should == 100
    @bank.sell("Paul", "AAPL", 1000, 100)
    @bank.accounts["Paul"].amount.should == 100000
    @bank.accounts["Paul"].assets["AAPL"].should == 0
  end
  
  it "won't let you sell more stocks than you own" do
    @bank = Bank.new($logger)
    @bank.register("Paul")
    @bank.buy("Paul", "AAPL", 1000, 100)
    
    expect {@bank.sell("Paul", "AAPL", 1000, 1000)}.to raise_error(InsufficientAssets)

    @bank.accounts["Paul"].amount.should == 0
    @bank.accounts["Paul"].assets["AAPL"].should == 100
  end
  
  it "can't sell something it doesn't have" do
    @bank = Bank.new($logger)
    @bank.register("Paul")
    
    expect {@bank.sell("Paul", "AAPL", 1000, 1000)}.to raise_error(InsufficientAssets)
    
    @bank.accounts["Paul"].amount.should == 100000
  end

  it "prints the current balance of all accounts" do
    @logger = MockLogger.new
    @bank = Bank.new(@logger)
    @bank.register("Paul")
    @bank.register("8thL")
    @bank.print_balances

    @logger.infos.should include("Paul's Balance = $100000", "8thL's Balance = $100000")
  end
  
end
