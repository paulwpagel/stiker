require File.expand_path(File.dirname(__FILE__) + "/../rindlet")
require "bank"
require "simple_logger"

class StockPriceUnavailable < Exception
end

class BankRindlet < Rinda::Rindlet

  def initialize
    @bank = Bank.new()
    @display_counter = 0
  end
    
  def run
    display_accounts
    
    with_tuple(["bank", "request"]) do |tuple|
      begin
        action, account_name = tuple[2], tuple[3]
        return_value = nil
        case action
        when "register"
          return_value = register(account_name)
        when "buy"
          return_value = buy(account_name, tuple)
        when "sell"
          return_value = sell(account_name, tuple)
        when "balance"
          return_value = @bank.balance(account_name)
        when "print_balances"
          @bank.print_balances
        end
        rinda_client.write(["bank", "response", "confirmation", account_name, action, return_value, tuple])
      rescue InsufficientFunds, InsufficientAssets, StockPriceUnavailable
        rinda_client.write(["bank", "response", "failure", account_name, action, nil, tuple])
      end
    end
    
  end
  
  
  private ###########################################
  
  def sell(account_name, tuple)
    stock_name, quantity = tuple[4], tuple[5]
    stock_price = current_price(stock_name)
    @bank.sell(account_name, stock_name, stock_price, quantity)
    
    account = @bank.accounts[account_name]
    $logger.info("#{account_name} sold #{quantity} of #{stock_name} at #{stock_price} per unit.")
    return stock_price
  end
  
  def buy(account_name, tuple)    
    stock_name, quantity = tuple[4], tuple[5]
    stock_price = current_price(stock_name)
    @bank.buy(account_name, stock_name, stock_price, quantity)
    account = @bank.accounts[account_name]
    $logger.info("#{account_name} purchased #{quantity} of #{stock_name} at #{stock_price} per unit.")
    return stock_price
  end
  
  def register(account_name)
    @bank.register(account_name)
    account = @bank.accounts[account_name]
    $logger.info("#{account_name} registered.  Balance=#{account.amount}")
    return account.amount
  end
  
  def find_account(account_name)
    
  end
  
  def current_price(stock_name, iteration=0)
    stock_tuple = rinda_client.read(["stock", stock_name])
    if stock_tuple.nil?
      if iteration < 15
        current_price(stock_name, iteration + 1)
      else
        raise StockPriceUnavailable
      end
    end
    current_price = stock_tuple[2]
  end
  
  
  
  def display_accounts
    if @display_counter == 5
      @bank.accounts.each do |name, account|
        $logger.info("| #{name} | #{account.amount} |")
        account.assets.each do |name, quantity|
          $logger.info("          | #{name} | #{quantity}")
        end
      end
      @display_counter = 0
    end
    @display_counter += 1
  end
  
  
  
end
