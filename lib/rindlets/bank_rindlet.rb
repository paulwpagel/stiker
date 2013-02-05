require File.expand_path(File.dirname(__FILE__) + "/../rindlet")
require "bank"
require "simple_logger"

class BankRindlet < Rinda::Rindlet

  def initialize
    @bank = Bank.new($logger)
  end

  def run
    with_tuple(["bank"]) do |tuple|
      begin
        account_name = tuple[2]
        case tuple[1]

        when "register"
          @bank.register(account_name)
        when "buy"
          @bank.buy(account_name, tuple[3], tuple[4], tuple[5])
        when "sell"
          @bank.sell(account_name, tuple[3], tuple[4], tuple[5])
        end
      
        rinda_client.write(["bank", "confirmation", account_name, tuple])
      rescue InsufficientFunds, InsufficientAssets
        rinda_client.write(["bank", "failure", account_name, tuple])
      end
    end
  end
end
