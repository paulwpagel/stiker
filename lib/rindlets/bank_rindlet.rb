require File.expand_path(File.dirname(__FILE__) + "/../rindlet")
require "bank"
require "simple_logger"

class StockPriceUnavailable < Exception
end

class BankRindlet < Rinda::Rindlet

  def initialize
    @bank = Bank.new($logger)
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
  
  def run
    with_tuple(["bank"]) do |tuple|
      begin
        action, account_name = tuple[1], tuple[2]
        return_value = nil
        case action
        when "register"
          @bank.register(account_name)
          return_value = 100000
        when "buy"
          stock_name, quantity = tuple[3], tuple[4]
          return_value = current_price = current_price(stock_name)
          @bank.buy(account_name, stock_name, current_price, quantity)
        when "sell"
          stock_name, quantity = tuple[3], tuple[4]
          return_value = current_price = current_price(stock_name)
          @bank.sell(account_name, stock_name, current_price, quantity)
        end
        rinda_client.write(["bank", "confirmation", account_name, action, return_value, tuple])
      rescue InsufficientFunds, InsufficientAssets, StockPriceUnavailable
        rinda_client.write(["bank", "failure", account_name, action, nil, tuple])
      end
    end
  end
end
