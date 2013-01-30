class Bank
  attr_reader :accounts
  
  def initialize(logger)
    @logger = logger
    @accounts = {}
  end
  
  def register(account)
    @accounts[account] = Account.new( 100000)
    @logger.info("#{account} registered.  Balance=#{@accounts[account].amount}")
  end
  
  def buy(account, stock_name, purchase_price, quantity)
    sale_price = purchase_price.to_f * quantity.to_f
    if @accounts[account].amount >= sale_price
      @accounts[account].amount -= sale_price
      @accounts[account].add_asset(stock_name, quantity)
      @logger.info("#{account} purchased #{quantity} of #{stock_name} at #{purchase_price} per unit.  Balance=#{@accounts[account].amount}")
    end
  end
  
  def sell(account, stock_name, purchase_price, quantity)
    sale_price = purchase_price.to_f * quantity.to_f
    if !@accounts[account].assets[stock_name].nil? && @accounts[account].assets[stock_name] >= quantity
      @accounts[account].amount += sale_price
      @accounts[account].remove_asset(stock_name, quantity)
      @logger.info("#{account} sold #{quantity} of #{stock_name} at #{purchase_price} per unit.  Balance=#{@accounts[account].amount}")
    end
  end
end


class Account
  attr_accessor :amount, :assets
  def initialize(initial_amount)
    @amount = initial_amount
    @assets= {}
  end
  
  def add_asset(name, quantity)
    if @assets[name].nil?
      @assets[name] = 0
    end
    
    @assets[name] += quantity    
  end
  
  def remove_asset(name, quantity)
    @assets[name] -= quantity    
  end
  
end