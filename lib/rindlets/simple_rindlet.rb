require File.expand_path(File.dirname(__FILE__) + "/../rindlet")
require "simple_logger"

module Rinda
  class SimpleRindlet < Rindlet
  
    def initialize
      super(1)
      rinda_client.write(["simple", "0"])
    end

    def run
      with_tuple(["simple"]) do |tuple|
        sleep 1
        
        $logger.info tuple[1]
        @rinda_client.write(["simple", (tuple[1].to_i + 1).to_s], 10)
      end
    end
  
  end 
end

