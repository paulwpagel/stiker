require File.expand_path(File.dirname(__FILE__) + "/../rindlet")
require "bank"
require "simple_logger"

module Rinda
  class StockSourceRindlet < Rindlet
  
    def initialize(name, initial_price)
      @bank = Bank.new($logger)
      super(1)
    end

    def run
      with_tuple(["bank"]) do |tuple|
        case tuple[1]
        when "register"
          @bank.register(tuple[2])
        when "buy"
          @bank.buy(tuple[2], tuple[3], tuple[4], tuple[5])
        when "sell"
          @bank.sell(tuple[2], tuple[3], tuple[4], tuple[5])
        end
      end
    end
  end

end

