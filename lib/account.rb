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