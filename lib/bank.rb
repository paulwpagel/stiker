require "account"

class InsufficientFunds < Exception
end

class InsufficientAssets < Exception
end

class Bank
  attr_reader :accounts
  
  def initialize
    @accounts = {}
  end

  def register(account)
    @accounts[account] = Account.new(100000)
  end
  
  def buy(account, stock_name, purchase_price, quantity)
    sale_price = purchase_price.to_f * quantity.to_f
    if @accounts[account].amount >= sale_price
      @accounts[account].amount -= sale_price
      @accounts[account].add_asset(stock_name, quantity)
    else
      raise InsufficientFunds
    end
  end
  
  def sell(account, stock_name, purchase_price, quantity)
    sale_price = purchase_price.to_f * quantity.to_f
    if !@accounts[account].assets[stock_name].nil? && @accounts[account].assets[stock_name] >= quantity
      @accounts[account].amount += sale_price
      @accounts[account].remove_asset(stock_name, quantity)
    else
      raise InsufficientAssets
    end
  end

  def balance(account_name)
    @accounts[account_name]
  end
end

