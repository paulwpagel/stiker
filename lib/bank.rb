require "account"

class InsufficientFunds < Exception
end

class InsufficientAssets < Exception
end

class Bank
  attr_reader :accounts
  
  def initialize(logger)
    @logger = logger
    @accounts = {}
  end
  
  def register(account)
    @accounts[account] = Account.new(100000)
    @logger.info("#{account} registered.  Balance=#{@accounts[account].amount}")
  end
  
  def buy(account, stock_name, purchase_price, quantity)
    sale_price = purchase_price.to_f * quantity.to_f
    if @accounts[account].amount >= sale_price
      @accounts[account].amount -= sale_price
      @accounts[account].add_asset(stock_name, quantity)
      @logger.info("#{account} purchased #{quantity} of #{stock_name} at #{purchase_price} per unit.  Balance=#{@accounts[account].amount}")
    else
      raise InsufficientFunds
    end
  end
  
  def sell(account, stock_name, purchase_price, quantity)
    sale_price = purchase_price.to_f * quantity.to_f
    if !@accounts[account].assets[stock_name].nil? && @accounts[account].assets[stock_name] >= quantity
      @accounts[account].amount += sale_price
      @accounts[account].remove_asset(stock_name, quantity)
      @logger.info("#{account} sold #{quantity} of #{stock_name} at #{purchase_price} per unit.  Balance=#{@accounts[account].amount}")
    else
      raise InsufficientAssets
    end
  end

  def print_balances
    @accounts.each do |name, account|
      @logger.info("#{name}'s Balance = $#{account.amount}")
    end
  end
end

