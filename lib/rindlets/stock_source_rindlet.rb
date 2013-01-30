require File.expand_path(File.dirname(__FILE__) + "/../rindlet")

module Rinda
  class StockSourceRindlet < Rindlet
  
    def initialize(name, initial_price)
      super(1)
      @name = name
      rinda_client.write(["stock", name, initial_price])
    end

    def run
      with_tuple(["stock", name]) do |tuple|
        sleep 5

        old_price = tuple[2]
        change_by = [0.87, 0.89, 0.9, 0.95, 0.97, 0.98, 0.99, 1, 1, 1, 1.05, 1.02, 1.13, 1.2, 1.22]
        new_price = old_price.to_i * change_by[rand(change_by.length)]
        $logger.info "Updating #{@name} from #{old_price} to #{new_price}"
        rinda_client.write(["stock", name, new_price])

      end
    end
  
  end

  class SimpleLogger
  
    def info(message)
      puts message
    end
  
    def error(message)
      puts message
    end
  
  end
end

